/// Serializes recovery from a failed queue entry. The same load can report an
/// error through both the platform stream and a failed Future; handle it once.
class PlaybackErrorRecovery {
  int? _handledAttempt;
  final Set<String> _failedEntries = {};
  int _generation = 0;

  void reset() {
    _generation++;
    _handledAttempt = null;
    _failedEntries.clear();
  }

  /// Actual playback progress ends a chain of consecutive failures, without
  /// allowing a duplicate error for the same attempt to trigger another skip.
  void markPlaybackProgress() => _failedEntries.clear();

  Future<void> handle({
    required int attempt,
    required String entryId,
    required String? nextEntryId,
    required bool Function() isEnabled,
    required bool Function() isCurrent,
    required Future<void> Function() pause,
    required Future<void> Function() skipToNext,
    required void Function() onSkip,
  }) async {
    if (!isCurrent() || _handledAttempt == attempt) return;
    _handledAttempt = attempt;
    final generation = _generation;
    _failedEntries.add(entryId);

    await pause();
    if (generation != _generation || !isCurrent() || !isEnabled()) return;

    // Exhausted queues and repeat-all queues containing only broken entries
    // stop safely instead of repeatedly requesting the same unavailable media.
    if (nextEntryId == null || _failedEntries.contains(nextEntryId)) return;

    onSkip();
    await skipToNext();
  }
}
