/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musify/constants/version.dart';
import 'package:musify/main.dart' show isFdroidBuild, logger;
import 'package:musify/services/data_manager.dart';
import 'package:musify/services/settings_manager.dart';

const String releasePageUrl =
    'https://github.com/doctorloveapp/musify/releases/latest';
const String releasesUrl =
    'https://api.github.com/repos/doctorloveapp/musify/releases/latest';

const _cachedUpdateVersionKey = 'availableUpdateVersion';
const _cachedUpdateUrlKey = 'availableUpdateUrl';

class AppUpdateInfo {
  const AppUpdateInfo({required this.version, required this.pageUrl});

  final String version;
  final String pageUrl;
}

/// Non-null only when GitHub reports a stable release newer than [appVersion].
/// The settings page listens to this value and renders a small, non-blocking
/// indicator; this service never opens dialogs or navigates by itself.
final ValueNotifier<AppUpdateInfo?> availableAppUpdate = ValueNotifier(null);

Future<AppUpdateInfo?>? _checkInFlight;

/// Restores the last successful result without contacting the network.
Future<void> restoreCachedAppUpdateState() async {
  if (shouldWeCheckUpdates.value != true) {
    await clearAppUpdateAvailability();
    return;
  }

  final version = (await getData(
    'settings',
    _cachedUpdateVersionKey,
  ))?.toString();
  final pageUrl =
      (await getData('settings', _cachedUpdateUrlKey))?.toString() ??
      releasePageUrl;

  if (version != null && isLatestVersionHigher(appVersion, version)) {
    availableAppUpdate.value = AppUpdateInfo(
      version: version,
      pageUrl: pageUrl,
    );
    return;
  }

  await clearAppUpdateAvailability();
}

/// Checks GitHub only when automatic checks are explicitly enabled.
///
/// This method is intentionally silent: the only observable update is
/// [availableAppUpdate], consumed by the settings indicator.
Future<AppUpdateInfo?> checkAppUpdates() {
  if (isFdroidBuild ||
      shouldWeCheckUpdates.value != true ||
      offlineMode.value) {
    return Future.value(availableAppUpdate.value);
  }

  final pending = _checkInFlight;
  if (pending != null) return pending;

  final operation = _checkAppUpdates();
  _checkInFlight = operation;
  return operation.whenComplete(() {
    if (identical(_checkInFlight, operation)) _checkInFlight = null;
  });
}

Future<AppUpdateInfo?> _checkAppUpdates() async {
  try {
    final response = await http.get(
      Uri.parse(releasesUrl),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      logger.log('Silent update check returned HTTP ${response.statusCode}');
      return availableAppUpdate.value;
    }

    final release = json.decode(response.body) as Map<String, dynamic>;
    final latestVersion = releaseVersionFromTag(
      release['tag_name']?.toString(),
    );
    if (latestVersion == null ||
        !isLatestVersionHigher(appVersion, latestVersion)) {
      await clearAppUpdateAvailability();
      return null;
    }

    final rawPageUrl = release['html_url']?.toString().trim();
    final update = AppUpdateInfo(
      version: latestVersion,
      pageUrl: rawPageUrl == null || rawPageUrl.isEmpty
          ? releasePageUrl
          : rawPageUrl,
    );
    availableAppUpdate.value = update;
    await addOrUpdateData<String>(
      'settings',
      _cachedUpdateVersionKey,
      update.version,
    );
    await addOrUpdateData<String>(
      'settings',
      _cachedUpdateUrlKey,
      update.pageUrl,
    );
    return update;
  } catch (error, stackTrace) {
    logger.log(
      'Silent update check failed',
      error: error,
      stackTrace: stackTrace,
    );
    return availableAppUpdate.value;
  }
}

Future<void> clearAppUpdateAvailability() async {
  availableAppUpdate.value = null;
  await deleteData('settings', _cachedUpdateVersionKey);
  await deleteData('settings', _cachedUpdateUrlKey);
}

String? releaseVersionFromTag(String? tag) {
  final match = RegExp(r'(?<!\d)(\d+\.\d+\.\d+)(?!\d)').firstMatch(tag ?? '');
  return match?.group(1);
}

bool isLatestVersionHigher(String currentVersion, String latestVersion) {
  final current = _versionParts(currentVersion);
  final latest = _versionParts(latestVersion);
  if (current == null || latest == null) return false;

  for (var index = 0; index < 3; index++) {
    if (latest[index] > current[index]) return true;
    if (latest[index] < current[index]) return false;
  }
  return false;
}

List<int>? _versionParts(String value) {
  final version = releaseVersionFromTag(value);
  if (version == null) return null;
  return version.split('.').map(int.parse).toList(growable: false);
}

/// Announcements are intentionally disabled in this branded distribution.
Future<void> fetchAnnouncementOnly() async {
  announcementURL.value = null;
}
