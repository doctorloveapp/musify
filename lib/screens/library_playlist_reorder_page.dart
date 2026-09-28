import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/utilities/artwork_provider.dart';
import 'package:musify/utilities/playlist_cover.dart';
import 'package:musify/widgets/four_artwork_mosaic.dart';

class LibraryPlaylistReorderPage extends StatefulWidget {
  const LibraryPlaylistReorderPage({super.key});

  @override
  State<LibraryPlaylistReorderPage> createState() =>
      _LibraryPlaylistReorderPageState();
}

class _LibraryPlaylistReorderPageState
    extends State<LibraryPlaylistReorderPage> {
  late List<Map> _playlists;

  @override
  void initState() {
    super.initState();
    _playlists = List<Map>.from(userCustomPlaylists.value);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final previous = List<Map>.from(_playlists);
    setState(() {
      final playlist = _playlists.removeAt(oldIndex);
      _playlists.insert(newIndex.clamp(0, _playlists.length), playlist);
    });

    final saved = await setRootCustomPlaylistOrder(_playlists);
    if (!saved && mounted) setState(() => _playlists = previous);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.orderPlaylists)),
      body: _playlists.length < 2
          ? Center(child: Text(context.l10n!.noPlaylistsToOrder))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              itemCount: _playlists.length,
              onReorderItem: _reorder,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                final id = playlist['ytid']?.toString() ?? 'playlist-$index';
                return Card(
                  key: ValueKey(id),
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: _PlaylistThumbnail(playlist: playlist),
                    title: Text(
                      playlist['title']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${(playlist['list'] as List? ?? const []).length} ${context.l10n!.songs.toLowerCase()}',
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
}

class _PlaylistThumbnail extends StatelessWidget {
  const _PlaylistThumbnail({required this.playlist});

  final Map playlist;

  @override
  Widget build(BuildContext context) {
    final generated = generatedPlaylistCoverSongs(playlist);
    if (generated.isNotEmpty) {
      return SizedBox.square(
        dimension: 46,
        child: FourArtworkMosaic(songs: generated, borderRadius: 8),
      );
    }

    final image = playlist['image']?.toString().trim();
    if (image == null || image.isEmpty) {
      return const SizedBox.square(
        dimension: 46,
        child: Icon(FluentIcons.text_bullet_list_24_regular),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image(
        image: ArtworkProvider.get(image),
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.square(
          dimension: 46,
          child: Icon(FluentIcons.text_bullet_list_24_regular),
        ),
      ),
    );
  }
}
