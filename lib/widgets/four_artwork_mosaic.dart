import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/widgets/playlist_artwork.dart';

class FourArtworkMosaic extends StatelessWidget {
  const FourArtworkMosaic({
    super.key,
    required this.songs,
    this.borderRadius = 16,
  });

  final List<Map> songs;
  final double borderRadius;

  String? _artwork(Map song) {
    for (final key in ['artworkPath', 'highResImage', 'image', 'lowResImage']) {
      final value = song[key]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : width;
          final visible = songs.take(4).toList(growable: false);
          if (visible.length <= 1) {
            return _tile(visible.isEmpty ? null : visible.first, width, height);
          }
          if (visible.length == 2) {
            return Row(
              children: [
                Expanded(child: _tile(visible[0], width / 2, height)),
                Expanded(child: _tile(visible[1], width / 2, height)),
              ],
            );
          }
          if (visible.length == 3) {
            return Row(
              children: [
                Expanded(child: _tile(visible[0], width / 2, height)),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _tile(visible[1], width / 2, height / 2)),
                      Expanded(child: _tile(visible[2], width / 2, height / 2)),
                    ],
                  ),
                ),
              ],
            );
          }
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: 4,
            itemBuilder: (context, index) =>
                _tile(visible[index], width / 2, height / 2),
          );
        },
      ),
    );
  }

  Widget _tile(Map? song, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: PlaylistArtwork(
          playlistArtwork: song == null ? null : _artwork(song),
          cubeIcon: FluentIcons.music_note_2_24_filled,
          size: width > height ? width : height,
        ),
      ),
    );
  }
}
