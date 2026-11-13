import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/lyrics_manager.dart';
import 'package:musify/widgets/now_playing/synced_lyrics_view.dart';

/// Mounted only on the back of the artwork. A Future belongs to one track/mode;
/// FutureBuilder ignores late completions after track changes or dismissal.
class LyricsPanel extends StatefulWidget {
  const LyricsPanel({
    super.key,
    required this.metadata,
    required this.synchronized,
    this.loader,
  });
  final MediaItem metadata;
  final bool synchronized;
  final Future<Lyrics?> Function()? loader;

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel> {
  late Future<Lyrics?> _future;
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(LyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadata != widget.metadata ||
        oldWidget.synchronized != widget.synchronized ||
        oldWidget.loader != widget.loader)
      _resolve();
  }

  void _resolve() {
    _future = _load();
  }

  Future<Lyrics?> _load() async {
    if (widget.loader != null) return widget.loader!();
    final m = widget.metadata;
    if (widget.synchronized) {
      return getSongLyricsResult(
        m.artist,
        m.title,
        duration: m.duration,
        album: m.album,
      );
    }
    final text = await getSongLyrics(m.artist, m.title);
    return text == null ? null : Lyrics(source: '', plain: text);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lyrics?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.hasError ? null : snapshot.data;
        if (result == null || result.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n!.lyricsNotAvailable,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (widget.synchronized && result.isSynced)
          return SyncedLyricsView(lyrics: result);
        final credit = result.source.isEmpty ? '' : '\n\n© ${result.source}';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Text(
            '${result.text}$credit',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        );
      },
    );
  }
}
