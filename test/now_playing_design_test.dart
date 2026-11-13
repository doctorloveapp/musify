import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/main.dart' as app;
import 'package:musify/models/position_data.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/services/audio_service.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/io_service.dart';
import 'package:musify/services/local_audio_service.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/theme/app_themes.dart';
import 'package:musify/widgets/liquid_glass.dart';
import 'package:musify/widgets/now_playing/player_glass.dart';
import 'package:rxdart/rxdart.dart';

class _PreviewAudioPlayer extends AudioPlayer {
  @override
  Future<void> setAndroidAudioAttributes(
    AndroidAudioAttributes attributes,
  ) async {}
  @override
  Future<void> setLoopMode(LoopMode mode) async {}
  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {}
  @override
  Future<void> stop() async {}
}

class _PreviewHandler extends MusifyAudioHandler {
  _PreviewHandler() : super(player: _PreviewAudioPlayer());

  final positions = BehaviorSubject<PositionData>.seeded(
    PositionData(
      const Duration(minutes: 2, seconds: 14),
      const Duration(minutes: 3),
      const Duration(minutes: 6, seconds: 38),
    ),
  );
  final maps = BehaviorSubject<List<Map>>.seeded([
    {'ytid': 'preview-song', 'title': 'Scene Eight: The Spirit Carries On'},
    {'ytid': 'preview-next', 'title': 'The next song'},
  ]);
  String? command;
  Duration? sought;
  @override
  Stream<PositionData> get positionDataStream => positions.stream;
  @override
  Stream<List<Map>> get queueAsMapStream => maps.stream;
  @override
  bool get hasPrevious => true;
  @override
  bool get hasNext => true;
  @override
  Future<void> play() async {
    command = 'play';
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready, playing: true),
    );
  }

  @override
  Future<void> pause() async {
    command = 'pause';
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready),
    );
  }

  @override
  Future<void> playAgain() async => command = 'replay';
  @override
  Future<void> skipToNext({bool fromPlaybackError = false}) async =>
      command = 'next';
  @override
  Future<void> skipToPrevious() async => command = 'previous';
  @override
  Future<void> seek(Duration position) async => sought = position;
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    shuffleNotifier.value = mode == AudioServiceShuffleMode.all;
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async =>
      repeatNotifier.value = mode;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporaryRoot;
  late _PreviewHandler handler;
  late MediaItem metadata;
  final captureKey = GlobalKey();

  Finder glassButton(String label) => find.byWidgetPredicate(
    (widget) => widget is PlayerGlassButton && widget.tooltip == label,
  );

  setUpAll(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('musify_player_ui_');
    applicationDirPath = temporaryRoot.path;
    Hive.init(temporaryRoot.path);
    for (final name in [
      'user',
      'settings',
      'userNoBackup',
      'localLibrary',
      'cache',
    ]) {
      await Hive.openBox<dynamic>(name);
    }
    await initializeLocalAudioService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_session'),
          (_) async => null,
        );
    wrappedEnabled.value = false;
    offlineMode.value = false;
    showAudioQualityBadge.value = false;
    lastFetchedLyrics = 'Dream Theater - Scene Eight: The Spirit Carries On';
    lyrics.value = 'A cached lyric used for the visual test.';
    handler = _PreviewHandler();
    app.audioHandler = handler;
    final artwork = File('assets/icons/musify_icon.png').absolute;
    metadata = MediaItem(
      id: 'preview-song',
      title: 'Scene Eight: The Spirit Carries On',
      artist: 'Dream Theater',
      duration: const Duration(minutes: 6, seconds: 38),
      artUri: Uri.file(artwork.path),
      extras: {'ytid': 'preview-song', 'artWorkPath': artwork.path},
    );
    handler.queue.add([metadata, metadata.copyWith(id: 'preview-next')]);
    handler.mediaItem.add(metadata);

    // Real fonts make the generated previews useful for visual review.
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final entry in manifest.whereType<Map>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List) {
        loader.addFont(rootBundle.load((font as Map)['asset'] as String));
      }
      await loader.load();
    }
    final sans = File('C:/Windows/Fonts/segoeui.ttf');
    if (await sans.exists()) {
      final bytes = await sans.readAsBytes();
      await (FontLoader(
        'PlayerPreviewSans',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });

  tearDownAll(() async {
    await handler.stop();
    await handler.audioPlayer.dispose();
    await handler.positions.close();
    await handler.maps.close();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await Hive.close();
    await temporaryRoot.delete(recursive: true);
  });

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(393, 852),
    Brightness brightness = Brightness.dark,
    Color accent = const Color(0xFF8E24AA),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repeatNotifier.value = AudioServiceRepeatMode.none;
    shuffleNotifier.value = false;
    handler.mediaItem.add(metadata);
    handler.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready, playing: true),
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    final base = getAppTheme(scheme);
    // Resolve disk I/O outside the widget test's fake clock, before the page
    // creates its FileImage stream. This also makes PNG capture deterministic.
    await tester.runAsync(() async {
      final stream = FileImage(File(metadata.extras!['artWorkPath'] as String))
          .resolve(const ImageConfiguration());
      final ready = Completer<void>();
      final listener = ImageStreamListener(
        (_, __) {
          if (!ready.isCompleted) ready.complete();
        },
        onError: (Object error, StackTrace? stack) {
          if (!ready.isCompleted) ready.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await ready.future;
      } finally {
        stream.removeListener(listener);
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: base.copyWith(
          textTheme: base.textTheme.apply(fontFamily: 'PlayerPreviewSans'),
        ),
        locale: const Locale('it'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: RepaintBoundary(
            key: captureKey,
            child: LiquidGlassBackground(child: child!),
          ),
        ),
        home: const NowPlayingPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    handler.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready, playing: true),
    );
    await tester.pump();
  }

  for (final brightness in Brightness.values) {
    testWidgets('player fits Galaxy S26 in $brightness and renders a preview', (
      tester,
    ) async {
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await mount(tester, brightness: brightness);
        expect(find.text(metadata.title), findsOneWidget);
        expect(find.text('In riproduzione'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);
        for (final button in tester.widgetList<PlayerGlassButton>(
          find.byType(PlayerGlassButton),
        )) {
          expect(button.diameter, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
        await tester.pump();
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'artifacts/player-11.5.4-' + brightness.name + '.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      } finally {
        debugDisableShadows = previousShadows;
      }
    });
  }

  for (final size in [
    const Size(320, 640),
    const Size(760, 400),
    const Size(1100, 800),
  ]) {
    testWidgets('player fits viewport $size without overflow', (tester) async {
      await mount(tester, size: size);
      expect(find.text(metadata.title), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large accessibility text stays reachable by scrolling', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 568), textScale: 1.8);
    await tester.ensureVisible(glassButton('Brani preferiti'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'glass controls still dispatch playback, shuffle, repeat and seek',
    (tester) async {
      await mount(tester);
      await tester.tap(glassButton('Pausa'));
      await tester.pump();
      expect(handler.command, 'pause');
      await tester.tap(glassButton('Riproduci'));
      await tester.pump();
      expect(handler.command, 'play');
      await tester.tap(glassButton('Salta alla successiva'));
      expect(handler.command, 'next');
      await tester.tap(glassButton('Riproduzione casuale'));
      await tester.pump();
      expect(shuffleNotifier.value, isTrue);
      final repeat = glassButton('Ripeti');
      await tester.tap(repeat);
      await tester.pump();
      expect(repeatNotifier.value, AudioServiceRepeatMode.all);
      await tester.drag(find.byType(Slider), const Offset(70, 0));
      await tester.pump();
      expect(handler.sought, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lyrics still flip to the cached text inside the artwork frame', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byType(PlayerArtworkFrame));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(
      find.text('A cached lyric used for the visual test.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio keeps a single primary control without a seek bar', (
    tester,
  ) async {
    await mount(tester);
    handler.mediaItem.add(
      metadata.copyWith(extras: {...metadata.extras!, 'isLive': true}),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final primary = find.byWidgetPredicate(
      (widget) => widget is PlayerGlassButton && widget.primary,
    );
    expect(primary, findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(glassButton('Salta alla successiva'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local tracks keep playlist, queue and favorite actions', (
    tester,
  ) async {
    await mount(tester);
    handler.mediaItem.add(
      metadata.copyWith(
        extras: {
          ...metadata.extras!,
          'ytid': 'local:preview',
          'source': 'local-device',
          'localUri': 'content://musify.test/preview',
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(NowPlayingPage)),
    )!;
    expect(glassButton(l10n.makeOffline), findsNothing);
    expect(glassButton(l10n.addToPlaylist), findsOneWidget);
    expect(glassButton(l10n.queue), findsOneWidget);
    expect(glassButton(l10n.likedSongs), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a theme color change recolors the glass and loading remains disabled',
    (tester) async {
      await mount(tester, accent: const Color(0xFF9B111E));
      final play = tester.element(glassButton('Pausa'));
      final ruby = Theme.of(play).colorScheme.primary;
      await mount(tester, accent: const Color(0xFF003153));
      expect(
        Theme.of(tester.element(glassButton('Pausa'))).colorScheme.primary,
        isNot(ruby),
      );
      handler.playbackState.add(
        PlaybackState(processingState: AudioProcessingState.buffering),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<PlayerGlassButton>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(PlayerGlassButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
