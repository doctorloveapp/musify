import 'dart:typed_data';

class LocalAudioRecord {
  const LocalAudioRecord({
    required this.id,
    required this.title,
    required this.displayName,
    required this.data,
    required this.uri,
    required this.durationMilliseconds,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    this.artist,
    this.album,
    this.albumId,
    this.extension,
    this.mimeType,
    this.folder,
    this.isMusic,
    this.isAlarm,
    this.isNotification,
    this.isRingtone,
  });

  final int id;
  final String title;
  final String displayName;
  final String data;
  final String? uri;
  final int? durationMilliseconds;
  final int size;
  final int? dateAdded;
  final int? dateModified;
  final String? artist;
  final String? album;
  final int? albumId;
  final String? extension;
  final String? mimeType;
  final String? folder;
  final bool? isMusic;
  final bool? isAlarm;
  final bool? isNotification;
  final bool? isRingtone;
}

abstract interface class LocalAudioDataSource {
  Future<int> androidSdkInt();

  Future<List<LocalAudioRecord>> querySongs();

  Future<Uint8List?> queryArtwork(int mediaStoreId, {int size = 512});
}
