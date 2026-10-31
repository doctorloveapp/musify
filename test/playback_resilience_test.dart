import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/main.dart' as app;
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/io_service.dart';
import 'package:musify/services/local_audio_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:rxdart/rxdart.dart';

/// Keeps just_audio's real source/sequence metadata while replacing only the
/// native transport. play() stays pending until pause(), just like the device.
class _SimulatedAudioPlayer extends AudioPlayer {
  _SimulatedAudioPlayer() : super(handleAudioSessionActivation: false);

  final errors = StreamController<PlayerException>.broadcast();
  final states = BehaviorSubject<PlayerState>.seeded(
    PlayerState(false, ProcessingState.idle),
  );
  final attemptedUris = <String>[];
  Completer<void>? _playback;

  @override
  Stream<PlayerException> get errorStream => errors.stream;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<ProcessingState> get processingStateStream =>
      states.stream.map((state) => state.processingState).distinct();
  @override
  ProcessingState get processingState => states.value.processingState;
  @override
  bool get playing => states.value.playing;
  @override
  Duration? get duration => const Duration(minutes: 3);

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    await super.setAudioSource(source, preload: false);
    final uri = (source as UriAudioSource).uri.toString();
    attemptedUris.add(uri);
    if (uri.endsWith('/403') || uri.endsWith('/401')) {
      final error = PlayerException(
        int.parse(uri.split('/').last),
        'Restricted',
        0,
      );
      errors.add(error);
      throw error;
    }
    states.add(PlayerState(false, ProcessingState.ready));
    return duration;
  }

  @override
  Future<void> play() {
    states.add(PlayerState(true, ProcessingState.ready));
    _playback = Completer<void>();
    return _playback!.future;
  }

  @override
  Future<void> pause() async {
    states.add(PlayerState(false, processingState));
    if (_playback?.isCompleted == false) _playback!.complete();
  }

  @override
  Future<void> stop() => pause();
  @override
  Future<void> setAndroidAudioAttributes(
    AndroidAudioAttributes attributes,
  ) async {}
  @override
  Future<void> setLoopMode(LoopMode mode) async {}
  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {}

  @override
  Future<void> dispose() async {
    await pause();
    await super.dispose();
    await errors.close();
    await states.close();
  }
}

Map<String, dynamic> _song(String id) => {
  'ytid': 'local:$id',
  'source': 'local-device',
  'title': id,
  'artist': 'Test',
  'localUri': 'content://musify.test/audio/$id',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporaryRoot;
  late _SimulatedAudioPlayer player;
  late MusifyAudioHandler handler;
  final skips = <void>[];
  StreamSubscription<void>? notices;
  final originalDebugPrint = debugPrint;

  setUpAll(() async {
    debugPrint = (String? message, {int? wrapWidth}) {};
    temporaryRoot = await Directory.systemTemp.createTemp('musify_resilience_');
    applicationDirPath = temporaryRoot.path;
    Hive.init(temporaryRoot.path);
    for (final name in [
      'settings',
      'user',
      'userNoBackup',
      'cache',
      'localLibrary',
    ]) {
      await Hive.openBox<dynamic>(name);
    }
    await initializeLocalAudioService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_session'),
          (_) async => null,
        );
  });

  setUp(() async {
    skipUnplayableSongs.value = true;
    offlineMode.value = true;
    wrappedEnabled.value = false;
    playNextSongAutomatically.value = false;
    repeatNotifier.value = AudioServiceRepeatMode.none;
    player = _SimulatedAudioPlayer();
    handler = MusifyAudioHandler(player: player);
    app.audioHandler = handler;
    skips.clear();
    notices = handler.skippedPlaybackErrors.listen(skips.add);
  });

  tearDown(() async {
    await notices?.cancel();
    await handler.stop();
    await player.dispose();
    // Let the existing look-ahead callback finish before the next test.
    await Future<void>.delayed(const Duration(milliseconds: 2100));
  });

  tearDownAll(() async {
    debugPrint = originalDebugPrint;
    await Hive.close();
    await temporaryRoot.delete(recursive: true);
  });

  for (final status in ['401', '403']) {
    test(
      'skips simulated $status once and starts the next queue entry',
      () async {
        await handler
            .addPlaylistToQueue([_song(status), _song('good')], replace: true)
            .timeout(const Duration(seconds: 2));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(handler.currentQueueIndex, 1);
        expect(handler.currentSong?['ytid'], 'local:good');
        expect(player.playing, isTrue);
        expect(player.attemptedUris, hasLength(2));
        expect(skips, hasLength(1));
      },
    );
  }

  test('disabled toggle stops on the failed entry without skipping', () async {
    skipUnplayableSongs.value = false;
    await handler.addPlaylistToQueue([
      _song('403'),
      _song('good'),
    ], replace: true);
    expect(handler.currentQueueIndex, 0);
    expect(player.playing, isFalse);
    expect(player.attemptedUris, hasLength(1));
    expect(skips, isEmpty);
  });

  test('an error after a good song advances past the failed index', () async {
    await handler.addPlaylistToQueue([
      _song('first'),
      _song('403'),
      _song('last'),
    ], replace: true);
    await handler.skipToNext().timeout(const Duration(seconds: 2));
    expect(handler.currentQueueIndex, 2);
    expect(handler.currentSong?['ytid'], 'local:last');
    expect(player.attemptedUris, hasLength(3));
    expect(player.playing, isTrue);
  });

  test(
    'more than three consecutive unavailable entries can be skipped',
    () async {
      await handler
          .addPlaylistToQueue([
            _song('401'),
            _song('403'),
            _song('401'),
            _song('403'),
            _song('good'),
          ], replace: true)
          .timeout(const Duration(seconds: 2));
      expect(handler.currentQueueIndex, 4);
      expect(player.playing, isTrue);
      expect(player.attemptedUris, hasLength(5));
    },
  );

  test('runtime errors and duplicate events advance only once', () async {
    await handler
        .addPlaylistToQueue([_song('first'), _song('good')], replace: true)
        .timeout(const Duration(seconds: 2));
    player.errors
      ..add(PlayerException(403, 'Forbidden during playback', 0))
      ..add(PlayerException(403, 'Duplicate platform event', 0));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(handler.currentQueueIndex, 1);
    expect(player.playing, isTrue);
    expect(skips, hasLength(1));
  });

  test('late errors after a manual pause cannot restart the queue', () async {
    await handler.addPlaylistToQueue([
      _song('first'),
      _song('good'),
    ], replace: true);
    await handler.pause();
    player.errors.add(PlayerException(403, 'Late platform event', 0));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(handler.currentQueueIndex, 0);
    expect(player.playing, isFalse);
    expect(skips, isEmpty);
  });

  test(
    'repeat all stops after each unavailable entry was attempted once',
    () async {
      repeatNotifier.value = AudioServiceRepeatMode.all;
      await handler
          .addPlaylistToQueue([_song('401'), _song('403')], replace: true)
          .timeout(const Duration(seconds: 2));
      expect(player.attemptedUris, hasLength(2));
      expect(player.playing, isFalse);
      expect(skips, hasLength(1));
    },
  );

  test(
    'a final unavailable entry stops without an empty skip notification',
    () async {
      await handler.addPlaylistToQueue([_song('403')], replace: true);
      expect(player.playing, isFalse);
      expect(player.attemptedUris, hasLength(1));
      expect(skips, isEmpty);
    },
  );

  test(
    'missing local media is skipped using the same queue recovery',
    () async {
      await handler
          .addPlaylistToQueue([
            {..._song('missing'), 'missing': true},
            _song('good'),
          ], replace: true)
          .timeout(const Duration(seconds: 2));
      expect(handler.currentQueueIndex, 1);
      expect(player.playing, isTrue);
    },
  );

  test(
    'skip setting survives closing and reopening the Hive settings box',
    () async {
      await setSkipUnplayableSongs(true);
      await Hive.box('settings').close();
      await Hive.openBox<dynamic>('settings');
      skipUnplayableSongs.value = false;
      reloadSettingsFromStorage();
      expect(skipUnplayableSongs.value, isTrue);
      offlineMode.value = true;
      wrappedEnabled.value = false;
      await setSkipUnplayableSongs(false);
      expect(Hive.box('settings').get('skipUnplayableSongs'), isFalse);
    },
  );
}
