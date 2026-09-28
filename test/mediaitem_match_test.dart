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
}
