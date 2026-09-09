import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/local_audio_permission.dart';
import 'package:musify/services/local_audio_service.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/song_source.dart';
import 'package:musify/widgets/mini_player_bottom_space.dart';

class LocalAudioImportPage extends StatefulWidget {
  const LocalAudioImportPage({super.key});

  @override
  State<LocalAudioImportPage> createState() => _LocalAudioImportPageState();
}

class _LocalAudioImportPageState extends State<LocalAudioImportPage> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};

  List<Map<String, dynamic>> _candidates = const [];
  String _query = '';
  String? _selectedFolder;
  bool _busy = false;
  bool _hasScanned = false;
  bool _lastScanWasFull = false;

  @override
  void dispose() {
    localAudioService.cancelScan();
    _searchController.dispose();
    super.dispose();
  }

  Set<String> get _importedIds => localAudioService.localSongs.value
      .map(songIdentity)
      .whereType<String>()
      .toSet();

  List<Map<String, dynamic>> get _visibleCandidates {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return _candidates;
    return _candidates
        .where((song) {
          return [song['title'], song['artist'], song['album'], song['folder']]
              .whereType<Object>()
              .map((value) => value.toString().toLowerCase())
              .any((value) => value.contains(normalizedQuery));
        })
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>?> _queryMediaStore() async {
    if (_busy) return null;
    setState(() => _busy = true);
    final songs = await localAudioService.scan();
    if (!mounted) return null;
    setState(() => _busy = false);
    return songs;
  }

  Future<void> _scanAll() async {
    final songs = await _queryMediaStore();
    if (songs == null || !mounted) return;
    if (localAudioService.permissionState.value !=
        LocalAudioPermissionState.granted) {
      setState(() => _hasScanned = true);
      return;
    }
    setState(() {
      _candidates = songs;
      _selectedIds.clear();
      _selectedFolder = null;
      _hasScanned = true;
      _lastScanWasFull = true;
    });
  }

  Future<void> _chooseFolder() async {
    final allSongs = await _queryMediaStore();
    if (allSongs == null || !mounted) return;
    if (localAudioService.permissionState.value !=
        LocalAudioPermissionState.granted) {
      setState(() => _hasScanned = true);
      return;
    }

    final availableFolders = localAudioService.folders.value;
    if (availableFolders.isEmpty) {
      setState(() {
        _candidates = const [];
        _selectedIds.clear();
        _selectedFolder = null;
        _hasScanned = true;
        _lastScanWasFull = false;
      });
      return;
    }

    final folder = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  context.l10n!.chooseFolderTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: availableFolders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final path = availableFolders[index];
                    return ListTile(
                      leading: const Icon(FluentIcons.folder_24_regular),
                      title: Text(_folderName(path)),
                      subtitle: Text(
                        path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(context, path),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (folder == null || !mounted) return;

    final normalizedFolder = folder.toLowerCase();
    setState(() {
      _candidates = allSongs
          .where(
            (song) =>
                song['folder']?.toString().toLowerCase() == normalizedFolder,
          )
          .toList(growable: false);
      _selectedIds.clear();
      _selectedFolder = folder;
      _hasScanned = true;
      _lastScanWasFull = false;
    });
  }

  Future<void> _importSelected() async {
    if (_busy || _selectedIds.isEmpty) return;
    final selected = _candidates
        .where((song) => _selectedIds.contains(songIdentity(song)))
        .toList(growable: false);
    if (selected.isEmpty) return;

    setState(() => _busy = true);
    await localAudioService.importTracks(
      selected,
      reconcileFullScan: _lastScanWasFull,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _selectedIds.clear();
    });
    showToast(
      context,
      '${selected.length} ${context.l10n!.localSongsImported}',
    );
  }

  void _selectAllVisible() {
    final imported = _importedIds;
    setState(() {
      _selectedIds.addAll(
        _visibleCandidates
            .map(songIdentity)
            .whereType<String>()
            .where((id) => !imported.contains(id)),
      );
    });
  }

  void _deselectAllVisible() {
    final visibleIds = _visibleCandidates
        .map(songIdentity)
        .whereType<String>()
        .toSet();
    setState(() => _selectedIds.removeAll(visibleIds));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final permission = localAudioService.permissionState.value;
    final visibleCandidates = _visibleCandidates;
    final imported = _importedIds;
    final availableVisibleIds = visibleCandidates
        .map(songIdentity)
        .whereType<String>()
        .where((id) => !imported.contains(id))
        .toSet();
    final allVisibleSelected =
        availableVisibleIds.isNotEmpty &&
        _selectedIds.containsAll(availableVisibleIds);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.localMusic)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n!.localMusicImportHint,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: localAudioService.localSongs,
                    builder: (_, songs, __) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FluentIcons.library_24_regular,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${songs.length} ${context.l10n!.importedLocalSongs}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/settings/local-music/imported'),
                          icon: const Icon(
                            FluentIcons.text_bullet_list_24_regular,
                          ),
                          label: Text(context.l10n!.viewImportedSongs),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : _scanAll,
                        icon: const Icon(FluentIcons.music_note_2_24_regular),
                        label: Text(context.l10n!.scanAllMusic),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _chooseFolder,
                        icon: const Icon(FluentIcons.folder_24_regular),
                        label: Text(context.l10n!.chooseMusicFolder),
                      ),
                    ],
                  ),
                  if (_hasScanned &&
                      permission == LocalAudioPermissionState.granted) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: context.l10n!.searchLocalMusic,
                        prefixIcon: const Icon(FluentIcons.search_24_regular),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(
                                  FluentIcons.dismiss_24_regular,
                                ),
                              ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedFolder == null
                                ? '${_candidates.length} ${context.l10n!.songs}'
                                : '${_folderName(_selectedFolder!)} · ${_candidates.length} ${context.l10n!.songs}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: availableVisibleIds.isEmpty
                              ? null
                              : allVisibleSelected
                              ? _deselectAllVisible
                              : _selectAllVisible,
                          child: Text(
                            allVisibleSelected
                                ? context.l10n!.deselectAll
                                : context.l10n!.selectAll,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _buildResults(
                context,
                permission,
                visibleCandidates,
                imported,
              ),
            ),
            if (_selectedIds.isNotEmpty)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _importSelected,
                    icon: const Icon(FluentIcons.add_circle_24_regular),
                    label: Text(
                      '${context.l10n!.importSelectedSongs} (${_selectedIds.length})',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    LocalAudioPermissionState permission,
    List<Map<String, dynamic>> visibleCandidates,
    Set<String> imported,
  ) {
    if (!_hasScanned) {
      return _CenteredMessage(
        icon: FluentIcons.music_note_2_24_regular,
        message: context.l10n!.localMusicScanPrompt,
      );
    }

    if (permission != LocalAudioPermissionState.granted) {
      final needsSettings =
          permission == LocalAudioPermissionState.permanentlyDenied ||
          permission == LocalAudioPermissionState.restricted;
      return _CenteredMessage(
        icon: FluentIcons.lock_closed_24_regular,
        message: needsSettings
            ? context.l10n!.localMusicPermissionPermanentlyDenied
            : context.l10n!.localMusicPermissionDenied,
        action: FilledButton(
          onPressed: _busy
              ? null
              : needsSettings
              ? localAudioService.openAppSettings
              : _scanAll,
          child: Text(
            needsSettings
                ? context.l10n!.openAppSettings
                : context.l10n!.grantPermission,
          ),
        ),
      );
    }

    if (localAudioService.scanStatus.value == LocalAudioScanStatus.error) {
      return _CenteredMessage(
        icon: FluentIcons.error_circle_24_regular,
        message: context.l10n!.scanFailed,
        details: localAudioService.scanError.value,
      );
    }

    if (visibleCandidates.isEmpty) {
      return _CenteredMessage(
        icon: FluentIcons.music_note_2_24_regular,
        message: context.l10n!.noLocalMusicFound,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
      itemCount: visibleCandidates.length + 1,
      itemBuilder: (context, index) {
        if (index == visibleCandidates.length) {
          return const MiniPlayerBottomSpace();
        }
        final song = visibleCandidates[index];
        final identity = songIdentity(song);
        final isImported = identity != null && imported.contains(identity);
        final isSelected = identity != null && _selectedIds.contains(identity);
        final duration = _durationLabel(song['duration']);
        final folder = _folderName(song['folder']?.toString() ?? '');
        final subtitleParts = <String>[
          song['artist']?.toString() ?? '',
          if (duration.isNotEmpty) duration,
          if (folder.isNotEmpty) folder,
        ].where((part) => part.trim().isNotEmpty).toList();

        return CheckboxListTile(
          value: isImported || isSelected,
          onChanged: isImported || identity == null
              ? null
              : (selected) => setState(() {
                  if (selected ?? false) {
                    _selectedIds.add(identity);
                  } else {
                    _selectedIds.remove(identity);
                  }
                }),
          secondary: Icon(
            isImported
                ? FluentIcons.checkmark_circle_24_filled
                : FluentIcons.music_note_2_24_regular,
          ),
          title: Text(
            song['title']?.toString() ?? song['displayName']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            isImported
                ? '${context.l10n!.alreadyImported} · ${subtitleParts.join(' · ')}'
                : subtitleParts.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          controlAffinity: ListTileControlAffinity.trailing,
        );
      },
    );
  }

  static String _folderName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/').where((part) => part.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }

  static String _durationLabel(dynamic value) {
    final totalSeconds = value is num ? value.round() : int.tryParse('$value');
    if (totalSeconds == null || totalSeconds <= 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.details,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? details;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colorScheme.primary),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            if (details?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
