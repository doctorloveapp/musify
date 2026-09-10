import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/utilities/playlist_cover.dart';
import 'package:musify/utilities/playlist_image_picker.dart';

class EditPlaylistDialog extends StatefulWidget {
  const EditPlaylistDialog({super.key, required this.playlistData});

  final Map playlistData;

  @override
  State<EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends State<EditPlaylistDialog> {
  late TextEditingController _titleController;
  late TextEditingController _imageUrlController;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.playlistData['title'],
    );
    final image = widget.playlistData['image'] as String?;
    if (image != null && image.startsWith('data:')) {
      _imageBase64 = image;
      _imageUrlController = TextEditingController(text: '');
    } else {
      _imageBase64 = null;
      _imageUrlController = TextEditingController(text: image);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        _imageBase64 = result;
        _imageUrlController.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget _imagePreview() {
      return buildImagePreview(
        imageBase64: _imageBase64,
        imageUrl: _imageUrlController.text.isEmpty
            ? null
            : _imageUrlController.text,
      );
    }

    return AlertDialog(
      title: Text(
        context.l10n!.editPlaylist,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.l10n!.customPlaylistName,
                prefixIcon: Icon(
                  FluentIcons.text_field_20_regular,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
              ),
            ),
            if (_imageBase64 == null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: context.l10n!.customPlaylistImgUrl,
                  prefixIcon: Icon(
                    FluentIcons.image_20_regular,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                ),
                onChanged: (_) => setState(() => _imageBase64 = null),
              ),
            ],
            const SizedBox(height: 12),
            if (_imageUrlController.text.isEmpty || _imageBase64 != null) ...[
              buildImagePickerRow(context, _pickImage, _imageBase64 != null),
              _imagePreview(),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n!.cancel,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            final newPlaylist = {
              ...widget.playlistData,
              'title': _titleController.text,
            };
            final selectedImage =
                _imageBase64 ??
                (_imageUrlController.text.trim().isEmpty
                    ? null
                    : _imageUrlController.text.trim());
            if (selectedImage == null) {
              newPlaylist.remove('image');
              ensureGeneratedPlaylistCover(newPlaylist);
            } else {
              newPlaylist['image'] = selectedImage;
              newPlaylist.remove(generatedPlaylistCoverIdsKey);
            }

            Navigator.pop(context, newPlaylist);
          },
          icon: const Icon(FluentIcons.save_20_regular),
          label: Text(context.l10n!.update),
        ),
      ],
    );
  }
}
