import 'package:musify/utilities/song_source.dart';

const playlistCsvHeaders = <String>[
  'Track Name',
  'Artist Name',
  'Track ID',
  'Source',
  'Album',
  'Duration',
];

String createPlaylistCsv(Map playlist) {
  final rows = <List<String>>[
    playlistCsvHeaders,
    for (final song in (playlist['list'] as List? ?? const []).whereType<Map>())
      [
        song['title']?.toString() ?? '',
        song['artist']?.toString() ?? '',
        songIdentity(song) ?? '',
        song['source']?.toString() ?? '',
        song['album']?.toString() ?? '',
        song['duration']?.toString() ?? '',
      ],
  ];
  return '\ufeff${rows.map(_encodeRow).join('\r\n')}\r\n';
}

List<List<String>> parsePlaylistCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;

  for (var index = 0; index < input.length; index++) {
    final character = input[index];
    if (character == '"') {
      if (quoted && index + 1 < input.length && input[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      row.add(field.toString());
      field = StringBuffer();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      if (character == '\r' &&
          index + 1 < input.length &&
          input[index + 1] == '\n') {
        index++;
      }
      row.add(field.toString());
      field = StringBuffer();
      if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(character);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
  }
  return rows;
}

String playlistCsvFileName(String? playlistTitle) {
  final title = playlistTitle?.trim() ?? '';
  final safeTitle = title
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final shortened = safeTitle.length > 80
      ? safeTitle.substring(0, 80).trim()
      : safeTitle;
  return 'Musify_${shortened.isEmpty ? 'Playlist' : shortened}.csv';
}

String _encodeRow(List<String> fields) => fields.map(_encodeCell).join(',');

String _encodeCell(String value) => '"${value.replaceAll('"', '""')}"';
