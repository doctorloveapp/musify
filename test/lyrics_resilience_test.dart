import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musify/services/lyrics_manager.dart';

http.Response jsonResponse(Object value, [int status = 200]) => http.Response(
  utf8.decode(utf8.encode(jsonEncode(value))),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(LyricsManager.clearCache);
  const track = TrackInfo(
    artist: 'Artist',
    title: 'Song',
    duration: Duration(seconds: 100),
  );
  test('LRCLIB failure still returns static fallback', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'lrclib.net')
        return http.Response('broken json', 200);
      if (request.url.host == 'api.lyrics.ovh')
        return jsonResponse({'lyrics': 'Static fallback'});
      return http.Response('', 404);
    });
    final lyrics = await LyricsManager(client: client).fetchLyricsResult(track);
    expect(lyrics!.isSynced, isFalse);
    expect(lyrics.text, 'Static fallback');
  });
  test('static mode never calls LRCLIB', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.lyrics.ovh');
      return jsonResponse({'lyrics': 'Legacy static'});
    });
    expect(
      await LyricsManager(client: client).fetchLyrics('Artist', 'Song'),
      contains('Legacy static'),
    );
  });
  test('concurrent requests share the same lookup', () async {
    final response = Completer<http.Response>();
    var calls = 0;
    final manager = LyricsManager(
      client: MockClient((_) {
        calls++;
        return response.future;
      }),
    );
    final first = manager.fetchLyricsResult(track);
    final second = manager.fetchLyricsResult(track);
    response.complete(
      jsonResponse([
        {'trackName': 'Song', 'artistName': 'Artist', 'plainLyrics': 'shared'},
      ]),
    );
    expect((await first)!.text, 'shared');
    expect((await second)!.text, 'shared');
    expect(calls, 1);
  });
  test('global lookup budget stops retries after a stalled provider', () async {
    var calls = 0;
    final never = Completer<http.Response>();
    final manager = LyricsManager(
      lookupBudget: const Duration(milliseconds: 25),
      client: MockClient((_) {
        calls++;
        return never.future;
      }),
    );
    final watch = Stopwatch()..start();
    expect(await manager.fetchLyricsResult(track), isNull);
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    expect(calls, 1);
    never.complete(http.Response('', 404));
  });
  test('LRU cache remains bounded and evicts oldest entry', () async {
    var calls = 0;
    final manager = LyricsManager(
      client: MockClient((request) async {
        calls++;
        return jsonResponse([
          {
            'trackName': request.url.queryParameters['track_name'],
            'artistName': 'Artist',
            'plainLyrics': 'text',
          },
        ]);
      }),
    );
    for (var i = 0; i < 51; i++) {
      await manager.fetchLyricsResult(
        TrackInfo(artist: 'Artist', title: 'Song $i'),
      );
    }
    expect(calls, 51);
    await manager.fetchLyricsResult(
      const TrackInfo(artist: 'Artist', title: 'Song 50'),
    );
    expect(calls, 51);
    await manager.fetchLyricsResult(
      const TrackInfo(artist: 'Artist', title: 'Song 0'),
    );
    expect(calls, 52);
  });
}
