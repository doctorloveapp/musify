/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart' show logger;

// Cache durations for different types of data
const Duration songCacheDuration = Duration(hours: 1, minutes: 30);
const Duration playlistCacheDuration = Duration(hours: 5);
const Duration searchCacheDuration = Duration(days: 4);
const Duration defaultCacheDuration = Duration(days: 7);

// In-memory cache for frequently accessed items
final _memoryCache = <String, _CacheEntry>{};

// Serialize only cache reads/mutations that can invalidate another operation.
Future<void> _cacheMutationTail = Future<void>.value();
Future<T> _withCacheMutation<T>(FutureOr<T> Function() action) {
  final result = _cacheMutationTail.then((_) => action());
  _cacheMutationTail = result.then<void>(
    (_) {},
    onError: (Object _, StackTrace __) {},
  );
  return result;
}

Future<void>? _cacheCleanup;
bool _startupCacheCleanupScheduled = false;

/// First UI frame only; never await cache maintenance on the startup path.
void scheduleStartupCacheCleanup({
  void Function(void Function())? afterFirstFrame,
}) {
  if (_startupCacheCleanupScheduled) return;
  _startupCacheCleanupScheduled = true;
  final schedule =
      afterFirstFrame ??
      (void Function() action) {
        WidgetsBinding.instance.addPostFrameCallback((_) => action());
      };
  schedule(() {
    unawaited(cleanupOldCacheEntries());
  });
}

class _CacheEntry {
  _CacheEntry(this.data, this.timestamp);
  final dynamic data;
  final DateTime timestamp;

  bool isValid(Duration cacheDuration) {
    return DateTime.now().difference(timestamp) < cacheDuration;
  }
}

DateTime? _parseCacheDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

// Maximum number of entries allowed in the memory cache
const int _maxMemoryCacheSize = 500;
const int _memoryCacheTrimSize = 100;

void _setMemoryCacheEntry(String key, _CacheEntry entry) {
  _memoryCache
    ..remove(key)
    ..[key] = entry;
  _trimMemoryCacheIfNeeded();
}

void _touchMemoryCacheEntry(String key) {
  final entry = _memoryCache.remove(key);
  if (entry != null) {
    _memoryCache[key] = entry;
  }
}

void _trimMemoryCacheIfNeeded() {
  if (_memoryCache.length > _maxMemoryCacheSize) {
    final keysToRemove = _memoryCache.keys.take(_memoryCacheTrimSize).toList();
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }
  }
}

Future<void> addOrUpdateData<T>(String category, String key, T value) async {
  final box = await _openBox(category);
  if (category != 'cache') {
    await box.put(key, value);
    return;
  }
  await _withCacheMutation(() async {
    final timestamp = DateTime.now();
    await box.putAll({key: value, '${key}_date': timestamp});
    _setMemoryCacheEntry('cache_$key', _CacheEntry(value, timestamp));
  });
}

Future<dynamic> getData(
  String category,
  String key, {
  dynamic defaultValue,
  Duration? cachingDuration,
}) async {
  final box = await _openBox(category);
  if (category != 'cache') return box.get(key, defaultValue: defaultValue);
  final duration = cachingDuration ?? _getCacheDurationForKey(key);
  return _withCacheMutation(() async {
    final cacheKey = 'cache_$key';
    final cached = _memoryCache[cacheKey];
    if (cached != null && cached.isValid(duration)) {
      _touchMemoryCacheEntry(cacheKey);
      return cached.data;
    }
    if (!isCacheValid(box, key, duration)) {
      await box.deleteAll([key, '${key}_date']);
      _memoryCache.remove(cacheKey);
      return defaultValue;
    }
    final data = box.get(key, defaultValue: defaultValue);
    if (data != null) {
      final timestamp = _parseCacheDate(box.get('${key}_date'))!;
      _setMemoryCacheEntry(cacheKey, _CacheEntry(data, timestamp));
    }
    return data;
  });
}

Future<void> deleteData(String category, String key) async {
  final box = await _openBox(category);
  if (category != 'cache') {
    await box.delete(key);
    return;
  }
  await _withCacheMutation(() async {
    final keys = [key, if (!key.endsWith('_date')) '${key}_date'];
    await box.deleteAll(keys);
    for (final item in keys) {
      _memoryCache.remove('cache_$item');
    }
  });
}

Future<bool> clearCache() async {
  try {
    final box = await _openBox('cache');
    await _withCacheMutation(() async {
      await box.clear();
      _memoryCache.clear();
    });
    return true;
  } catch (e, stackTrace) {
    logger.log('Failed to clear cache', error: e, stackTrace: stackTrace);
    return false;
  }
}

/// Coalesced cleanup of reconstructible Hive cache only, never files or other boxes.
Future<void> cleanupOldCacheEntries({DateTime? now}) {
  final active = _cacheCleanup;
  if (active != null) return active;
  final operation = _cleanupOldCacheEntries(now ?? DateTime.now());
  _cacheCleanup = operation;
  return operation.whenComplete(() {
    if (identical(_cacheCleanup, operation)) _cacheCleanup = null;
  });
}

Future<void> _cleanupOldCacheEntries(DateTime now) async {
  try {
    final box = await _openBox('cache');
    final keys = box.keys
        .where((key) => !key.toString().endsWith('_date'))
        .toList();
    var removed = 0;
    var processed = 0;
    for (final key in keys) {
      await _withCacheMutation(() async {
        // Re-read while holding the mutation queue: a newly refreshed entry wins.
        if (!box.containsKey(key)) return;
        final date = _parseCacheDate(box.get('${key}_date'));
        if (date != null && now.difference(date) <= const Duration(days: 30))
          return;
        await box.deleteAll([key, '${key}_date']);
        _memoryCache.remove('cache_$key');
        removed++;
      });
      // Let rendering, cache writers and other event-loop work run between batches.
      if (++processed % 25 == 0) await Future<void>.delayed(Duration.zero);
    }
    logger.log(
      'Cache maintenance completed: $removed obsolete entries removed',
    );
  } catch (e, stackTrace) {
    logger.log(
      'Cache maintenance failed (startup continues)',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

// Check if the cache is still valid based on the caching duration
bool isCacheValid(Box box, String key, Duration cachingDuration) {
  final date = _parseCacheDate(box.get('${key}_date'));
  if (date == null) {
    return false;
  }
  final age = DateTime.now().difference(date);
  return age < cachingDuration;
}

Duration _getCacheDurationForKey(String key) {
  if (key.startsWith('song_') || key.contains('manifest_')) {
    return songCacheDuration;
  } else if (key.startsWith('playlist_') || key.contains('playlistSongs')) {
    return playlistCacheDuration;
  } else if (key.startsWith('search_')) {
    return searchCacheDuration;
  }
  return defaultCacheDuration;
}

Future<Box> _openBox(String category) async {
  if (Hive.isBoxOpen(category)) {
    return Hive.box(category);
  } else {
    return Hive.openBox(category);
  }
}

Future<({String message, bool success})> backupData(
  BuildContext context,
) async {
  final boxNames = ['user', 'settings'];

  try {
    for (final boxName in boxNames) {
      final box = await _openBox(boxName);

      if (box.path == null) {
        logger.log('Box path is null for $boxName');
        continue;
      }

      // Compact the box before copying
      try {
        await box.compact();
      } catch (e, stackTrace) {
        logger.log(
          'Failed to compact box $boxName',
          error: e,
          stackTrace: stackTrace,
        );
      }

      final sourceFile = File(box.path!);
      if (await sourceFile.exists()) {
        final bytes = await sourceFile.readAsBytes();
        final savedPath = await FilePicker.saveFile(
          fileName: '$boxName.hive',
          type: FileType.custom,
          allowedExtensions: ['hive'],
          bytes: Uint8List.fromList(bytes),
        );
        if (savedPath == null) {
          return (message: '${context.l10n!.chooseBackupDir}!', success: false);
        }
      } else {
        throw StateError('Source file does not exist for $boxName');
      }
    }

    return (message: '${context.l10n!.backedupSuccess}!', success: true);
  } catch (e, stackTrace) {
    logger.log('Backup error', error: e, stackTrace: stackTrace);
    return (message: '${context.l10n!.backupError}: $e', success: false);
  }
}

Future<({String message, bool success})> restoreData(
  BuildContext context,
) async {
  final boxNames = ['user', 'settings'];
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['hive'],
  );

  if (result.isEmpty) {
    return (message: '${context.l10n!.chooseBackupFiles}!', success: false);
  }

  final selectedFiles = <String, PlatformFile>{};
  for (final boxName in boxNames) {
    final backupFile = result
        .where(
          (file) =>
              file.name == '$boxName.hive' ||
              file.name.startsWith('${boxName}_'),
        )
        .firstOrNull;
    if (backupFile == null) {
      return (
        message: '${context.l10n!.chooseBackupFiles} ($boxName.hive)!',
        success: false,
      );
    }
    selectedFiles[boxName] = backupFile;
  }

  final boxPaths = <String, String>{};
  for (final boxName in boxNames) {
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await _openBox(boxName);
    final path = box.path;
    if (path == null) {
      return (message: context.l10n!.restoreError, success: false);
    }
    boxPaths[boxName] = path;
  }

  final backupBytes = <String, Uint8List>{};
  final originalBytes = <String, Uint8List>{};
  for (final boxName in boxNames) {
    final bytes = await _readPickedFile(selectedFiles[boxName]!);
    backupBytes[boxName] = bytes;
    originalBytes[boxName] = Uint8List.fromList(
      await File(boxPaths[boxName]!).readAsBytes(),
    );
  }

  final restoredBoxes = <String>[];
  try {
    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
    }

    for (final boxName in boxNames) {
      await _validateHiveBytes(boxName, backupBytes[boxName]!);
    }

    for (final boxName in boxNames) {
      await _replaceHiveFile(boxPaths[boxName]!, backupBytes[boxName]!);
      restoredBoxes.add(boxName);
      logger.log('Restored $boxName');
    }

    return (message: '${context.l10n!.restoredSuccess}!', success: true);
  } catch (e, stackTrace) {
    logger.log('Restore error', error: e, stackTrace: stackTrace);
    for (final boxName in restoredBoxes.reversed) {
      try {
        await _replaceHiveFile(boxPaths[boxName]!, originalBytes[boxName]!);
      } catch (rollbackError, rollbackStackTrace) {
        logger.log(
          'Failed to roll back $boxName after restore error',
          error: rollbackError,
          stackTrace: rollbackStackTrace,
        );
      }
    }
    return (message: '${context.l10n!.restoreError}: $e', success: false);
  } finally {
    for (final boxName in boxNames) {
      try {
        await _openBox(boxName);
      } catch (e, stackTrace) {
        logger.log(
          'Failed to reopen box $boxName',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}

Future<Uint8List> _readPickedFile(PlatformFile file) async {
  return file.readAsBytes();
}

Future<void> _validateHiveBytes(String boxName, Uint8List bytes) async {
  final validationDirectory = await Directory.systemTemp.createTemp(
    'musify_restore_',
  );
  try {
    final validationFile = File('${validationDirectory.path}/$boxName.hive');
    await validationFile.writeAsBytes(bytes, flush: true);
    final box = await Hive.openBox(boxName, path: validationDirectory.path);
    await box.close();
  } finally {
    await validationDirectory.delete(recursive: true);
  }
}

Future<void> _replaceHiveFile(String targetPath, Uint8List bytes) async {
  final targetFile = File(targetPath);
  final temporaryFile = File('$targetPath.restore.tmp');
  final backupFile = File('$targetPath.restore.bak');

  await temporaryFile.writeAsBytes(bytes, flush: true);
  if (await backupFile.exists()) await backupFile.delete();

  try {
    if (await targetFile.exists()) await targetFile.rename(backupFile.path);
    await temporaryFile.rename(targetPath);
    if (await backupFile.exists()) await backupFile.delete();
  } catch (_) {
    if (await temporaryFile.exists()) await temporaryFile.delete();
    if (!await targetFile.exists() && await backupFile.exists()) {
      await backupFile.rename(targetPath);
    }
    rethrow;
  }
}
