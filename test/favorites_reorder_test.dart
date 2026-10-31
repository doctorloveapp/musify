import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/localization/app_localizations.dart';
import 'package:musify/screens/playlist_reorder_page.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/widgets/edit_playlist_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporaryRoot;
  final first = <String, dynamic>{
    'ytid': 'video-1',
    'title': 'Online',
    'artist': 'A',
  };
  final local = <String, dynamic>{
    'ytid': 'local:42',
    'title': 'Locale',
    'artist': 'B',
    'source': 'local-device',
    'localUri': 'content://media/audio/42',
  };

  setUpAll(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('musify_reorder_');
    Hive.init(temporaryRoot.path);
    await Hive.openBox<dynamic>('user');
  });

  setUp(() async {
    userLikedSongsList.value = [first, local];
    await Hive.box('user').put('likedSongs', [first, local]);
  });

  tearDownAll(() async {
    await Hive.close();
    await temporaryRoot.delete(recursive: true);
  });

  test(
    'favorite ordering persists and preserves local identity and metadata',
    () async {
      var changes = 0;
      void listener() => changes++;
      userLikedSongsList.addListener(listener);
      expect(
        await setLikedSongsOrder([
          {'ytid': 'local:42'},
          {'ytid': 'video-1'},
        ]),
        isTrue,
      );
      expect(changes, 1);
      expect(userLikedSongsList.value, [local, first]);
      await Hive.box('user').close();
      final reopened = await Hive.openBox<dynamic>('user');
      expect(reopened.get('likedSongs'), [local, first]);
      userLikedSongsList.removeListener(listener);
    },
  );

  test('stale, partial or duplicate reorder cannot delete favorites', () async {
    expect(await setLikedSongsOrder([first]), isFalse);
    expect(await setLikedSongsOrder([first, first]), isFalse);
    expect(
      await setLikedSongsOrder([
        first,
        {'ytid': 'unknown'},
      ]),
      isFalse,
    );
    expect(userLikedSongsList.value, [first, local]);
    expect(Hive.box('user').get('likedSongs'), [first, local]);
  });

  Widget localized(Widget child) => MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets('favorites reuse the drag handles and save the reordered list', (
    tester,
  ) async {
    await tester.pumpWidget(localized(const PlaylistReorderPage.favorites()));
    await tester.pumpAndSettle();
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    // The framework already supplies the normalized target index.
    await tester.runAsync(() async {
      list.onReorderItem!(0, 1);
      await Hive.box('user').flush();
    });
    await tester.pumpAndSettle();
    expect(userLikedSongsList.value, [local, first]);
    expect(
      tester.getTopLeft(find.text('Locale')).dy,
      lessThan(tester.getTopLeft(find.text('Online')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('playlist edit menu offers the additional ordering shortcut', (
    tester,
  ) async {
    final playlist = {
      'ytid': 'custom-test',
      'title': 'Test',
      'source': 'user-created',
      'list': [first, local],
    };
    userCustomPlaylists.value = [playlist];
    Map? saved;
    await tester.pumpWidget(
      localized(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Apri modifica'),
              onPressed: () async {
                saved = await showDialog<Map>(
                  context: context,
                  builder: (_) => EditPlaylistDialog(playlistData: playlist),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri modifica'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Nuovo titolo');
    await tester.tap(find.text('Ordina brani'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistReorderPage), findsOneWidget);
    userCustomPlaylists.value = [
      {
        ...playlist,
        'list': [local, first],
      },
    ];
    Navigator.of(tester.element(find.byType(PlaylistReorderPage))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiorna'));
    await tester.pumpAndSettle();
    expect(saved?['title'], 'Nuovo titolo');
    expect(saved?['list'], [local, first]);
    expect(tester.takeException(), isNull);
  });
}
