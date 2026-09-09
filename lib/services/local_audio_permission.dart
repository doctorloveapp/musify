import 'package:permission_handler/permission_handler.dart';

enum LocalAudioPermissionState {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unsupported,
}

abstract interface class LocalAudioPermissionGateway {
  /// A strict check used at the MediaStore call boundary.
  Future<bool> isGranted(int androidSdk);

  Future<LocalAudioPermissionState> status(int androidSdk);

  Future<LocalAudioPermissionState> request(int androidSdk);

  Future<bool> openSettings();
}

class PermissionHandlerLocalAudioGateway
    implements LocalAudioPermissionGateway {
  Permission _permission(int androidSdk) =>
      androidSdk >= 33 ? Permission.audio : Permission.storage;

  @override
  Future<bool> isGranted(int androidSdk) async =>
      (await _permission(androidSdk).status).isGranted;

  @override
  Future<LocalAudioPermissionState> status(int androidSdk) async =>
      _map(await _permission(androidSdk).status);

  @override
  Future<LocalAudioPermissionState> request(int androidSdk) async =>
      _map(await _permission(androidSdk).request());

  @override
  Future<bool> openSettings() => openAppSettings();

  LocalAudioPermissionState _map(PermissionStatus status) {
    // MediaStore audio access is binary on Android. A limited status must not
    // be promoted to granted, otherwise the audio query plugin can be invoked
    // before READ_MEDIA_AUDIO is actually available.
    if (status.isGranted) {
      return LocalAudioPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return LocalAudioPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) return LocalAudioPermissionState.restricted;
    return LocalAudioPermissionState.denied;
  }
}
