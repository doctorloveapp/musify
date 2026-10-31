import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';

/// Responsive primary actions for song collections.
///
/// On compact screens the optional share action no longer steals horizontal
/// space from the translated Play and Shuffle labels. The shuffle action moves
/// to its own full-width row instead of wrapping text inside a narrow button.
class CollectionPlaybackActions extends StatelessWidget {
  const CollectionPlaybackActions({
    super.key,
    required this.playLabel,
    required this.shuffleLabel,
    required this.onPlay,
    required this.onShuffle,
    this.onShare,
    this.shareTooltip,
    this.onEdit,
    this.editTooltip,
  });

  final String playLabel;
  final String shuffleLabel;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback? onShare;
  final String? shareTooltip;
  final VoidCallback? onEdit;
  final String? editTooltip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWithShare =
            (onShare != null || onEdit != null) && constraints.maxWidth < 520;
        if (compactWithShare) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _playButton()),
                  if (onEdit != null) ...[
                    const SizedBox(width: 12),
                    _editButton(),
                  ],
                  if (onShare != null) ...[
                    const SizedBox(width: 12),
                    _shareButton(),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: _shuffleButton(context)),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _playButton()),
            const SizedBox(width: 12),
            Expanded(child: _shuffleButton(context)),
            if (onEdit != null) ...[const SizedBox(width: 12), _editButton()],
            if (onShare != null) ...[const SizedBox(width: 12), _shareButton()],
          ],
        );
      },
    );
  }

  Widget _playButton() {
    return FilledButton.icon(
      icon: const Icon(FluentIcons.play_24_filled),
      label: _singleLineLabel(playLabel),
      onPressed: onPlay,
    );
  }

  Widget _shuffleButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
      ),
      icon: const Icon(FluentIcons.arrow_shuffle_24_filled),
      label: _singleLineLabel(shuffleLabel),
      onPressed: onShuffle,
    );
  }

  Widget _shareButton() {
    return IconButton.filledTonal(
      icon: const Icon(FluentIcons.share_24_regular),
      tooltip: shareTooltip,
      onPressed: onShare,
    );
  }

  Widget _editButton() => IconButton.filledTonal(
    icon: const Icon(FluentIcons.edit_24_filled),
    tooltip: editTooltip,
    onPressed: onEdit,
  );

  Widget _singleLineLabel(String value) =>
      Text(value, maxLines: 1, softWrap: false, overflow: TextOverflow.fade);
}
