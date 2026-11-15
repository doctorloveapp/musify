import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/challenges/ejs/base_ejs_solver.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/challenges/js_challenge.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class _EjsSolver extends BaseEJSSolver {
  var executions = 0;
  @override
  Future<String> executeJavaScript(String jsCode) async {
    executions++;
    expect(jsCode, contains('valid-player-script'));
    return jsonEncode({
      'type': 'result',
      'responses': [
        {
          'type': 'result',
          'data': {'a': 'decoded-a', 'b': 'decoded-b'},
        },
      ],
    });
  }
}

class _Solver extends BaseJSChallengeSolver {
  _Solver({this.failBulk = true, this.failIndividual = true});
  final bool failBulk;
  final bool failIndividual;
  var bulkCalls = 0;
  var singleCalls = 0;
  @override
  Future<Map<String, String?>> solveBulk(
    String playerUrl,
    Map<JSChallengeType, List<String>> requests,
  ) async {
    bulkCalls++;
    if (failBulk) throw Exception('Fixture bulk failure');
    return {
      for (final list in requests.values)
        for (final key in list) key: 'decoded',
    };
  }

  @override
  Future<String> solve(
    String playerUrl,
    JSChallengeType type,
    String challenge,
  ) async {
    singleCalls++;
    if (failIndividual) throw Exception('Fixture individual failure');
    return 'decoded';
  }
}

Map<String, dynamic> _format(int tag, {String? n, bool signature = false}) {
  final uri = Uri.https('r1.googlevideo.com', '/stream-$tag', {
    if (n != null) 'n': n,
  });
  return {
    'itag': tag,
    'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
    'bitrate': 128000,
    'contentLength': '1024',
    if (signature)
      'signatureCipher': Uri(
        queryParameters: {'url': uri.toString(), 's': 'encrypted', 'sp': 'sig'},
      ).query
    else
      'url': uri.toString(),
  };
}

Future<StreamManifest> _resolve(
  List<Map<String, dynamic>> formats, {
  BaseJSChallengeSolver? solver,
  required List<Uri> headRequests,
}) async {
  final transport = MockClient((request) async {
    if (request.method == 'HEAD') {
      headRequests.add(request.url);
      return http.Response('', 200, request: request);
    }
    if (request.method == 'POST') {
      return http.Response(
        jsonEncode({
          'playabilityStatus': {'status': 'OK'},
          'streamingData': {'adaptiveFormats': formats},
        }),
        200,
        request: request,
      );
    }
    return http.Response(
      '''<html>
      <head><meta property="og:url" content="https://www.youtube.com/watch?v=abcdefghijk"></head>
      <body><div id="player"></div>
      <script src="/s/player/test/player_ias.vflset/en_US/base.js"></script>
      <script>ytcfg.set({"INNERTUBE_CONTEXT":{"client":{"visitorData":"fixture"}}});</script>
      </body></html>''',
      200,
      headers: {'set-cookie': 'TEST=fixture;'},
      request: request,
    );
  });
  final client = StreamClient(YoutubeHttpClient(transport), jsSolver: solver);
  try {
    return await client.getManifest(
      'abcdefghijk',
      ytClients: [YoutubeApiClient.android],
      retryBudget: 1,
    );
  } finally {
    transport.close();
  }
}

void main() {
  for (final failure in [
    http.Response('denied', 403),
    http.Response('error', 500),
    http.Response('', 200),
  ]) {
    test(
      'failed script download (${failure.statusCode}, ${failure.body.length} bytes) is not cached',
      () async {
        final solver = _EjsSolver();
        var downloads = 0;
        await http.runWithClient(
          () async {
            await expectLater(
              solver.solve(
                'https://youtube.com/player.js',
                JSChallengeType.n,
                'a',
              ),
              throwsException,
            );
            expect(solver.executions, 0);
            expect(
              await solver.solve(
                'https://youtube.com/player.js',
                JSChallengeType.n,
                'a',
              ),
              'decoded-a',
            );
            expect(
              await solver.solve(
                'https://youtube.com/player.js',
                JSChallengeType.n,
                'a',
              ),
              'decoded-a',
            );
            expect(
              await solver.solve(
                'https://youtube.com/player.js',
                JSChallengeType.sig,
                'b',
              ),
              'decoded-b',
            );
          },
          () => MockClient((request) async {
            downloads++;
            return downloads == 1
                ? failure
                : http.Response('valid-player-script', 200);
          }),
        );
        expect(downloads, 2);
        expect(solver.executions, 2);
      },
    );
  }

  for (final type in ['n', 'signature']) {
    for (final advanced in [false, true]) {
      test(
        'unsolved $type is skipped; valid audio survives (advanced=$advanced)',
        () async {
          StreamFilterPolicy.advancedEnabled = advanced;
          addTearDown(() => StreamFilterPolicy.advancedEnabled = false);
          final heads = <Uri>[];
          final solver = _Solver();
          final result = await _resolve(
            [
              _format(
                140,
                n: type == 'n' ? 'encrypted' : null,
                signature: type == 'signature',
              ),
              _format(141),
            ],
            solver: solver,
            headRequests: heads,
          );
          expect(result.audioOnly.map((stream) => stream.tag), [141]);
          expect(heads.single.path, '/stream-141');
          expect(solver.bulkCalls, 1);
          expect(solver.singleCalls, 1);
        },
      );
    }
  }

  test(
    'all unsolved formats surface an error without validation requests',
    () async {
      final heads = <Uri>[];
      await expectLater(
        _resolve(
          [_format(140, n: 'encrypted')],
          solver: _Solver(),
          headRequests: heads,
        ),
        throwsException,
      );
      expect(heads, isEmpty);
    },
  );

  for (final bulk in [true, false]) {
    test(
      'successful ${bulk ? 'bulk' : 'individual'} solution preserves playable formats',
      () async {
        final solver = _Solver(failBulk: !bulk, failIndividual: false);
        final heads = <Uri>[];
        final result = await _resolve(
          [_format(140, n: 'encrypted', signature: true)],
          solver: solver,
          headRequests: heads,
        );
        final uri = result.audioOnly.single.url;
        expect(uri.queryParameters['n'], 'decoded');
        expect(uri.queryParameters['sig'], 'decoded');
        expect(solver.singleCalls, bulk ? 0 : 2);
        expect(heads.single, uri);
      },
    );
  }

  test(
    'without JS solver, the existing client path remains unchanged',
    () async {
      final heads = <Uri>[];
      final result = await _resolve([
        _format(140, n: 'untouched'),
      ], headRequests: heads);
      expect(result.audioOnly.single.url.queryParameters['n'], 'untouched');
      expect(heads.length, 1);
    },
  );
}
