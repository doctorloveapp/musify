import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:musify/services/data_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Box cache;
  final now = DateTime(2026, 11, 13, 12);

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('musify_cache_1161_');
    Hive.init(root.path);
    cache = await Hive.openBox('cache');
    for (final name in ['user', 'settings', 'userNoBackup', 'localLibrary']) {
      await Hive.openBox(name);
    }
  });
  tearDownAll(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });
  setUp(() async {
    await clearCache();
  });

  test(
    'cleanup removes only >30-day or invalid entries and their date',
    () async {
      await cache.putAll({
        'old': 1,
        'old_date': now.subtract(const Duration(days: 31)),
        'boundary': 2,
        'boundary_date': now.subtract(const Duration(days: 30)),
        'recent': 3,
        'recent_date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'future': 4,
        'future_date': now.add(const Duration(days: 1)),
        'missing': 5,
        'invalid': 6,
        'invalid_date': 'not-a-date',
      });
      await cleanupOldCacheEntries(now: now);
      for (final key in ['old', 'missing', 'invalid']) {
        expect(cache.containsKey(key), isFalse);
        expect(cache.containsKey('${key}_date'), isFalse);
      }
      expect(cache.get('boundary'), 2);
      expect(cache.get('recent'), 3);
      expect(cache.get('future'), 4);
    },
  );

  test('permanent boxes and identity/order are never changed', () async {
    for (final name in ['user', 'settings', 'userNoBackup', 'localLibrary']) {
      await Hive.box(name)
          .put('keep', ['local:42', 'online', 'playlist-order']);
    }
    await cache.put('missing', 'obsolete');
    await cleanupOldCacheEntries(now: now);
    for (final name in ['user', 'settings', 'userNoBackup', 'localLibrary']) {
      expect(Hive.box(name).get('keep'), [
        'local:42',
        'online',
        'playlist-order',
      ]);
    }
  });

  test('cleanup invalidates RAM and data/date atomically', () async {
    await addOrUpdateData('cache', 'ram', 'old');
    expect(await getData('cache', 'ram'), 'old');
    await cleanupOldCacheEntries(
      now: DateTime.now().add(const Duration(days: 31)),
    );
    expect(await getData('cache', 'ram'), isNull);
    expect(cache.containsKey('ram_date'), isFalse);
    await addOrUpdateData('cache', 'ram', 'fresh');
    expect(await getData('cache', 'ram'), 'fresh');
  });

  test(
    'fresh writes survive simultaneous cleanup and retain paired dates',
    () async {
      await cache.putAll({'race': 'old', 'race_date': DateTime(2000)});
      await Future.wait([
        cleanupOldCacheEntries(),
        addOrUpdateData('cache', 'race', 'fresh'),
      ]);
      expect(await getData('cache', 'race'), 'fresh');
      expect(cache.get('race_date'), isA<DateTime>());
      await deleteData('cache', 'race');
      expect(cache.containsKey('race_date'), isFalse);
      expect(await getData('cache', 'race'), isNull);
    },
  );

  test(
    'large cache yields between batches and concurrent cleanup coalesces',
    () async {
      await cache.putAll({for (var n = 0; n < 150; n++) 'item$n': n});
      var yielded = false;
      final cleanup = cleanupOldCacheEntries();
      final concurrent = cleanupOldCacheEntries();
      final tick = Future<void>.delayed(Duration.zero, () => yielded = true);
      await Future.wait([cleanup, concurrent, tick]);
      expect(yielded, isTrue);
      expect(cache.isEmpty, isTrue);
    },
  );

  test('startup maintenance is deferred and scheduled only once', () async {
    final callbacks = <void Function()>[];
    await cache.put('obsolete', 'test');
    scheduleStartupCacheCleanup(afterFirstFrame: callbacks.add);
    scheduleStartupCacheCleanup(afterFirstFrame: callbacks.add);
    expect(callbacks.length, 1);
    expect(cache.containsKey('obsolete'), isTrue);
    callbacks.single();
    await cleanupOldCacheEntries();
    expect(cache.containsKey('obsolete'), isFalse);
  });
}
