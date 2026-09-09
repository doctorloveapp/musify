import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/local_audio_data_source.dart';
import 'package:musify/services/local_audio_permission.dart';
import 'package:musify/services/local_audio_service.dart';

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> box;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'musify_permission_gate_',
    );
    Hive.init(hiveDirectory.path);
    box = await Hive.openBox<dynamic>('local_audio_permission_gate');
  });

  setUp(() => box.clear());

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('a denied request never reaches querySongs', () async {
    final dataSource = _FakeDataSource();
    final gateway = _FakePermissionGateway(
      state: LocalAudioPermissionState.denied,
      requestResult: LocalAudioPermissionState.denied,
    );
    final service = LocalAudioService(dataSource, gateway, isAndroid: true);
    await service.initialize(box: box);

    final songs = await service.scan();

    expect(songs, isEmpty);
    expect(gateway.requestCalls, 1);
    expect(dataSource.querySongsCalls, 0);
    expect(service.permissionState.value, LocalAudioPermissionState.denied);
  });

  test(
    'querySongs runs only after request and status both report granted',
    () async {
      final dataSource = _FakeDataSource();
      final gateway = _FakePermissionGateway(
        state: LocalAudioPermissionState.denied,
        requestResult: LocalAudioPermissionState.granted,
        applyRequestResultToStatus: true,
      );
      final service = LocalAudioService(dataSource, gateway, isAndroid: true);
      await service.initialize(box: box);

      await service.scan();

      expect(gateway.requestCalls, 1);
      expect(gateway.isGrantedCalls, greaterThanOrEqualTo(3));
      expect(dataSource.querySongsCalls, 1);
      expect(service.permissionState.value, LocalAudioPermissionState.granted);
    },
  );

  test('an unconfirmed grant never reaches querySongs', () async {
    final dataSource = _FakeDataSource();
    final gateway = _FakePermissionGateway(
      state: LocalAudioPermissionState.denied,
      requestResult: LocalAudioPermissionState.granted,
    );
    final service = LocalAudioService(dataSource, gateway, isAndroid: true);
    await service.initialize(box: box);

    await service.scan();

    expect(gateway.requestCalls, 1);
    expect(dataSource.querySongsCalls, 0);
    expect(service.permissionState.value, LocalAudioPermissionState.denied);
  });

  test('a MediaStore query failure is contained as scan error', () async {
    final dataSource = _FakeDataSource(throwOnQuery: true);
    final gateway = _FakePermissionGateway(
      state: LocalAudioPermissionState.granted,
      requestResult: LocalAudioPermissionState.granted,
    );
    final service = LocalAudioService(dataSource, gateway, isAndroid: true);
    await service.initialize(box: box);

    final songs = await service.scan();

    expect(songs, isEmpty);
    expect(dataSource.querySongsCalls, 1);
    expect(service.scanStatus.value, LocalAudioScanStatus.error);
    expect(service.scanError.value, contains('simulated MediaStore failure'));
  });
}

class _FakeDataSource implements LocalAudioDataSource {
  _FakeDataSource({this.throwOnQuery = false});

  final bool throwOnQuery;
  int querySongsCalls = 0;

  @override
  Future<int> androidSdkInt() async => 36;

  @override
  Future<Uint8List?> queryArtwork(int mediaStoreId, {int size = 512}) async =>
      null;

  @override
  Future<List<LocalAudioRecord>> querySongs() async {
    querySongsCalls++;
    if (throwOnQuery) throw StateError('simulated MediaStore failure');
    return const [];
  }
}

class _FakePermissionGateway implements LocalAudioPermissionGateway {
  _FakePermissionGateway({
    required this.state,
    required this.requestResult,
    this.applyRequestResultToStatus = false,
  });

  LocalAudioPermissionState state;
  final LocalAudioPermissionState requestResult;
  final bool applyRequestResultToStatus;
  int requestCalls = 0;
  int statusCalls = 0;
  int isGrantedCalls = 0;

  @override
  Future<bool> isGranted(int androidSdk) async {
    isGrantedCalls++;
    return state == LocalAudioPermissionState.granted;
  }

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<LocalAudioPermissionState> request(int androidSdk) async {
    requestCalls++;
    if (applyRequestResultToStatus) state = requestResult;
    return requestResult;
  }

  @override
  Future<LocalAudioPermissionState> status(int androidSdk) async {
    statusCalls++;
    return state;
  }
}
