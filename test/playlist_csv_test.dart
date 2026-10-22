import 'package:flutter_test/flutter_test.dart';
import 'package:musify/utilities/playlist_csv.dart';

void main() {
  group('playlist CSV', () {
    test('round-trips remote and local metadata without changing order', () {
      final csv = createPlaylistCsv({
        'title': 'Test',
        'list': [
          {
            'title': 'Titolo, con "virgolette"',
            'artist': 'Artista\nSeconda riga',
            'ytid': 'abcDEF12345',
            'album': 'Album remoto',
            'duration': 180,
          },
          {
            'title': 'Brano locale',
            'artist': 'Dan King',
            'ytid': 'local:content://media/external/audio/media/42',
            'source': 'local-device',
            'album': 'Archivio',
            'duration': 205,
          },
        ],
      });

      final rows = parsePlaylistCsv(csv);
      expect(rows, hasLength(3));
      expect(rows.first.first.replaceFirst('\ufeff', ''), 'Track Name');
      expect(rows[1], [
        'Titolo, con "virgolette"',
        'Artista\nSeconda riga',
        'abcDEF12345',
        '',
        'Album remoto',
        '180',
      ]);
      expect(rows[2], [
        'Brano locale',
        'Dan King',
        'local:content://media/external/audio/media/42',
        'local-device',
        'Archivio',
        '205',
      ]);
    });

    test('liked songs export is import-compatible at library scale', () {
      final songs = List<Map<String, dynamic>>.generate(
        431,
        (index) => {
          'title': 'Favorite ${index + 1}',
          'artist': 'Artist ${index + 1}',
          'ytid': 'id${index.toString().padLeft(9, '0')}',
          'source': 'youtube',
          'album': 'Album',
          'duration': 180 + index,
        },
      );

      final csv = createPlaylistCsv({
        'title': 'Brani preferiti',
        'list': songs,
      });
      final rows = parsePlaylistCsv(csv);

      expect(rows, hasLength(432));
      expect([
        rows.first.first.replaceFirst('\ufeff', ''),
        ...rows.first.skip(1),
      ], playlistCsvHeaders);
      expect(rows[1][0], 'Favorite 1');
      expect(rows.last[0], 'Favorite 431');
      expect(rows.last[2], 'id000000430');
    });

    test('parses the minimal Spotify-compatible columns', () {
      const csv =
          'Track Name,Artist Name,Track URI\r\n'
          'First song,First artist,spotify:track:123\r\n';

      final rows = parsePlaylistCsv(csv);

      expect(rows, [
        ['Track Name', 'Artist Name', 'Track URI'],
        ['First song', 'First artist', 'spotify:track:123'],
      ]);
    });

    test('creates a safe and recognizable filename', () {
      expect(
        playlistCsvFileName('  Playlist: estate/2026?  '),
        'Musify_Playlist_ estate_2026_.csv',
      );
    });
  });
}
