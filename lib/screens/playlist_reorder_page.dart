import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/utilities/artwork_provider.dart';
import 'package:musify/utilities/song_source.dart';

class PlaylistReorderPage extends StatefulWidget {
  const PlaylistReorderPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<PlaylistReorderPage> createState() => _PlaylistReorderPageState();
}

class _PlaylistReorderPageState extends State<PlaylistReorderPage> {
  late List<Map> _songs;

  @override
  void initState() {
    super.initState();
    _songs = _readSongs();
  }

  List<Map> _readSongs() => List<Map>.from(
    getCustomPlaylistById(widget.playlistId)?['list'] as List? ?? const [],
  );

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final previous = List<Map>.from(_songs);
    setState(() {
      final song = _songs.removeAt(oldIndex);
      final target = newIndex.clamp(0, _songs.length);
      _songs.insert(target, song);
    });

    final saved = await setCustomPlaylistSongOrder(widget.playlistId, _songs);
    if (!saved && mounted) setState(() => _songs = previous);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.orderSongs)),
      body: _songs.isEmpty
          ? Center(child: Text(context.l10n!.noSongsInPlaylist))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              itemCount: _songs.length,
              onReorderItem: _reorder,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final identity = songIdentity(song) ?? 'song-$index';
                final artwork = _artwork(song);
                return Card(
                  key: ValueKey(identity),
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: artwork == null
                          ? const SizedBox.square(
                              dimension: 46,
                              child: Icon(FluentIcons.music_note_2_24_regular),
                            )
                          : Image(
                              image: ArtworkProvider.get(artwork),
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.square(
                                    dimension: 46,
                                    child: Icon(
                                      FluentIcons.music_note_2_24_regular,
                                    ),
                                  ),
                            ),
                    ),
                    title: Text(
                      song['title']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song['artist']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(FluentIcons.re_order_24_regular),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String? _artwork(Map song) {
    for (final key in ['artworkPath', 'highResImage', 'image', 'lowResImage']) {
      final value = song[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
