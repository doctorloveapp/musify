import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/playback_error_recovery.dart';

void main() {
  test(
    'a newer user action cancels recovery while pausing is pending',
    () async {
      final recovery = PlaybackErrorRecovery();
      final pausing = Completer<void>();
      var skipped = false;
      final pending = recovery.handle(
        attempt: 1,
        entryId: 'failed',
        nextEntryId: 'next',
        isEnabled: () => true,
        isCurrent: () => true,
        pause: () => pausing.future,
        skipToNext: () async => skipped = true,
        onSkip: () {},
      );
      recovery.reset();
      pausing.complete();
      await pending;
      expect(skipped, isFalse);
    },
  );

  test(
    'turning the preference off while handling an error prevents a skip',
    () async {
      final recovery = PlaybackErrorRecovery();
      final pausing = Completer<void>();
      var enabled = true;
      var skipped = false;
      final pending = recovery.handle(
        attempt: 1,
        entryId: 'failed',
        nextEntryId: 'next',
        isEnabled: () => enabled,
        isCurrent: () => true,
        pause: () => pausing.future,
        skipToNext: () async => skipped = true,
        onSkip: () {},
      );
      enabled = false;
      pausing.complete();
      await pending;
      expect(skipped, isFalse);
    },
  );
}
