import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/playlists_manager.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('musify_last_list_');
    Hive.init(hiveDirectory.path);
    await Hive.openBox<dynamic>('user');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'only an existing personal playlist replaces the remembered context',
    () async {
      final personal = <String, dynamic>{
        'ytid': 'personal-1',
        'title': 'La mia playlist',
        'source': 'user-created',
        'list': <dynamic>[],
      };
      userCustomPlaylists.value = [personal];
      userPlaylistFolders.value = const [];
      lastPlayedCustomPlaylistId.value = null;

      rememberLastPlayedCustomPlaylist(personal);
      await Future<void>.delayed(Duration.zero);
      await Hive.box<dynamic>('user').flush();

      expect(lastPlayedCustomPlaylistId.value, 'personal-1');
      expect(
        Hive.box<dynamic>('user').get('lastPlayedCustomPlaylistId'),
        'personal-1',
      );

      rememberLastPlayedCustomPlaylist({
        'ytid': 'single-track',
        'title': 'Brano singolo',
      });
      rememberLastPlayedCustomPlaylist({
        'ytid': 'remote-playlist',
        'source': 'youtube',
        'list': <dynamic>[],
      });
      rememberLastPlayedCustomPlaylist({
        'ytid': 'deleted-personal-playlist',
        'source': 'user-created',
        'list': <dynamic>[],
      });

      expect(lastPlayedCustomPlaylistId.value, 'personal-1');
    },
  );

  test(
    'root playlist order is persisted without changing playlist data',
    () async {
      final first = <String, dynamic>{
        'ytid': 'personal-1',
        'title': 'Prima',
        'source': 'user-created',
        'list': <dynamic>[],
      };
      final second = <String, dynamic>{
        'ytid': 'personal-2',
        'title': 'Seconda',
        'source': 'user-created',
        'list': <dynamic>[],
      };
      userCustomPlaylists.value = [first, second];
      await Hive.box<dynamic>('user').put('customPlaylists', [first, second]);

      expect(await setRootCustomPlaylistOrder([second, first]), isTrue);
      expect(userCustomPlaylists.value.map((playlist) => playlist['ytid']), [
        'personal-2',
        'personal-1',
      ]);
      final persisted = List<Map>.from(
        Hive.box<dynamic>('user').get('customPlaylists') as List,
      );
      expect(persisted.map((playlist) => playlist['ytid']), [
        'personal-2',
        'personal-1',
      ]);

      expect(await setRootCustomPlaylistOrder([first]), isFalse);
    },
  );
}
