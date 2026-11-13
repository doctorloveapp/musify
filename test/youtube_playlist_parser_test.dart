import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/pages/playlist_page.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const _channel = 'UC0000000000000000000000';
String _id(int n) => 'v${n.toString().padLeft(10, '0')}';
Map<String, dynamic> _classic(int n) => {
  'playlistVideoRenderer': {
    'videoId': _id(n),
    'title': {
      'runs': [
        {'text': 'Track $n'},
      ],
    },
    'ownerText': {
      'runs': [
        {
          'text': 'Artist',
          'navigationEndpoint': {
            'browseEndpoint': {'browseId': _channel},
          },
        },
      ],
    },
    'lengthText': {'simpleText': '3:10'},
  },
};
Map<String, dynamic> _music(int n) => {
  'musicResponsiveListItemRenderer': {
    'playlistItemData': {'videoId': _id(n)},
    'flexColumns': [
      for (final text in ['Track $n', 'Artist'])
        {
          'musicResponsiveListItemFlexColumnRenderer': {
            'text': {
              'runs': [
                {'text': text},
              ],
            },
          },
        },
    ],
    'fixedColumns': [
      {
        'musicResponsiveListItemFixedColumnRenderer': {
          'text': {
            'runs': [
              {'text': '3:10'},
            ],
          },
        },
      },
    ],
  },
};
Map<String, dynamic> _token(String value) => {
  'continuationItemRenderer': {
    'continuationEndpoint': {
      'continuationCommand': {'token': value},
    },
  },
};
Map<String, dynamic> _page(List<Map<String, dynamic>> items) => {
  'contents': {
    'twoColumnBrowseResultsRenderer': {
      'tabs': [
        {
          'tabRenderer': {
            'content': {
              'sectionListRenderer': {
                'contents': [
                  {
                    'itemSectionRenderer': {
                      'contents': [
                        {
                          'playlistVideoListRenderer': {'contents': items},
                        },
                      ],
                    },
                  },
                ],
              },
            },
          },
        },
      ],
    },
  },
};
String _html(Map<String, dynamic> data, {bool dedicated = false}) => dedicated
    ? '<script id="yt-initial-data" type="application/json">${jsonEncode(data)}</script>'
    : '<script>var ytInitialData = ${jsonEncode(data)};</script>';

class _Client extends YoutubeHttpClient {
  _Client({this.musicEmpty = false, this.stuck = false});
  final bool musicEmpty;
  final bool stuck;
  final posts = <Map<String, dynamic>>[];
  var htmlReads = 0;
  @override
  Future<Map<String, dynamic>> sendPost(
    String action,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    bool validate = false,
  }) async {
    posts.add(data);
    if (musicEmpty) return {};
    final continuation = data['continuation'] as String?;
    final start = continuation == null ? 0 : int.parse(continuation);
    final items = [
      for (var n = start; n < start + 100; n++) _music(n),
      if (start < 200) _token(stuck ? '100' : '${start + 100}'),
    ];
    if (continuation != null)
      return {
        'onResponseReceivedActions': [
          {
            'appendContinuationItemsAction': {'continuationItems': items},
          },
        ],
      };
    return {
      'contents': {
        'twoColumnBrowseResultsRenderer': {
          'secondaryContents': {
            'sectionListRenderer': {
              'contents': [
                {
                  'musicPlaylistShelfRenderer': {'contents': items},
                },
              ],
            },
          },
        },
      },
    };
  }

  @override
  Future<String> getString(
    dynamic url, {
    Map<String, String> headers = const {},
    bool validate = true,
  }) async {
    htmlReads++;
    return _html(_page([_classic(1)]));
  }
}

void main() {
  for (final dedicated in [false, true]) {
    test('classic playlist parser: dedicated JSON = $dedicated', () {
      final page = PlaylistPage.parse(
        _html(_page([_classic(1)]), dedicated: dedicated),
        'PLtest',
      );
      expect(page.videos.single.id, _id(1));
      expect(page.videos.single.title, 'Track 1');
      expect(
        page.videos.single.duration,
        const Duration(minutes: 3, seconds: 10),
      );
      expect(page.videos.single.viewCount, 0);
    });
  }

  test('malformed dedicated JSON falls back to existing marker parser', () {
    final page = PlaylistPage.parse(
      '<script id="yt-initial-data">bad-json</script>'
          '${_html(_page([_classic(2)]))}',
      'PLtest',
    );
    expect(page.videos.single.id, _id(2));
  });

  test('lockup playlist rows and nested continuation tokens are accepted', () {
    final page = PlaylistPage.parse(
      _html(
        _page([
          {
            'lockupViewModel': {
              'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
              'contentId': _id(3),
              'metadata': {
                'lockupMetadataViewModel': {
                  'title': {'content': 'New layout'},
                },
              },
            },
          },
          {
            'continuationItemViewModel': {
              'continuationCommand': {
                'innertubeCommand': {
                  'continuationCommand': {'token': 'next'},
                },
              },
            },
          },
        ]),
      ),
      'PLtest',
    );
    expect(page.videos.single.id, _id(3));
    expect(page.videos.single.title, 'New layout');
  });

  test(
    'WEB_REMIX pagination exceeds 200 tracks with one consistent context',
    () async {
      final transport = _Client();
      addTearDown(transport.close);
      final videos = await PlaylistClient(transport)
          .getVideos('PLabcdefghijklmnop')
          .toList();
      expect(videos.length, 300);
      expect(videos.map((v) => v.id.value).toSet().length, 300);
      expect(transport.htmlReads, 0);
      expect(transport.posts.length, 3);
      for (final post in transport.posts) {
        expect(post['context']['client']['clientName'], 'WEB_REMIX');
      }
    },
  );

  test(
    'uploads/mixes retain HTML fallback when music client is empty',
    () async {
      final transport = _Client(musicEmpty: true);
      addTearDown(transport.close);
      final videos = await PlaylistClient(transport)
          .getVideos('UUabcdefghijklmnopqrstuv')
          .toList();
      expect(videos.length, 1);
      expect(transport.htmlReads, 1);
    },
  );

  test('repeated continuation token terminates rather than hanging', () async {
    final transport = _Client(stuck: true);
    addTearDown(transport.close);
    final videos = await PlaylistClient(transport)
        .getVideos('PLabcdefghijklmnop')
        .toList();
    expect(videos.length, 100);
    expect(transport.posts.length, 2);
  });
}
