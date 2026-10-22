import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:musify/services/io_service.dart';

const _artworkDirectoryName = 'android_auto_artwork';
const _maximumOriginalBytes = 8 * 1024 * 1024;
const _maximumPrecacheQueue = 32;
const _maximumConcurrentPreloads = 2;

String get androidAutoArtworkAuthority {
  const flavor = String.fromEnvironment(
    'FLUTTER_APP_FLAVOR',
    defaultValue: 'github',
  );
  const flavorSuffix = flavor == 'fdroid' ? '.fdroid' : '';
  const debugSuffix = kDebugMode ? '.debug' : '';
  return 'com.danilo.musify$flavorSuffix$debugSuffix.androidauto.artwork';
}

/// Registers artwork sources without performing network I/O on the Android
/// Auto browse request. The native content provider consumes these small JSON
/// descriptors and serves cached, size-bounded JPEG thumbnails.
class AndroidAutoArtworkService {
  AndroidAutoArtworkService({this.rootPath, String? authority})
    : authority = authority ?? androidAutoArtworkAuthority;

  final String? rootPath;
  final String authority;
  final Map<String, Future<Uri?>> _registrations = {};
  final Queue<_PrecacheTask> _precacheQueue = Queue();
  final Set<String> _scheduledPreloads = {};
  int _activePreloads = 0;

  Directory get _directory => Directory(
    '${rootPath ?? applicationDirPath}${Platform.pathSeparator}'
    '$_artworkDirectoryName',
  );

  Future<Uri?> prepareSingle(String? source, {bool precache = false}) async {
    final normalized = _normalizeSource(source);
    if (normalized == null) return null;

    final parsed = Uri.tryParse(normalized);
    if (parsed?.scheme == 'android.resource') return parsed;

    final key = _digest('single\n$normalized');
    return _registrations.putIfAbsent(
      key,
      () =>
          _registerSingle(key, normalized, precache: precache).whenComplete(() {
            _registrations.remove(key);
          }),
    );
  }

  Future<Uri?> prepareMosaic(
    Iterable<String?> sources, {
    bool precache = false,
  }) async {
    final unique = <String>[];
    for (final source in sources) {
      final normalized = _normalizeSource(source);
      if (normalized == null || unique.contains(normalized)) continue;
      unique.add(normalized);
      if (unique.length == 4) break;
    }
    if (unique.length == 3) unique.removeLast();
    if (unique.isEmpty) return null;
    if (unique.length == 1) {
      return prepareSingle(unique.single, precache: precache);
    }

    final keys = <String>[];
    for (final source in unique) {
      final key = _digest('single\n$source');
      final uri = await _registrations.putIfAbsent(
        key,
        () => _registerSingle(key, source, precache: precache).whenComplete(() {
          _registrations.remove(key);
        }),
      );
      if (uri != null) keys.add(key);
    }
    if (keys.isEmpty) return null;
    if (keys.length == 1) return _contentUri(keys.single);

    final mosaicKey = _digest('mosaic\n${keys.join('\n')}');
    final directory = _directory;
    await directory.create(recursive: true);
    await _writeTextIfMissing(
      File('${directory.path}${Platform.pathSeparator}$mosaicKey.json'),
      jsonEncode({'kind': 'mosaic', 'keys': keys}),
    );
    return _contentUri(mosaicKey);
  }

  Future<Uri?> _registerSingle(
    String key,
    String source, {
    required bool precache,
  }) async {
    final directory = _directory;
    await directory.create(recursive: true);
    final specFile = File(
      '${directory.path}${Platform.pathSeparator}$key.json',
    );
    var persistedSource = source;

    if (source.startsWith('data:image/')) {
      try {
        final data = UriData.fromUri(Uri.parse(source));
        final bytes = data.contentAsBytes();
        if (bytes.isEmpty || bytes.length > _maximumOriginalBytes) return null;
        await _writeBytesIfMissing(
          File('${directory.path}${Platform.pathSeparator}$key.original'),
          bytes,
        );
        persistedSource = 'cached:';
      } on FormatException {
        return null;
      }
    }

    await _writeTextIfMissing(
      specFile,
      jsonEncode({'kind': 'single', 'source': persistedSource}),
    );
    if (precache && source.startsWith('https://')) {
      _schedulePrecache(key, Uri.parse(source));
    }
    return _contentUri(key);
  }

  String? _normalizeSource(String? source) {
    final value = source?.trim();
    if (value == null || value.isEmpty || value == 'null') return null;
    if (value.startsWith('/')) return Uri.file(value).toString();
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.scheme == 'data') {
      return value.startsWith('data:image/') ? value : null;
    }
    if (const {
      'https',
      'file',
      'content',
      'android.resource',
    }.contains(uri.scheme)) {
      return value;
    }
    return null;
  }

  String _digest(String value) => sha256.convert(utf8.encode(value)).toString();

  Uri _contentUri(String key) =>
      Uri(scheme: 'content', host: authority, pathSegments: ['art', key]);

  Future<void> _writeTextIfMissing(File target, String value) async {
    if (await target.exists()) return;
    await _writeAtomically(target, utf8.encode(value));
  }

  Future<void> _writeBytesIfMissing(File target, List<int> value) async {
    if (await target.exists()) return;
    await _writeAtomically(target, value);
  }

  Future<void> _writeAtomically(File target, List<int> bytes) async {
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      if (await target.exists()) {
        await temporary.delete();
      } else {
        await temporary.rename(target.path);
      }
    } on FileSystemException {
      if (await temporary.exists()) await temporary.delete();
      if (!await target.exists()) rethrow;
    }
  }

  void _schedulePrecache(String key, Uri source) {
    final original = File(
      '${_directory.path}${Platform.pathSeparator}$key.original',
    );
    if (original.existsSync() || !_scheduledPreloads.add(key)) return;
    if (_precacheQueue.length >= _maximumPrecacheQueue) {
      _scheduledPreloads.remove(key);
      return;
    }
    _precacheQueue.add(_PrecacheTask(key, source));
    _drainPrecacheQueue();
  }

  void _drainPrecacheQueue() {
    while (_activePreloads < _maximumConcurrentPreloads &&
        _precacheQueue.isNotEmpty) {
      final task = _precacheQueue.removeFirst();
      _activePreloads++;
      unawaited(
        _downloadOriginal(task).whenComplete(() {
          _activePreloads--;
          _scheduledPreloads.remove(task.key);
          _drainPrecacheQueue();
        }),
      );
    }
  }

  Future<void> _downloadOriginal(_PrecacheTask task) async {
    final directory = _directory;
    final target = File(
      '${directory.path}${Platform.pathSeparator}${task.key}.original',
    );
    if (await target.exists()) return;

    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.download',
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client
          .getUrl(task.source)
          .timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.userAgentHeader, 'Musify/11.4.2');
      final response = await request.close().timeout(
        const Duration(seconds: 7),
      );
      if (response.statusCode != HttpStatus.ok ||
          response.headers.contentType?.primaryType != 'image' ||
          (response.contentLength > _maximumOriginalBytes)) {
        return;
      }

      final sink = temporary.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.timeout(
          const Duration(seconds: 7),
        )) {
          received += chunk.length;
          if (received > _maximumOriginalBytes) {
            throw const FormatException('Artwork exceeds cache limit');
          }
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      if (received == 0) return;
      if (await target.exists()) {
        await temporary.delete();
      } else {
        await temporary.rename(target.path);
      }
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
    } finally {
      client.close(force: true);
    }
  }
}

class _PrecacheTask {
  const _PrecacheTask(this.key, this.source);

  final String key;
  final Uri source;
}

final androidAutoArtworkService = AndroidAutoArtworkService();
