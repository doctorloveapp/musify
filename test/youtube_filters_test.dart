import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/services/youtube_filter_advice.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/player/player_response.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('musify_filters_');
    Hive.init(root.path);
    for (final box in ['settings', 'user', 'userNoBackup', 'cache']) {
      await Hive.openBox(box);
    }
  });
  tearDownAll(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });
  setUp(() async {
    await Hive.box('settings').clear();
    reloadSettingsFromStorage();
  });

  final response = PlayerResponse({
    'streamingData': {
      'adaptiveFormats': [
        {'itag': 1, 'url': 'https://example.org/standard'},
        {
          'itag': 2,
          'url': 'https://example.org/drm',
          'drmFamilies': ['widevine'],
        },
        {
          'itag': 3,
          'url': 'https://example.org/otf',
          'type': 'FORMAT_STREAM_TYPE_OTF',
        },
        {'itag': 4, 'url': 'https://example.org/drc', 'isDrc': true},
      ],
    },
  });

  test('filters default OFF while synced lyrics default ON', () {
    expect(advancedYouTubeStreamFilters.value, isFalse);
    expect(syncedLyricsEnabled.value, isTrue);
    expect(StreamFilterPolicy.advancedEnabled, isFalse);
    expect(
      StreamFilterPolicy.apply(response.adaptiveStreams).map((s) => s.tag),
      [1, 2, 3, 4],
    );
  });
  test('native response flags and opt-in filtering match upstream', () async {
    await setAdvancedYouTubeStreamFilters(true);
    expect(response.adaptiveStreams[1].isDrmProtected, isTrue);
    expect(response.adaptiveStreams[2].isOtf, isTrue);
    expect(response.adaptiveStreams[3].isDrc, isTrue);
    expect(
      StreamFilterPolicy.apply(response.adaptiveStreams).map((s) => s.tag),
      [1],
    );
    await setAdvancedYouTubeStreamFilters(false);
    expect(StreamFilterPolicy.apply(response.adaptiveStreams).length, 4);
  });
  test(
    'an explicitly disabled lyrics setting stays disabled after reload',
    () async {
      await setSyncedLyricsEnabled(false);
      reloadSettingsFromStorage();
      expect(syncedLyricsEnabled.value, isFalse);
      await Hive.box('settings').close();
      await Hive.openBox('settings');
      reloadSettingsFromStorage();
      expect(syncedLyricsEnabled.value, isFalse);
      expect(advancedYouTubeStreamFilters.value, isFalse);
    },
  );
  test(
    'all rejected formats do not silently bypass the opted-in filter',
    () async {
      await setAdvancedYouTubeStreamFilters(true);
      expect(
        StreamFilterPolicy.apply(response.adaptiveStreams.skip(1)),
        isEmpty,
      );
      await setAdvancedYouTubeStreamFilters(false);
      expect(
        StreamFilterPolicy.apply(response.adaptiveStreams.skip(1)).length,
        3,
      );
    },
  );
  test(
    'preferences survive box reopen without altering existing data',
    () async {
      await Hive.box('settings').put('existingPreference', 'keep');
      await Hive.box('user').put('likedSongs', ['local:42', 'youtube-id']);
      await setSyncedLyricsEnabled(true);
      await setAdvancedYouTubeStreamFilters(true);
      await Hive.box('settings').close();
      await Hive.openBox('settings');
      reloadSettingsFromStorage();
      expect(syncedLyricsEnabled.value, isTrue);
      expect(advancedYouTubeStreamFilters.value, isTrue);
      expect(StreamFilterPolicy.advancedEnabled, isTrue);
      expect(Hive.box('settings').get('existingPreference'), 'keep');
      expect(Hive.box('user').get('likedSongs'), ['local:42', 'youtube-id']);
    },
  );
  test('filter advice is optional, throttled and never enables filters', () {
    var now = DateTime(2026, 11, 13);
    final advice = YouTubeFilterAdvice(now: () => now);
    expect(advice.report('403 Forbidden', filtersEnabled: false), isTrue);
    expect(
      advice.report('Stream non riproducibile', filtersEnabled: false),
      isFalse,
    );
    now = now.add(const Duration(minutes: 3));
    expect(advice.report('no audio streams', filtersEnabled: true), isFalse);
    expect(advice.report('403', filtersEnabled: false, online: false), isFalse);
    expect(advice.report('network timeout', filtersEnabled: false), isFalse);
    expect(
      advice.report('no compatible streams', filtersEnabled: false),
      isTrue,
    );
    expect(advancedYouTubeStreamFilters.value, isFalse);
    expect(advice.notices.value, 2);
    advice.notices.dispose();
  });
}
