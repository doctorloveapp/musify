import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/local_audio_data_source.dart';
import 'package:musify/services/local_audio_permission.dart';
import 'package:musify/services/media_store_audio_data_source.dart';
import 'package:musify/utilities/local_track_adapter.dart';
import 'package:musify/utilities/song_source.dart';
import 'package:path_provider/path_provider.dart';

enum LocalAudioScanStatus { idle, requestingPermission, scanning, ready, error }

class LocalAudioService {
  LocalAudioService(
    this._dataSource,
    this._permissionGateway, {
    bool? isAndroid,
  }) : _isAndroid = isAndroid ?? Platform.isAndroid;

  static const int schemaVersion = 1;
  static const _songsKey = 'songs';
  static const _schemaKey = 'schemaVersion';
  static const _permissionRequestedKey = 'permissionRequested';

  final LocalAudioDataSource _dataSource;
  final LocalAudioPermissionGateway _permissionGateway;
  final bool _isAndroid;
  late Box<dynamic> _box;
  int? _androidSdk;
  int _scanGeneration = 0;
  Future<bool>? _permissionCheckInFlight;
  List<Map<String, dynamic>> _lastDiscoveredSongs = const [];
  bool _lastScanWasFull = false;

  final ValueNotifier<List<Map<String, dynamic>>> localSongs = ValueNotifier(
    const [],
  );
  final ValueNotifier<List<Map<String, dynamic>>> scanCandidates =
      ValueNotifier(const []);
  final ValueNotifier<List<String>> folders = ValueNotifier(const []);
  final ValueNotifier<LocalAudioPermissionState> permissionState =
      ValueNotifier(LocalAudioPermissionState.notRequested);
  final ValueNotifier<LocalAudioScanStatus> scanStatus = ValueNotifier(
    LocalAudioScanStatus.idle,
  );
  final ValueNotifier<String?> scanError = ValueNotifier(null);

  Future<void> initialize({Box<dynamic>? box}) async {
    _box = box ?? Hive.box('localLibrary');
    await _migrate();
    final stored = _box.get(_songsKey, defaultValue: const <dynamic>[]);
    localSongs.value = List<Map<String, dynamic>>.unmodifiable(
      (stored as List).whereType<Map>().map(Map<String, dynamic>.from),
    );
    if (!_isAndroid) {
      permissionState.value = LocalAudioPermissionState.unsupported;
      return;
    }
    final sdk = await _getAndroidSdk();
    final current = await _permissionGateway.status(sdk);
    final requested =
        _box.get(_permissionRequestedKey, defaultValue: false) == true;
    permissionState.value =
        !requested && current == LocalAudioPermissionState.denied
        ? LocalAudioPermissionState.notRequested
        : current;
  }

  Future<void> _migrate() async {
    final current = _box.get(_schemaKey, defaultValue: 0) as int;
    if (current < schemaVersion) await _box.put(_schemaKey, schemaVersion);
  }

  Future<bool> ensurePermission({bool request = true}) async {
    if (!_isAndroid) {
      permissionState.value = LocalAudioPermissionState.unsupported;
      return false;
    }

    // Serialize permission operations. Two quick scan requests must never
    // race a system permission dialog and reach the MediaStore plugin early.
    while (_permissionCheckInFlight != null) {
      final pending = _permissionCheckInFlight!;
      await pending;
    }
    final operation = _ensurePermission(request: request);
    _permissionCheckInFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_permissionCheckInFlight, operation)) {
        _permissionCheckInFlight = null;
      }
    }
  }

  Future<bool> _ensurePermission({required bool request}) async {
    scanStatus.value = LocalAudioScanStatus.requestingPermission;
    try {
      final sdk = await _getAndroidSdk();
      if (await _permissionGateway.isGranted(sdk)) {
        permissionState.value = LocalAudioPermissionState.granted;
        return true;
      }

      var state = await _permissionGateway.status(sdk);
      // isGranted() is the authoritative gate. A mapped or vendor-specific
      // status must never be enough to permit a MediaStore call.
      if (state == LocalAudioPermissionState.granted) {
        state = LocalAudioPermissionState.denied;
      }
      if (!request) {
        permissionState.value = state;
        return false;
      }

      await _box.put(_permissionRequestedKey, true);
      final requestResult = await _permissionGateway.request(sdk);
      permissionState.value = requestResult;
      if (requestResult != LocalAudioPermissionState.granted) return false;

      // request() returning is not sufficient on every vendor build. Confirm
      // the actual Permission.audio status before touching MediaStore. Short
      // retries cover propagation on One UI.
      for (var attempt = 0; attempt < 4; attempt++) {
        if (await _permissionGateway.isGranted(sdk)) {
          permissionState.value = LocalAudioPermissionState.granted;
          return true;
        }
        state = await _permissionGateway.status(sdk);
        permissionState.value = state == LocalAudioPermissionState.granted
            ? LocalAudioPermissionState.denied
            : state;
        if (state == LocalAudioPermissionState.permanentlyDenied ||
            state == LocalAudioPermissionState.restricted) {
          return false;
        }
        if (attempt < 3) {
          await Future<void>.delayed(
            Duration(milliseconds: 75 * (attempt + 1)),
          );
        }
      }
      return false;
    } catch (error, stackTrace) {
      permissionState.value = LocalAudioPermissionState.denied;
      logger.log(
        'Local audio permission check failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      if (scanStatus.value == LocalAudioScanStatus.requestingPermission) {
        scanStatus.value = LocalAudioScanStatus.idle;
      }
    }
  }

  Future<int> _getAndroidSdk() async =>
      _androidSdk ??= await _dataSource.androidSdkInt();

  /// Last-line Dart guard immediately before a native MediaStore operation.
  /// The native channel repeats this check to close the revoke-between-checks
  /// race, but no query is even sent across the channel unless this is true.
  Future<bool> _hasConfirmedMediaPermission() async {
    if (!_isAndroid) return false;
    final sdk = await _getAndroidSdk();
    final granted = await _permissionGateway.isGranted(sdk);
    if (granted) {
      permissionState.value = LocalAudioPermissionState.granted;
      return true;
    }
    final state = await _permissionGateway.status(sdk);
    permissionState.value = state == LocalAudioPermissionState.granted
        ? LocalAudioPermissionState.denied
        : state;
    return false;
  }

  Future<bool> openAppSettings() => _permissionGateway.openSettings();

  void cancelScan() {
    _scanGeneration++;
    scanStatus.value = LocalAudioScanStatus.idle;
  }

  Future<List<Map<String, dynamic>>> scan({String? folder}) async {
    final generation = ++_scanGeneration;
    if (!await ensurePermission()) return const [];
    if (generation != _scanGeneration) return const [];

    // Re-check at the last possible moment. The user may revoke access while
    // the app resumes; no platform query is issued without an explicit grant.
    if (!await _hasConfirmedMediaPermission()) return const [];
    if (generation != _scanGeneration) return const [];
    scanStatus.value = LocalAudioScanStatus.scanning;
    scanError.value = null;
    try {
      final records = await _querySongsSafely();
      if (generation != _scanGeneration) return const [];
      final mapped = records
          .where(_isImportable)
          .map(LocalTrackAdapter.fromRecord)
          .toList(growable: false);
      final deduplicated =
          <String, Map<String, dynamic>>{
            for (final song in mapped) songIdentity(song)!: song,
          }.values.toList()..sort(
            (a, b) => a['title'].toString().toLowerCase().compareTo(
              b['title'].toString().toLowerCase(),
            ),
          );
      folders.value =
          deduplicated
              .map((song) => song['folder']?.toString() ?? '')
              .where((path) => path.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final normalizedFolder = folder?.toLowerCase();
      _lastDiscoveredSongs = List.unmodifiable(deduplicated);
      _lastScanWasFull = normalizedFolder == null;
      final result = normalizedFolder == null
          ? deduplicated
          : deduplicated
                .where(
                  (song) =>
                      song['folder'].toString().toLowerCase() ==
                      normalizedFolder,
                )
                .toList();
      scanCandidates.value = List.unmodifiable(result);
      scanStatus.value = LocalAudioScanStatus.ready;
      return result;
    } catch (error, stackTrace) {
      if (generation == _scanGeneration) {
        scanError.value = error.toString();
        scanStatus.value = LocalAudioScanStatus.error;
      }
      logger.log(
        'Local audio scan failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  Future<List<LocalAudioRecord>> _querySongsSafely() async {
    try {
      return await _dataSource.querySongs();
    } catch (error, stackTrace) {
      logger.log(
        'MediaStore querySongs rejected',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool _isImportable(LocalAudioRecord record) =>
      (record.uri?.isNotEmpty == true || record.data.isNotEmpty) &&
      (record.durationMilliseconds ?? 0) > 0 &&
      record.isMusic != false &&
      record.isAlarm != true &&
      record.isNotification != true &&
      record.isRingtone != true;

  Future<void> importTracks(
    Iterable<Map> selected, {
    bool reconcileFullScan = false,
  }) async {
    final merged = mergeLibrary(
      localSongs.value,
      selected,
      discovered: _lastDiscoveredSongs,
      reconcileFullScan: reconcileFullScan && _lastScanWasFull,
    );
    localSongs.value = List.unmodifiable(merged);
    await _box.put(_songsKey, merged);
  }

  Future<void> remove(String identity) async {
    final updated = localSongs.value
        .where((song) => songIdentity(song) != identity)
        .map(Map<String, dynamic>.from)
        .toList();
    localSongs.value = List.unmodifiable(updated);
    await _box.put(_songsKey, updated);
  }

  Future<String?> cacheArtwork(Map song) async {
    final existing = song['artworkPath']?.toString();
    if (existing != null &&
        existing.isNotEmpty &&
        await File(existing).exists()) {
      return existing;
    }
    final id = song['mediaStoreId'];
    if (id is! int) return null;
    if (!await _hasConfirmedMediaPermission()) return null;
    Uint8List? bytes;
    try {
      bytes = await _dataSource.queryArtwork(id);
    } catch (error, stackTrace) {
      logger.log(
        'MediaStore queryArtwork rejected',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
    if (bytes == null || bytes.isEmpty) return null;
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}local_artwork',
    );
    await directory.create(recursive: true);
    final path = '${directory.path}${Platform.pathSeparator}$id.jpg';
    await File(path).writeAsBytes(bytes, flush: true);
    final updated = localSongs.value.map((item) {
      final copy = Map<String, dynamic>.from(item);
      if (songIdentity(copy) == songIdentity(song)) copy['artworkPath'] = path;
      return copy;
    }).toList();
    localSongs.value = List.unmodifiable(updated);
    await _box.put(_songsKey, updated);
    return path;
  }

  @visibleForTesting
  static List<Map<String, dynamic>> mergeLibrary(
    Iterable<Map> existing,
    Iterable<Map> imported, {
    Iterable<Map> discovered = const [],
    bool reconcileFullScan = false,
  }) {
    final result = existing.map(Map<String, dynamic>.from).toList();
    final byId = {
      for (var i = 0; i < result.length; i++) songIdentity(result[i])!: i,
    };
    final byReconciliation = <String, int>{
      for (var i = 0; i < result.length; i++)
        if (result[i]['reconciliationKey'] != null)
          result[i]['reconciliationKey'].toString(): i,
    };
    for (final raw in imported) {
      final next = Map<String, dynamic>.from(raw);
      var index = byId[songIdentity(next)];
      index ??= byReconciliation[next['reconciliationKey']?.toString()];
      if (index == null) {
        result.add(next);
        byId[songIdentity(next)!] = result.length - 1;
      } else {
        final stableId = result[index]['id'];
        final stableYtid = result[index]['ytid'];
        result[index] = {
          ...result[index],
          ...next,
          'id': stableId,
          'ytid': stableYtid,
          'missing': false,
        };
      }
    }
    if (reconcileFullScan) {
      final availableIds = discovered
          .map(songIdentity)
          .whereType<String>()
          .toSet();
      final availableKeys = discovered
          .map((song) => song['reconciliationKey']?.toString())
          .whereType<String>()
          .toSet();
      for (final song in result) {
        song['missing'] =
            !availableIds.contains(songIdentity(song)) &&
            !availableKeys.contains(song['reconciliationKey']?.toString());
      }
    }
    return result;
  }
}

late LocalAudioService localAudioService;

Future<void> initializeLocalAudioService() async {
  localAudioService = LocalAudioService(
    MediaStoreAudioDataSource(),
    PermissionHandlerLocalAudioGateway(),
  );
  try {
    await localAudioService.initialize();
  } catch (error, stackTrace) {
    logger.log(
      'Local audio service initialization failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
