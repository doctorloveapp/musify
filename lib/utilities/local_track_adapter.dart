import 'dart:io';

import 'package:musify/services/local_audio_data_source.dart';
import 'package:musify/utilities/song_source.dart';

class LocalTrackAdapter {
  const LocalTrackAdapter._();

  static Map<String, dynamic> fromRecord(
    LocalAudioRecord record, {
    String unknownArtist = 'Unknown artist',
  }) {
    final volume = _volumeFromUri(record.uri);
    final identity = 'local:$volume:${record.id}';
    final path = record.data.trim();
    final providedFolder = record.folder?.trim() ?? '';
    final folder = providedFolder.isNotEmpty
        ? providedFolder
        : path.isEmpty
        ? ''
        : File(path).parent.path;
    final title = record.title.trim().isNotEmpty
        ? record.title.trim()
        : _withoutExtension(record.displayName);
    final artist = _cleanTag(record.artist, unknownArtist);

    return <String, dynamic>{
      'id': identity,
      'ytid': identity,
      'source': deviceLocalSource,
      'localUri': record.uri,
      if (path.isNotEmpty) 'audioPath': path,
      'mediaStoreId': record.id,
      'volumeName': volume,
      'title': title,
      'artist': artist,
      if (_validTag(record.album) case final album?) 'album': album,
      if (record.albumId case final albumId?) 'albumId': albumId,
      'duration': ((record.durationMilliseconds ?? 0) / 1000).round(),
      'dateAdded': record.dateAdded,
      'dateModified': record.dateModified,
      'size': record.size,
      'mimeType': record.mimeType ?? _mimeType(record.extension),
      'folder': folder,
      'displayName': record.displayName,
      'isLive': false,
      'missing': false,
      'reconciliationKey': _reconciliationKey(record, volume, folder),
    };
  }

  static String _volumeFromUri(String? value) {
    final uri = Uri.tryParse(value ?? '');
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first.toLowerCase();
    }
    return 'external';
  }

  static String _withoutExtension(String value) =>
      value.replaceFirst(RegExp(r'\.[^.]+$'), '').trim();

  static String? _validTag(String? value) {
    final tag = value?.trim();
    if (tag == null || tag.isEmpty || tag == '<unknown>') return null;
    return tag;
  }

  static String _cleanTag(String? value, String fallback) =>
      _validTag(value) ?? fallback;

  static String _reconciliationKey(
    LocalAudioRecord record,
    String volume,
    String folder,
  ) => [
    volume,
    folder.toLowerCase(),
    record.displayName.toLowerCase(),
    record.size,
    record.durationMilliseconds ?? 0,
    record.dateModified ?? 0,
  ].join('|');

  static String? _mimeType(String? extension) {
    return switch (extension?.toLowerCase().replaceFirst('.', '')) {
      'mp3' => 'audio/mpeg',
      'm4a' || 'mp4' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' || 'opus' => 'audio/ogg',
      'wav' => 'audio/wav',
      'flac' => 'audio/flac',
      _ => null,
    };
  }
}
