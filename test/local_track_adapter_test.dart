import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/local_audio_data_source.dart';
import 'package:musify/services/local_audio_service.dart';
import 'package:musify/utilities/local_track_adapter.dart';
import 'package:musify/utilities/mediaitem.dart';
import 'package:musify/utilities/song_source.dart';

void main() {
  const record = LocalAudioRecord(
    id: 42,
    title: '',
    displayName: 'Track One.mp3',
    data: '/storage/emulated/0/Music/Track One.mp3',
    uri: 'content://media/external/audio/media/42',
    durationMilliseconds: 61234,
    size: 123456,
    dateAdded: 10,
    dateModified: 20,
    artist: '<unknown>',
    extension: 'mp3',
    isMusic: true,
  );

  test('adapter creates a stable Musify-compatible local track', () {
    final song = LocalTrackAdapter.fromRecord(
      record,
      unknownArtist: 'Artista sconosciuto',
    );

    expect(songIdentity(song), 'local:external:42');
    expect(isDeviceLocalSong(song), isTrue);
    expect(song['title'], 'Track One');
    expect(song['artist'], 'Artista sconosciuto');
    expect(song['duration'], 61);
    expect(song['mimeType'], 'audio/mpeg');
    expect(song['localUri'], 'content://media/external/audio/media/42');
  });

  test('merge is idempotent and refreshes metadata', () {
    final original = LocalTrackAdapter.fromRecord(record);
    final changed = {...original, 'title': 'Updated title'};

    final merged = LocalAudioService.mergeLibrary([original], [changed]);

    expect(merged, hasLength(1));
    expect(merged.single['title'], 'Updated title');
    expect(merged.single['ytid'], original['ytid']);
  });

  test('full reconciliation marks only undiscovered tracks missing', () {
    final first = LocalTrackAdapter.fromRecord(record);
    final second = {
      ...first,
      'id': 'local:external:99',
      'ytid': 'local:external:99',
      'reconciliationKey': 'other',
    };

    final merged = LocalAudioService.mergeLibrary(
      [first, second],
      const [],
      discovered: [first],
      reconcileFullScan: true,
    );

    expect(merged[0]['missing'], isFalse);
    expect(merged[1]['missing'], isTrue);
  });

  test('MediaItem round-trip preserves local playback fields', () {
    final song = LocalTrackAdapter.fromRecord(record);
    final restored = mediaItemToMap(mapToMediaItem(song));

    expect(restored['source'], deviceLocalSource);
    expect(restored['localUri'], song['localUri']);
    expect(restored['mediaStoreId'], 42);
    expect(restored['duration'], 61);
  });
}
