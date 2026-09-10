import 'package:flutter_test/flutter_test.dart';
import 'package:musify/screens/local_audio_scan_page.dart';

void main() {
  final songs = <Map<String, dynamic>>[
    {
      'title': 'Notte romana',
      'displayName': 'notte_romana.flac',
      'artist': 'Dan King',
      'album': 'Roma',
      'folder': '/Music/Italiane',
      'data': '/storage/emulated/0/Music/Italiane/notte_romana.flac',
    },
    {
      'title': 'Morning Light',
      'displayName': 'morning.mp3',
      'artist': 'Example',
      'album': 'Sunrise',
      'folder': '/Music/English',
      'data': '/storage/emulated/0/Music/English/morning.mp3',
    },
  ];

  test('filters the current scan by title, filename, artist and folder', () {
    expect(filterLocalAudioCandidates(songs, 'NOTTE'), [songs.first]);
    expect(filterLocalAudioCandidates(songs, 'dan king'), [songs.first]);
    expect(filterLocalAudioCandidates(songs, 'italiane'), [songs.first]);
    expect(filterLocalAudioCandidates(songs, 'morning.mp3'), [songs.last]);
    expect(filterLocalAudioCandidates(songs, 'missing'), isEmpty);
  });
}
