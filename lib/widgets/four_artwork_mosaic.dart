import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/widgets/playlist_artwork.dart';

class FourArtworkMosaic extends StatelessWidget {
  const FourArtworkMosaic({super.key, required this.songs});

  final List<Map> songs;

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
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth / 2;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => PlaylistArtwork(
              playlistArtwork: index < songs.length
                  ? _artwork(songs[index])
                  : null,
              cubeIcon: FluentIcons.music_note_2_24_filled,
              size: size,
            ),
          );
        },
      ),
    );
  }
}
