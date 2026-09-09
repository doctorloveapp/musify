import 'package:flutter/services.dart';
import 'package:musify/services/local_audio_data_source.dart';

class MediaStoreAudioDataSource implements LocalAudioDataSource {
  MediaStoreAudioDataSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.danilo.musify/local_audio';
  final MethodChannel _channel;

  @override
  Future<int> androidSdkInt() async =>
      await _channel.invokeMethod<int>('getSdkInt') ?? 0;

  @override
  Future<List<LocalAudioRecord>> querySongs() async {
    final rawSongs =
        await _channel.invokeListMethod<Object?>('querySongs') ?? const [];

    return rawSongs
        .whereType<Map>()
        .map(
          (raw) => LocalAudioRecord(
            id: _int(raw, 'id'),
            title: _string(raw, 'title'),
            displayName: _string(raw, 'displayName'),
            data: _string(raw, 'data'),
            uri: _nullableString(raw, 'uri'),
            durationMilliseconds: _nullableInt(raw, 'duration'),
            size: _int(raw, 'size'),
            dateAdded: _nullableInt(raw, 'dateAdded'),
            dateModified: _nullableInt(raw, 'dateModified'),
            artist: _nullableString(raw, 'artist'),
            album: _nullableString(raw, 'album'),
            albumId: _nullableInt(raw, 'albumId'),
            extension: _nullableString(raw, 'extension'),
            mimeType: _nullableString(raw, 'mimeType'),
            folder: _nullableString(raw, 'folder'),
            isMusic: _nullableBool(raw, 'isMusic'),
            isAlarm: _nullableBool(raw, 'isAlarm'),
            isNotification: _nullableBool(raw, 'isNotification'),
            isRingtone: _nullableBool(raw, 'isRingtone'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Uint8List?> queryArtwork(int mediaStoreId, {int size = 512}) =>
      _channel.invokeMethod<Uint8List>('queryArtwork', <String, Object>{
        'id': mediaStoreId,
        'size': size,
      });

  static int _int(Map raw, String key) => _nullableInt(raw, key) ?? 0;

  static int? _nullableInt(Map raw, String key) {
    final value = raw[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _string(Map raw, String key) => _nullableString(raw, key) ?? '';

  static String? _nullableString(Map raw, String key) {
    final value = raw[key]?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  static bool? _nullableBool(Map raw, String key) {
    final value = raw[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return switch (value?.toString().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    };
  }
}
