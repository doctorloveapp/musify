import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/playlist_cover.dart';

void main() {
  Map<String, dynamic> song(int index) => {
    'ytid': 'song-$index',
    'title': 'Song $index',
    'image': 'image-$index',
  };

  test('generated playlist cover selection is stable and limited to four', () {
    final playlist = <String, dynamic>{
      'source': 'user-created',
      'list': List.generate(6, song),
    };

    expect(ensureGeneratedPlaylistCover(playlist, random: Random(3)), isTrue);
    final firstSelection = List<String>.from(
      playlist[generatedPlaylistCoverIdsKey],
    );
    expect(firstSelection, hasLength(4));

    expect(ensureGeneratedPlaylistCover(playlist, random: Random(99)), isFalse);
    expect(playlist[generatedPlaylistCoverIdsKey], firstSelection);
    expect(generatedPlaylistCoverSongs(playlist), hasLength(4));
  });

  test('manual artwork takes precedence and clears generated metadata', () {
    final playlist = <String, dynamic>{
      'source': 'user-created',
      'list': [song(1), song(2)],
    };
    ensureGeneratedPlaylistCover(playlist, random: Random(1));
    playlist['image'] = 'custom-cover.jpg';

    expect(ensureGeneratedPlaylistCover(playlist), isTrue);
    expect(playlist.containsKey(generatedPlaylistCoverIdsKey), isFalse);
    expect(generatedPlaylistCoverSongs(playlist), isEmpty);
  });
}
