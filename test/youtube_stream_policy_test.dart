import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_parser/http_parser.dart';
import 'package:musify/services/proxy_endpoint.dart';
import 'package:musify/services/youtube_stream_policy.dart';
import 'package:youtube_explode_dart/src/retry.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

StreamManifest _manifest() => StreamManifest([
  AudioOnlyStreamInfo(
    VideoId('abcdefghijk'),
    140,
    Uri.parse('https://r1.googlevideo.com/videoplayback?test=1'),
    StreamContainer.mp4,
    const FileSize(1024),
    const Bitrate(128000),
    'aac',
    'medium',
    [],
    MediaType('audio', 'mp4'),
    null,
  ),
]);

void main() {
  late YoutubeExplode youtube;
  setUp(() => youtube = YoutubeExplode());
  tearDown(() => youtube.close());

  test(
    'advanced fallback is finite and preserves the successful client headers',
    () async {
      final clients = <YoutubeApiClient>[];
      final policy = YouTubeStreamPolicy(
        lookup: (_, _, client) async {
          clients.add(client);
          if (clients.length == 1) throw Exception('403 Forbidden');
          return _manifest();
        },
      );
      final manifest = await policy.resolveManifest(
        youtube,
        'abcdefghijk',
        advancedEnabled: true,
        timeout: const Duration(seconds: 1),
      );
      expect(clients, [YoutubeApiClient.visionOs, YoutubeApiClient.android]);
      expect(
        policy.headersFor(manifest.audioOnly.first.url),
        containsPair(
          'user-agent',
          clientRequestHeaders(YoutubeApiClient.android)['user-agent'],
        ),
      );
    },
  );

  for (final status in ['401 Unauthorized', '403 Forbidden']) {
    test('$status exhausts only the two explicit clients', () async {
      var count = 0;
      final policy = YouTubeStreamPolicy(
        lookup: (_, _, _) async {
          count++;
          throw Exception(status);
        },
      );
      await expectLater(
        policy.resolveManifest(
          youtube,
          'abcdefghijk',
          advancedEnabled: true,
          timeout: const Duration(seconds: 1),
        ),
        throwsException,
      );
      expect(count, 2);
    });
  }

  test('rate limits stop immediately without client rotation', () async {
    var count = 0;
    final policy = YouTubeStreamPolicy(
      lookup: (_, _, _) async {
        count++;
        throw Exception('429 Too Many Requests');
      },
    );
    await expectLater(
      policy.resolveManifest(
        youtube,
        'abcdefghijk',
        advancedEnabled: true,
        timeout: const Duration(seconds: 1),
      ),
      throwsException,
    );
    expect(count, 1);
  });

  test(
    'deadline stops without starting an overlapping fallback request',
    () async {
      var count = 0;
      final pending = Completer<StreamManifest>();
      final policy = YouTubeStreamPolicy(
        lookup: (_, _, _) {
          count++;
          return pending.future;
        },
      );
      await expectLater(
        policy.resolveManifest(
          youtube,
          'abcdefghijk',
          advancedEnabled: true,
          timeout: const Duration(milliseconds: 15),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(count, 1);
      pending.complete(_manifest());
    },
  );

  test(
    'empty audio manifests cannot be returned as successful resolution',
    () async {
      var count = 0;
      final policy = YouTubeStreamPolicy(
        lookup: (_, _, _) async {
          count++;
          return StreamManifest([]);
        },
      );
      await expectLater(
        policy.resolveManifest(
          youtube,
          'abcdefghijk',
          advancedEnabled: true,
          timeout: const Duration(seconds: 1),
        ),
        throwsException,
      );
      expect(count, 2);
    },
  );

  test('versioned cache restores URL and safe headers as one context', () {
    final uri = _manifest().audioOnly.first.url;
    final policy = YouTubeStreamPolicy();
    policy.remember(uri, {
      'User-Agent': 'test-client',
      'authorization': 'discard',
      'cookie': 'discard',
      'referer': 'bad\r\nheader',
    });
    final record = policy.cacheRecord(uri);
    final restored = YouTubeStreamPolicy();
    expect(restored.restoreRecord(record), uri.toString());
    expect(restored.headersFor(uri), {'user-agent': 'test-client'});
    expect(
      () => restored.headersFor(uri)['cookie'] = 'x',
      throwsUnsupportedError,
    );
  });

  for (final raw in [
    null,
    'old-url',
    {'version': 2},
    {'version': 1, 'url': 'https://evil.example/x', 'headers': {}},
    {
      'version': 1,
      'url': 'https://r1.googlevideo.com/x',
      'headers': {'x': 4},
    },
  ]) {
    test('invalid cache shape is a cache miss: $raw', () {
      expect(YouTubeStreamPolicy().restoreRecord(raw), isNull);
    });
  }

  for (final url in [
    'http://r1.googlevideo.com/x',
    'content://local/42',
    'file:///test.mp3',
    'https://googlevideo.com.evil.example/x',
    'https://user@r1.googlevideo.com/x',
  ]) {
    test('no stream headers or records for $url', () {
      final policy = YouTubeStreamPolicy();
      final uri = Uri.parse(url);
      policy.remember(uri, {'user-agent': 'secret-context'});
      expect(policy.headersFor(uri), isEmpty);
      expect(policy.cacheRecord(uri), isNull);
    });
  }

  test('header contexts are bounded and least-recently-used', () {
    final policy = YouTubeStreamPolicy();
    final first = Uri.https('r1.googlevideo.com', '/0');
    for (var n = 0; n < 256; n++) {
      policy.remember(Uri.https('r1.googlevideo.com', '/$n'), {
        'user-agent': 'test',
      });
    }
    policy.headersFor(first);
    policy.remember(Uri.https('r1.googlevideo.com', '/256'), {
      'user-agent': 'test',
    });
    expect(policy.headersFor(first), isNotEmpty);
    expect(policy.headersFor(Uri.https('r1.googlevideo.com', '/1')), isEmpty);
  });

  test(
    'cached HEAD validates with client headers and blocks external redirects',
    () async {
      final policy = YouTubeStreamPolicy();
      final uri = _manifest().audioOnly.first.url;
      policy.remember(uri, {'user-agent': 'test-client'});
      var count = 0;
      final client = MockClient((request) async {
        count++;
        expect(request.method, 'HEAD');
        expect(request.followRedirects, isFalse);
        expect(request.headers['user-agent'], 'test-client');
        return http.Response(
          '',
          302,
          headers: {'location': 'https://external.example/x'},
        );
      });
      addTearDown(client.close);
      expect(await policy.validateCachedUri(uri, client: client), isFalse);
      expect(count, 1);
    },
  );

  test('same-CDN redirects are bounded and valid 200 is accepted', () async {
    final policy = YouTubeStreamPolicy();
    final uri = _manifest().audioOnly.first.url;
    var count = 0;
    final client = MockClient((request) async {
      count++;
      return count == 1
          ? http.Response('', 302, headers: {'location': '/new'})
          : http.Response('', 200);
    });
    addTearDown(client.close);
    expect(await policy.validateCachedUri(uri, client: client), isTrue);
    expect(count, 2);
  });

  test(
    'one-attempt budget and legacy default retry budget remain distinct',
    () async {
      var calls = 0;
      await expectLater(
        retry<void>(null, () {
          calls++;
          throw Exception('test');
        }, retryBudget: 1),
        throwsException,
      );
      expect(calls, 1);
      calls = 0;
      await expectLater(
        retry<void>(null, () {
          calls++;
          throw Exception('test');
        }),
        throwsException,
      );
      expect(calls, 5);
    },
  );

  test('proxy endpoints reject private, malformed and reserved addresses', () {
    for (final value in [
      'localhost:80',
      '127.0.0.1:80',
      '10.0.0.1:8080',
      '192.168.1.1:3128',
      '172.16.0.1:80',
      '169.254.1.1:80',
      '100.64.1.1:80',
      '224.0.0.1:80',
      '256.2.3.4:80',
      '1.2.3.4:0',
      '1.2.3.4:65536',
      '1.2.3.4:80; DIRECT',
    ]) {
      expect(isPublicProxyAddress(value), isFalse, reason: value);
    }
    expect(isPublicProxyAddress('8.8.8.8:443'), isTrue);
    expect(isPublicProxyAddress('1.1.1.1:8080'), isTrue);
  });
}
