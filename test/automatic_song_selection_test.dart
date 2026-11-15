import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/automatic_song_selection.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Video _video(int index, Duration? duration, {bool live = false}) => Video(
  VideoId('v${index.toString().padLeft(10, '0')}'),
  'Track $index',
  'Artist',
  ChannelId('UC0000000000000000000000'),
  null,
  null,
  null,
  '',
  duration,
  ThumbnailSet('v${index.toString().padLeft(10, '0')}'),
  [],
  Engagement(0, null, null),
  live,
);

void main() {
  for (final duration in [
    const Duration(seconds: 30),
    const Duration(minutes: 8),
    const Duration(minutes: 3),
    null,
  ]) {
    test('accepts duration $duration for automatic selection', () {
      final candidate = _video(1, duration);
      expect(selectAutomaticSong([candidate]), same(candidate));
    });
  }
  for (final duration in [
    Duration.zero,
    const Duration(seconds: 29),
    const Duration(minutes: 8, seconds: 1),
    const Duration(hours: 2),
  ]) {
    test(
      'skips duration $duration without reordering remaining candidates',
      () {
        final good = _video(2, const Duration(minutes: 3));
        expect(
          selectAutomaticSong([
            _video(1, duration),
            good,
            _video(3, const Duration(minutes: 4)),
          ]),
          same(good),
        );
      },
    );
  }
  test('live entries are excluded even without duration', () {
    expect(selectAutomaticSong([_video(1, null, live: true)]), isNull);
  });
  test('empty or fully excluded results return no recommendation', () {
    expect(selectAutomaticSong([]), isNull);
    expect(
      selectAutomaticSong([
        _video(1, const Duration(hours: 2)),
        _video(2, const Duration(seconds: 10)),
      ]),
      isNull,
    );
  });
}
