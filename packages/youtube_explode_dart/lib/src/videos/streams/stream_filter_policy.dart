import '../../reverse_engineering/models/stream_info_provider.dart';

/// Opt-in compatibility policy. Standard parsing is the default for every client.
/// Adapted from gokadzev/Musify commit 868cd6e723ea (GPL-3.0-or-later).
class StreamFilterPolicy {
  static bool advancedEnabled = false;

  static Iterable<StreamInfoProvider> apply(
    Iterable<StreamInfoProvider> streams,
  ) {
    if (!advancedEnabled) return streams;
    return streams
        .where((s) => !s.isDrmProtected && !s.isOtf && !s.isDrc)
        .toList();
  }
}
