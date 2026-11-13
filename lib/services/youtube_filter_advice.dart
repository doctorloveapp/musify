import 'package:flutter/foundation.dart';

final youtubeFilterAdvice = YouTubeFilterAdvice();

/// Advisory only: never changes settings, queues, retries or proxy policy.
class YouTubeFilterAdvice {
  YouTubeFilterAdvice({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final notices = ValueNotifier<int>(0);
  DateTime? _lastNotice;
  int _count = 0;

  bool report(
    Object error, {
    required bool filtersEnabled,
    bool online = true,
  }) {
    if (filtersEnabled || !online || _count >= 3) return false;
    final message = error.toString().toLowerCase();
    if (!RegExp(
      r'\b403\b|forbidden|no (available |compatible |audio )?streams|unplayable|non riproducibile',
    ).hasMatch(message))
      return false;
    final now = _now();
    if (_lastNotice != null &&
        now.difference(_lastNotice!) < const Duration(minutes: 2))
      return false;
    _lastNotice = now;
    _count++;
    notices.value++;
    return true;
  }
}
