import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/services/lyrics_manager.dart';
import 'package:musify/widgets/now_playing/lyrics_panel.dart';
import 'package:musify/widgets/now_playing/synced_lyrics_view.dart';

Widget app(Widget child, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: brightness,
        ),
      ),
      home: Scaffold(body: SizedBox(height: 420, child: child)),
    );

void main() {
  const lyrics = Lyrics(
    source: 'test',
    synced: [
      LyricLine(Duration(seconds: 1), 'First line'),
      LyricLine(Duration(seconds: 6), 'Second line'),
    ],
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'synced view follows position and explicit seek in $brightness',
      (tester) async {
        final positions = StreamController<PositionData>.broadcast();
        Duration? sought;
        await tester.pumpWidget(
          app(
            SyncedLyricsView(
              lyrics: lyrics,
              positionStream: positions.stream,
              initialPosition: const Duration(seconds: 2),
              onSeek: (target) async {
                sought = target;
              },
            ),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('First line'), findsOneWidget);
        expect(sought, isNull);
        positions.add(
          PositionData(
            const Duration(seconds: 7),
            Duration.zero,
            const Duration(seconds: 100),
          ),
        );
        await tester.pumpAndSettle();
        expect(sought, isNull);
        await tester.tap(find.text('Second line'));
        await tester.pumpAndSettle();
        expect(sought, const Duration(seconds: 6));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await positions.close();
      },
    );
  }

  testWidgets('missing timed lyrics remain readable as static lyrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        LyricsPanel(
          metadata: const MediaItem(id: 'plain', title: 'Song'),
          synchronized: true,
          loader: () async =>
              const Lyrics(source: 'fallback', plain: 'Static text'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Static text'), findsOneWidget);
    expect(find.byType(SyncedLyricsView), findsNothing);
  });

  testWidgets('late result from A cannot replace B and rebuilds do not fetch', (
    tester,
  ) async {
    final first = Completer<Lyrics?>();
    final second = Completer<Lyrics?>();
    var calls = 0;
    Future<Lyrics?> loadA() {
      calls++;
      return first.future;
    }

    Future<Lyrics?> loadB() {
      calls++;
      return second.future;
    }

    Widget panel(String id, Future<Lyrics?> Function() loader) => app(
      LyricsPanel(
        metadata: MediaItem(id: id, title: id),
        synchronized: true,
        loader: loader,
      ),
    );
    await tester.pumpWidget(panel('A', loadA));
    await tester.pumpWidget(panel('A', loadA));
    expect(calls, 1);
    await tester.pumpWidget(panel('B', loadB));
    second.complete(const Lyrics(source: '', plain: 'Current B'));
    await tester.pumpAndSettle();
    first.complete(const Lyrics(source: '', plain: 'Old A'));
    await tester.pumpAndSettle();
    expect(find.text('Current B'), findsOneWidget);
    expect(find.text('Old A'), findsNothing);
    expect(calls, 2);
  });

  testWidgets('loader failure is non-blocking and leaves unavailable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        LyricsPanel(
          metadata: const MediaItem(id: 'error', title: 'Song'),
          synchronized: true,
          loader: () async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
