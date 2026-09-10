import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/local_audio_permission.dart';
import 'package:musify/services/local_audio_service.dart';
import 'package:musify/utilities/song_source.dart';

List<Map<String, dynamic>> filterLocalAudioCandidates(
  Iterable<Map<String, dynamic>> candidates,
  String rawQuery,
) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return candidates.toList(growable: false);
  return candidates
      .where((song) {
        final searchable = [
          song['title'],
          song['displayName'],
          song['artist'],
          song['album'],
          song['folder'],
          song['data'],
        ].whereType<Object>().map((value) => value.toString().toLowerCase());
        return searchable.any((value) => value.contains(query));
      })
      .toList(growable: false);
}

class LocalAudioScanPage extends StatefulWidget {
  const LocalAudioScanPage({super.key, required this.folderOnly});

  final bool folderOnly;

  @override
  State<LocalAudioScanPage> createState() => _LocalAudioScanPageState();
}

class _LocalAudioScanPageState extends State<LocalAudioScanPage> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};
  List<Map<String, dynamic>> _candidates = const [];
  String _query = '';
  String? _selectedFolder;
  bool _busy = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

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
    return filterLocalAudioCandidates(_candidates, _query);
  }

  Future<void> _startScan() async {
    if (widget.folderOnly) {
      await _scanFolder();
    } else {
      await _scanAll();
    }
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
    setState(() {
      _candidates = songs;
      _selectedIds.clear();
      _selectedFolder = null;
      _hasScanned = true;
    });
  }

  Future<void> _scanFolder() async {
    final songs = await _queryMediaStore();
    if (songs == null || !mounted) return;
    if (localAudioService.permissionState.value !=
        LocalAudioPermissionState.granted) {
      setState(() => _hasScanned = true);
      return;
    }

    final folders = localAudioService.folders.value;
    if (folders.isEmpty) {
      setState(() {
        _candidates = const [];
        _selectedIds.clear();
        _hasScanned = true;
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
                  itemCount: folders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final path = folders[index];
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
    if (!mounted) return;
    if (folder == null) {
      Navigator.pop(context);
      return;
    }

    final normalizedFolder = folder.toLowerCase();
    setState(() {
      _selectedFolder = folder;
      _candidates = songs
          .where(
            (song) =>
                song['folder']?.toString().toLowerCase() == normalizedFolder,
          )
          .toList(growable: false);
      _selectedIds.clear();
      _hasScanned = true;
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
      reconcileFullScan: !widget.folderOnly,
    );
    if (!mounted) return;
    Navigator.pop(context, selected.length);
  }

  void _toggleAllVisible(bool select) {
    final imported = _importedIds;
    final available = _visibleCandidates
        .map(songIdentity)
        .whereType<String>()
        .where((id) => !imported.contains(id));
    setState(() {
      if (select) {
        _selectedIds.addAll(available);
      } else {
        _selectedIds.removeAll(available);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final permission = localAudioService.permissionState.value;
    final visible = _visibleCandidates;
    final imported = _importedIds;
    final selectableIds = visible
        .map(songIdentity)
        .whereType<String>()
        .where((id) => !imported.contains(id))
        .toSet();
    final allSelected =
        selectableIds.isNotEmpty && _selectedIds.containsAll(selectableIds);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.localMusic)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            if (_hasScanned && permission == LocalAudioPermissionState.granted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedFolder == null
                                ? '${_candidates.length} ${context.l10n!.songs}'
                                : '${_folderName(_selectedFolder!)} · ${_candidates.length} ${context.l10n!.songs}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: selectableIds.isEmpty
                              ? null
                              : () => _toggleAllVisible(!allSelected),
                          child: Text(
                            allSelected
                                ? context.l10n!.deselectAll
                                : context.l10n!.selectAll,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildResults(permission, visible, imported)),
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
    LocalAudioPermissionState permission,
    List<Map<String, dynamic>> visible,
    Set<String> imported,
  ) {
    if (!_hasScanned) {
      return _CenteredMessage(
        icon: FluentIcons.music_note_2_24_regular,
        message: context.l10n!.localMusicScanPrompt,
      );
    }
    if (permission != LocalAudioPermissionState.granted) {
      final settingsRequired =
          permission == LocalAudioPermissionState.permanentlyDenied ||
          permission == LocalAudioPermissionState.restricted;
      return _CenteredMessage(
        icon: FluentIcons.lock_closed_24_regular,
        message: settingsRequired
            ? context.l10n!.localMusicPermissionPermanentlyDenied
            : context.l10n!.localMusicPermissionDenied,
        action: FilledButton(
          onPressed: _busy
              ? null
              : settingsRequired
              ? localAudioService.openAppSettings
              : _startScan,
          child: Text(
            settingsRequired
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
    if (visible.isEmpty) {
      return _CenteredMessage(
        icon: FluentIcons.music_note_2_24_regular,
        message: context.l10n!.noLocalMusicFound,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final song = visible[index];
        final identity = songIdentity(song);
        final isImported = identity != null && imported.contains(identity);
        final selected = identity != null && _selectedIds.contains(identity);
        final duration = _durationLabel(song['duration']);
        final folder = _folderName(song['folder']?.toString() ?? '');
        final details = <String>[
          song['artist']?.toString() ?? '',
          if (duration.isNotEmpty) duration,
          if (folder.isNotEmpty) folder,
        ].where((part) => part.trim().isNotEmpty).join(' · ');
        return CheckboxListTile(
          value: isImported || selected,
          onChanged: isImported || identity == null
              ? null
              : (value) => setState(() {
                  if (value ?? false) {
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
                ? '${context.l10n!.alreadyImported} · $details'
                : details,
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
        padding: const EdgeInsets.all(32),
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
