import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/local_audio_service.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';

class LocalAudioImportPage extends StatelessWidget {
  const LocalAudioImportPage({super.key});

  Future<void> _openScan(BuildContext context, String mode) async {
    final imported = await context.push<int>('/local-music-scan/$mode');
    if (context.mounted && imported != null && imported > 0) {
      showToast(context, '$imported ${context.l10n!.localSongsImported}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.localMusic)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            context.l10n!.localMusicImportHint,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: localAudioService.localSongs,
            builder: (_, songs, __) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.library_24_regular,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${songs.length} ${context.l10n!.importedLocalSongs}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/settings/local-music/imported'),
                      icon: const Icon(FluentIcons.text_bullet_list_24_regular),
                      label: Text(context.l10n!.viewImportedSongs),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _openScan(context, 'all'),
            icon: const Icon(FluentIcons.music_note_2_24_regular),
            label: Text(context.l10n!.scanAllMusic),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openScan(context, 'folder'),
            icon: const Icon(FluentIcons.folder_24_regular),
            label: Text(context.l10n!.chooseMusicFolder),
          ),
          const MiniPlayerBottomSpace(),
        ],
      ),
    );
  }
}
