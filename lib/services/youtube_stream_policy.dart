import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:musify/constants/clients.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

typedef ManifestLookup = Future<StreamManifest> Function(
  YoutubeExplode youtube,
  String songId,
  YoutubeApiClient client,
);

final youtubeStreamPolicy = YouTubeStreamPolicy();

/// Stream URLs and their resolving client stay paired, including cache restores.
/// Client fallback is opt-in and never changes proxy settings or playback queues.
class YouTubeStreamPolicy {
  YouTubeStreamPolicy({ManifestLookup? lookup})
    : _lookup = lookup ?? _lookupManifest;

  final ManifestLookup _lookup;
  final _contexts = <String, Map<String, String>>{};
  static const _maximumContexts = 256;
  static const _allowedHeaders = {
    'user-agent',
    'x-youtube-client-name',
    'x-youtube-client-version',
    'origin',
    'referer',
  };

  static Future<StreamManifest> _lookupManifest(
    YoutubeExplode youtube,
    String songId,
    YoutubeApiClient client,
  ) => youtube.videos.streams.getManifest(
    songId,
    ytClients: [client],
    retryBudget: 1,
  );

  static bool isYouTubeStreamUri(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      (uri.host == 'googlevideo.com' ||
          uri.host.endsWith('.googlevideo.com') ||
          uri.host == 'youtube.com' ||
          uri.host.endsWith('.youtube.com'));

  Future<StreamManifest> resolveManifest(
    YoutubeExplode youtube,
    String songId, {
    required bool advancedEnabled,
    required Duration timeout,
  }) async {
    if (!advancedEnabled) {
      // Preserve the existing client and retry policy when the toggle is OFF.
      return youtube.videos.streams
          .getManifest(songId, ytClients: customClients)
          .timeout(timeout);
    }
    final watch = Stopwatch()..start();
    Object? lastError;
    StackTrace? lastStack;
    for (final client in [
      YoutubeApiClient.visionOs,
      YoutubeApiClient.android,
    ]) {
      final remaining = timeout - watch.elapsed;
      if (remaining <= Duration.zero) break;
      final limit = remaining < const Duration(seconds: 8)
          ? remaining
          : const Duration(seconds: 8);
      try {
        final manifest = await _lookup(youtube, songId, client).timeout(limit);
        if (manifest.audioOnly.isEmpty) {
          throw YoutubeExplodeException('No compatible audio streams');
        }
        final headers = _safeHeaders(clientRequestHeaders(client));
        for (final stream in manifest.audioOnly) {
          remember(stream.url, headers);
        }
        return manifest;
      } catch (error, stack) {
        // Do not retry rate limits or explicit unplayable-content restrictions.
        if (error is TimeoutException ||
            error is RequestLimitExceededException ||
            error is VideoUnplayableException ||
            RegExp(r'\b429\b').hasMatch(error.toString()))
          rethrow;
        lastError = error;
        lastStack = stack;
      }
    }
    if (lastError != null) Error.throwWithStackTrace(lastError, lastStack!);
    throw TimeoutException('YouTube stream lookup budget exhausted');
  }

  static Map<String, String> _safeHeaders(Map<String, String> headers) => {
    for (final entry in headers.entries)
      if (_allowedHeaders.contains(entry.key.toLowerCase()) &&
          !RegExp(r'[\r\n]').hasMatch(entry.value))
        entry.key.toLowerCase(): entry.value,
  };

  void remember(Uri uri, Map<String, String> headers) {
    if (!isYouTubeStreamUri(uri)) return;
    final key = uri.toString();
    _contexts.remove(key);
    _contexts[key] = Map.unmodifiable(_safeHeaders(headers));
    while (_contexts.length > _maximumContexts) {
      _contexts.remove(_contexts.keys.first);
    }
  }

  Map<String, String> headersFor(Uri uri) {
    if (!isYouTubeStreamUri(uri)) return const {};
    final headers = _contexts.remove(uri.toString());
    if (headers == null) return const {};
    _contexts[uri.toString()] = headers;
    return headers;
  }

  Map<String, dynamic>? cacheRecord(Uri uri) {
    if (!isYouTubeStreamUri(uri) || !_contexts.containsKey(uri.toString()))
      return null;
    return {'version': 1, 'url': uri.toString(), 'headers': headersFor(uri)};
  }

  String? restoreRecord(dynamic raw) {
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['url'] is! String ||
        raw['headers'] is! Map)
      return null;
    final uri = Uri.tryParse(raw['url']);
    if (uri == null || !isYouTubeStreamUri(uri)) return null;
    final headers = <String, String>{};
    for (final entry in (raw['headers'] as Map).entries) {
      if (entry.key is! String || entry.value is! String) return null;
      headers[entry.key] = entry.value;
    }
    remember(uri, headers);
    return uri.toString();
  }

  /// Manual redirects keep client headers away from arbitrary third-party hosts.
  Future<bool> validateCachedUri(
    Uri uri, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final ownedClient = client == null ? http.Client() : null;
    final transport = client ?? ownedClient!;
    final watch = Stopwatch()..start();
    final headers = headersFor(uri);
    try {
      for (var redirect = 0; redirect <= 3; redirect++) {
        if (!isYouTubeStreamUri(uri)) return false;
        final remaining = timeout - watch.elapsed;
        if (remaining <= Duration.zero) return false;
        final request = http.Request('HEAD', uri)..followRedirects = false;
        request.headers.addAll(headers);
        final response = await transport.send(request).timeout(remaining);
        final bodyBudget = timeout - watch.elapsed;
        if (bodyBudget <= Duration.zero) return false;
        await response.stream.drain<void>().timeout(bodyBudget);
        if (response.statusCode >= 200 && response.statusCode < 300)
          return true;
        if (![301, 302, 303, 307, 308].contains(response.statusCode))
          return false;
        final location = response.headers['location'];
        if (location == null) return false;
        uri = uri.resolve(location);
      }
    } catch (_) {
      return false;
    } finally {
      ownedClient?.close();
    }
    return false;
  }
}
