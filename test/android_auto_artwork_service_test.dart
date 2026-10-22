import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/android_auto_artwork_service.dart';

void main() {
  late Directory temporaryRoot;
  late AndroidAutoArtworkService service;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('musify_auto_art_');
    service = AndroidAutoArtworkService(
      rootPath: temporaryRoot.path,
      authority: 'com.danilo.musify.test.androidauto.artwork',
    );
  });

  tearDown(() async {
    await temporaryRoot.delete(recursive: true);
  });

  test('registers an HTTPS artwork as an opaque local content URI', () async {
    const source = 'https://i.ytimg.com/vi/example/maxresdefault.jpg';
    final uri = await service.prepareSingle(source);

    expect(uri?.scheme, 'content');
    expect(uri?.authority, 'com.danilo.musify.test.androidauto.artwork');
    expect(uri?.pathSegments.first, 'art');

    final key = uri!.pathSegments.last;
    final spec = File(
      '${temporaryRoot.path}${Platform.pathSeparator}'
      'android_auto_artwork${Platform.pathSeparator}$key.json',
    );
    final json = jsonDecode(await spec.readAsString()) as Map<String, dynamic>;
    expect(json, {'kind': 'single', 'source': source});
  });

  test('materializes data artwork without placing it in the URI', () async {
    final source = 'data:image/png;base64,${base64Encode([1, 2, 3, 4])}';
    final uri = await service.prepareSingle(source);
    final key = uri!.pathSegments.last;
    final directory = Directory(
      '${temporaryRoot.path}${Platform.pathSeparator}android_auto_artwork',
    );

    expect(await File('${directory.path}/$key.original').readAsBytes(), [
      1,
      2,
      3,
      4,
    ]);
    final spec = jsonDecode(
      await File('${directory.path}/$key.json').readAsString(),
    ) as Map<String, dynamic>;
    expect(spec['source'], 'cached:');
    expect(uri.toString(), isNot(contains('base64')));
  });

  test('mosaic keeps unique sources and reduces three covers to two', () async {
    final uri = await service.prepareMosaic(const [
      'https://i.ytimg.com/vi/one/default.jpg',
      'https://i.ytimg.com/vi/two/default.jpg',
      'https://i.ytimg.com/vi/two/default.jpg',
      'https://i.ytimg.com/vi/three/default.jpg',
    ]);
    final key = uri!.pathSegments.last;
    final spec = jsonDecode(
      await File(
        '${temporaryRoot.path}${Platform.pathSeparator}'
        'android_auto_artwork${Platform.pathSeparator}$key.json',
      ).readAsString(),
    ) as Map<String, dynamic>;

    expect(spec['kind'], 'mosaic');
    expect(spec['keys'], isA<List>());
    expect((spec['keys'] as List).length, 2);
  });

  test('rejects insecure or unsupported artwork sources', () async {
    expect(await service.prepareSingle('http://example.com/cover.jpg'), isNull);
    expect(
      await service.prepareSingle('data:text/plain;base64,SGVsbG8='),
      isNull,
    );
    expect(await service.prepareSingle('javascript:alert(1)'), isNull);
  });
}
