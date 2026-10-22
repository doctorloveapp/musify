import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/mediaitem.dart';

void main() {
  test('current media item matches remote and namespaced local identities', () {
    const remote = MediaItem(
      id: 'queue-entry-1',
      title: 'Remote',
      extras: {'ytid': 'youtube-id'},
    );
    const local = MediaItem(
      id: 'queue-entry-2',
      title: 'Local',
      extras: {'ytid': 'local:external:42'},
    );

    expect(mediaItemMatchesSong(remote, {'ytid': 'youtube-id'}), isTrue);
    expect(mediaItemMatchesSong(local, {'ytid': 'local:external:42'}), isTrue);
    expect(mediaItemMatchesSong(remote, {'ytid': 'different'}), isFalse);
  });

  test('compact browse item excludes playback-only extras', () {
    final source = mapToMediaItem({
      'ytid': 'abcdefghijk',
      'title': 'Browse title',
      'artist': 'Browse artist',
      'album': 'Browse album',
      'highResImage': 'https://example.com/high.jpg',
      'lowResImage': 'https://example.com/low.jpg',
      'source': 'youtube',
      'duration': 240,
    });
    final artwork = Uri.parse(
      'content://com.danilo.musify.androidauto.artwork/art/key',
    );

    final compact = compactMediaItemForBrowse(
      source,
      id: 'song:liked_songs:abcdefghijk',
      artUri: artwork,
      displaySubtitle: 'Browse artist',
    );

    expect(compact.id, 'song:liked_songs:abcdefghijk');
    expect(compact.title, 'Browse title');
    expect(compact.artist, 'Browse artist');
    expect(compact.album, 'Browse album');
    expect(compact.artUri, artwork);
    expect(compact.playable, isTrue);
    expect(compact.extras, isNull);
    expect(compact.duration, isNull);
  });
}
