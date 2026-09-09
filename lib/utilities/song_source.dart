enum SongSource { remote, downloaded, deviceLocal, radio }

const String deviceLocalSource = 'local-device';

SongSource songSource(Map? song) {
  if (song == null) return SongSource.remote;
  if (song['source'] == deviceLocalSource) return SongSource.deviceLocal;
  if (song['source'] == 'radio' || song['isRadio'] == true) {
    return SongSource.radio;
  }
  if (song['audioPath']?.toString().trim().isNotEmpty ?? false) {
    return SongSource.downloaded;
  }
  return SongSource.remote;
}

bool isDeviceLocalSong(Map? song) => songSource(song) == SongSource.deviceLocal;

String? songIdentity(Map? song) {
  if (song == null) return null;
  final value = song['ytid'] ?? song['id'];
  final identity = value?.toString().trim();
  return identity == null || identity.isEmpty ? null : identity;
}

bool isLocallyPlayableSong(Map? song) {
  if (song == null || song['missing'] == true) return false;
  if (isDeviceLocalSong(song)) {
    return song['localUri']?.toString().trim().isNotEmpty == true ||
        song['audioPath']?.toString().trim().isNotEmpty == true;
  }
  return song['audioPath']?.toString().trim().isNotEmpty == true;
}
