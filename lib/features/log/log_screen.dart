import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_extensions.dart';
import '../../data/models/models.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../core/api/api_exception.dart';

class LogScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final String? viewUserId;
  final String? initialProjectId;
  const LogScreen({
    super.key,
    required this.date,
    this.viewUserId,
    this.initialProjectId,
  });

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  final _uuid = const Uuid();
  List<_EntryEditor>? _editors;
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  DailyLogModel? _existingLog;
  final List<String> _deletedEntryIds = [];

  bool get _isEditable => widget.viewUserId == null && widget.date.isToday;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final repo = LogRepository();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    
    final result = widget.viewUserId != null
        ? await repo.getUserLogByDate(widget.viewUserId!, dateStr)
        : (widget.date.isToday
            ? await repo.getTodayLog()
            : await repo.getLogByDate(dateStr));
      
    if (mounted) {
      if (result is ApiSuccess) {
        _existingLog = result.data;
      }
      
      final oldEditors = _editors;
      List<_EntryEditor> newEditors = [];

      if (_existingLog != null && _existingLog!.entries.isNotEmpty) {
        for (final e in _existingLog!.entries) {
          final existing = oldEditors?.where((ed) => ed.entry.id == e.id).firstOrNull;
          if (existing != null) {
            newEditors.add(_EntryEditor(
              entry: e,
              controller: existing.controller,
              uploading: existing.uploading,
            ));
          } else {
            newEditors.add(_EntryEditor(
              entry: e,
              controller: TextEditingController(text: e.description),
            ));
          }
        }
      } else if (widget.viewUserId != null || !widget.date.isToday) {
        // Read-only mode or past date without log: show empty list
        newEditors = [];
      } else {
        newEditors = [_newEditor(user.id, '${user.id}_$dateStr')];
      }

      // Pre-select project if initialProjectId is passed
      if (widget.initialProjectId != null &&
          widget.initialProjectId!.isNotEmpty &&
          widget.viewUserId == null &&
          widget.date.isToday) {
        final match = newEditors
            .where((ed) => ed.entry.projectId == widget.initialProjectId)
            .firstOrNull;
        if (match == null) {
          final blankEntry = newEditors
              .where((ed) => ed.entry.projectId.isEmpty)
              .firstOrNull;
          if (blankEntry != null) {
            final idx = newEditors.indexOf(blankEntry);
            newEditors[idx] = _EntryEditor(
              entry: blankEntry.entry.copyWith(projectId: widget.initialProjectId!),
              controller: blankEntry.controller,
              uploading: blankEntry.uploading,
            );
          } else {
            final newEd = _newEditor(user.id, '${user.id}_$dateStr');
            newEditors.add(_EntryEditor(
              entry: newEd.entry.copyWith(projectId: widget.initialProjectId!),
              controller: newEd.controller,
            ));
          }
        }
      }
      
      // Dispose old controllers that are no longer used
      if (oldEditors != null) {
        for (final old in oldEditors) {
          if (!newEditors.any((newEd) => newEd.controller == old.controller)) {
            old.controller.dispose();
          }
        }
      }

      _editors = newEditors;
      
      setState(() {
        _loading = false;
      });
    }
  }

  _EntryEditor _newEditor(String userId, String logId) {
    return _EntryEditor(
      entry: LogEntryModel(
        id: _uuid.v4(),
        logId: logId,
        projectId: '',
        description: '',
      ),
      controller: TextEditingController(),
    );
  }

  void _addEntry() {
    final user = ref.read(currentUserProvider)!;
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    final logId = '${user.id}_$dateStr';
    setState(() {
      _editors ??= [];
      _editors!.add(_newEditor(user.id, logId));
    });
  }

  void _removeEntry(int index) {
    if (_editors == null || _editors!.length == 1) return;
    setState(() {
      final removed = _editors![index];
      // If it's an existing entry from the backend, mark it for deletion
      if (_existingLog != null && _existingLog!.entries.any((e) => e.id == removed.entry.id)) {
        _deletedEntryIds.add(removed.entry.id);
      }
      removed.controller.dispose();
      _editors!.removeAt(index);
    });
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !_isEditable || _editors == null) return;

    bool hasValid = false;
    bool hasInvalid = false;
    for (final e in _editors!) {
      final hasProject = e.entry.projectId.isNotEmpty;
      final hasDesc = e.controller.text.trim().isNotEmpty;
      if (hasProject && hasDesc) {
        hasValid = true;
      } else if (hasProject || hasDesc) {
        hasInvalid = true;
      }
    }

    if (!hasValid || hasInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please ensure all added entries have both a project and a description.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final repo = LogRepository();
    
    if (_existingLog != null) {
      final entriesData = _editors!.map((e) => <String, dynamic>{
        if (_existingLog!.entries.any((ext) => ext.id == e.entry.id)) 'id': e.entry.id,
        'projectId': e.entry.projectId,
        'description': e.controller.text.trim(),
      }).toList();
      
      await repo.updateLog(
        logId: _existingLog!.id,
        entries: entriesData,
        deletedEntryIds: _deletedEntryIds,
      );
    } else {
      final entriesData = _editors!.map((e) => <String, String>{
        'projectId': e.entry.projectId,
        'description': e.controller.text.trim(),
      }).toList();
      await repo.createLog(entries: entriesData);
    }

    ref.invalidate(todayLogProvider);

    setState(() {
      _saving = false;
      _saved = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _saved = false);
      Navigator.of(context).maybePop();
    }
  }

  Future<bool> _autoSave(int targetIndex) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !_isEditable || _editors == null) return false;

    final targetEditor = _editors![targetIndex];
    if (targetEditor.entry.projectId.isEmpty || targetEditor.controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in the project and description before adding an attachment.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }

    setState(() => _saving = true);

    final repo = LogRepository();
    DailyLogModel? savedLog;

    // Filter to only save valid editors so we don't drop empty ones from state
    final validEditors = _editors!.where((e) => e.entry.projectId.isNotEmpty && e.controller.text.trim().isNotEmpty).toList();

    if (_existingLog != null) {
      final entriesData = validEditors.map((e) => <String, dynamic>{
        if (_existingLog!.entries.any((ext) => ext.id == e.entry.id)) 'id': e.entry.id,
        'projectId': e.entry.projectId,
        'description': e.controller.text.trim(),
      }).toList();

      final result = await repo.updateLog(
        logId: _existingLog!.id,
        entries: entriesData,
        deletedEntryIds: _deletedEntryIds,
      );

      if (result is ApiSuccess) {
        savedLog = result.data;
        _deletedEntryIds.clear();
      }
    } else {
      final entriesData = validEditors.map((e) => <String, String>{
        'projectId': e.entry.projectId,
        'description': e.controller.text.trim(),
      }).toList();

      final result = await repo.createLog(entries: entriesData);
      if (result is ApiSuccess) {
        savedLog = result.data;
      }
    }

    if (savedLog != null) {
      _existingLog = savedLog;
      // We only update the entry objects in _editors to capture new backend IDs/attachments.
      // We do NOT replace the controllers or rebuild the entire list.
      for (int i = 0; i < _editors!.length; i++) {
        final currentEditor = _editors![i];
        final backendEntry = savedLog.entries.where((e) => 
            e.projectId == currentEditor.entry.projectId && 
            e.description == currentEditor.controller.text.trim()
        ).firstOrNull;
        
        if (backendEntry != null) {
          _editors![i] = _EntryEditor(
            entry: backendEntry,
            controller: currentEditor.controller,
            uploading: currentEditor.uploading,
          );
        }
      }
      ref.invalidate(todayLogProvider);
      setState(() => _saving = false);
      return true;
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save log progress.')),
      );
      return false;
    }
  }

  void _showAttachmentPicker(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.separator(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Attachment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how you want to select a file',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_camera_rounded, color: Colors.blue, size: 22),
              ),
              title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Take a photo using your camera'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment(index, AttachmentSource.camera);
              },
            ),
            const AppDivider(indent: 72),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Colors.purple, size: 22),
              ),
              title: const Text('Photo Library', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Select an image from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment(index, AttachmentSource.gallery);
              },
            ),
            const AppDivider(indent: 72),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insert_drive_file_rounded, color: Colors.orange, size: 22),
              ),
              title: const Text('Browse Files', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Choose a document or PDF file'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment(index, AttachmentSource.files);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAttachment(int index, AttachmentSource source) async {
    final saved = await _autoSave(index);
    if (!saved) return;

    final entryId = _editors![index].entry.id;
    if (entryId.isEmpty) return;

    String? filePath;
    String? fileName;

    try {
      if (source == AttachmentSource.camera || source == AttachmentSource.gallery) {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source == AttachmentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 85,
        );
        if (image != null) {
          filePath = image.path;
          fileName = image.name;
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          filePath = result.files.single.path;
          fileName = result.files.single.name;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
      return;
    }

    if (filePath == null || fileName == null) {
      return;
    }

    setState(() {
      _editors![index].uploading = true;
    });

    final repo = AttachmentRepository();
    final uploadResult = await repo.uploadAttachment(
      logEntryId: entryId,
      filePath: filePath,
      fileName: fileName,
    );

    if (mounted) {
      setState(() {
        _editors![index].uploading = false;
      });

      if (uploadResult is ApiSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded "$fileName" successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadLog();
      } else {
        final err = (uploadResult as ApiError).exception;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${err.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deleteAttachment(int index, String attachmentId) async {
    setState(() {
      _editors![index].uploading = true;
    });

    final repo = AttachmentRepository();
    final result = await repo.deleteAttachment(attachmentId);

    if (mounted) {
      setState(() {
        _editors![index].uploading = false;
      });

      if (result is ApiSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attachment deleted.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadLog();
      } else {
        final err = (result as ApiError).exception;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${err.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(String attachmentId) async {
    final repo = AttachmentRepository();
    final result = await repo.getDownloadUrl(attachmentId);
    if (result is ApiSuccess) {
      final downloadUrl = result.data['downloadUrl'] as String?;
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        String fullUrl = downloadUrl;
        if (!downloadUrl.startsWith('http://') && !downloadUrl.startsWith('https://')) {
          fullUrl = 'https://worktracker.addonshareware.com$downloadUrl';
        }
        final uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open attachment url.')),
            );
          }
        }
      }
    } else {
      if (mounted) {
        final err = (result as ApiError).exception;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get download link: ${err.message}')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_editors != null) {
      for (final e in _editors!) {
        e.controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myProjects = ref.watch(myProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditable ? 'Today\'s Log' : widget.date.shortDate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!_isEditable)
              Text(
                'Read only',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 11,
                    ),
              ),
          ],
        ),
        actions: [
          if (!_isEditable)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Read Only',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                    bottom: 24, top: 8, left: AppSpacing.md, right: AppSpacing.md),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_editors!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 48,
                              color: AppColors.textSecondary(context).withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No work log submitted for this date.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (int i = 0; i < _editors!.length; i++) ...[
                    _EntrySection(
                      key: ValueKey(_editors![i].entry.id),
                      editor: _editors![i],
                      index: i,
                      totalCount: _editors!.length,
                      projects: myProjects.valueOrNull ?? <ProjectModel>[],
                      isEditable: _isEditable,
                      onRemove: () => _removeEntry(i),
                      onProjectSelected: (projectId) {
                        setState(() {
                          _editors![i] = _EntryEditor(
                            entry: _editors![i].entry.copyWith(projectId: projectId),
                            controller: _editors![i].controller,
                            uploading: _editors![i].uploading,
                          );
                        });
                      },
                      onChanged: (_) => setState(() {}),
                      onAddAttachment: () => _showAttachmentPicker(i),
                      onDeleteAttachment: (attachmentId) => _deleteAttachment(i, attachmentId),
                      onTapAttachment: (attachmentId) => _openAttachment(attachmentId),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (_isEditable)
                    GestureDetector(
                      onTap: _addEntry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.separator(context),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                color: AppColors.accent, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Add Another Project',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_isEditable)
              Container(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background(context),
                  border: Border(
                    top: BorderSide(
                        color: AppColors.separator(context), width: 0.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _saved
                        ? Container(
                            key: const ValueKey('saved'),
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.logDot,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Saved',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17)),
                              ],
                            ),
                          )
                        : PremiumButton(
                            key: const ValueKey('save'),
                            label: 'Save Log',
                            loading: _saving,
                            onPressed: _save,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntryEditor {
  final LogEntryModel entry;
  final TextEditingController controller;
  bool uploading;
  _EntryEditor({
    required this.entry,
    required this.controller,
    this.uploading = false,
  });
}

class _EntrySection extends StatefulWidget {
  final _EntryEditor editor;
  final int index;
  final int totalCount;
  final List<dynamic> projects;
  final bool isEditable;
  final VoidCallback onRemove;
  final ValueChanged<String> onProjectSelected;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddAttachment;
  final ValueChanged<String> onDeleteAttachment;
  final ValueChanged<String> onTapAttachment;

  const _EntrySection({
    super.key,
    required this.editor,
    required this.index,
    required this.totalCount,
    required this.projects,
    required this.isEditable,
    required this.onRemove,
    required this.onProjectSelected,
    required this.onChanged,
    required this.onAddAttachment,
    required this.onDeleteAttachment,
    required this.onTapAttachment,
  });

  @override
  State<_EntrySection> createState() => _EntrySectionState();
}

class _EntrySectionState extends State<_EntrySection> {

  @override
  Widget build(BuildContext context) {
    final entry = widget.editor.entry;
    final selectedProject = widget.projects
        .where((p) => p.id == entry.projectId)
        .firstOrNull;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Project selector + remove button ───────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: widget.isEditable
                      ? _ProjectDropdown(
                          projects: widget.projects,
                          selectedId: entry.projectId,
                          onSelected: widget.onProjectSelected,
                        )
                      : Text(
                          selectedProject?.name ?? 'Unknown Project',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
                if (widget.isEditable && widget.totalCount > 1)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.remove_circle_outline_rounded,
                        color: AppColors.error, size: 20),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),

          const AppDivider(),

          // ── Text field ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: widget.isEditable
                ? TextField(
                    controller: widget.editor.controller,
                    maxLines: null,
                    minLines: 4,
                    onChanged: widget.onChanged,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                    decoration: InputDecoration(
                      hintText: 'What did you work on?',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    widget.editor.controller.text.isNotEmpty
                        ? widget.editor.controller.text
                        : entry.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
          ),

          // ── Quick presets (edit mode only) ───────────────────────────────
          if (widget.isEditable) ...[
            const AppDivider(indent: AppSpacing.md),
            _QuickPresets(
              onSelect: (preset) {
                final current = widget.editor.controller.text;
                widget.editor.controller.text =
                    current.isEmpty ? preset : '$current\n$preset';
                widget.onChanged(widget.editor.controller.text);
              },
            ),
          ],

          // ── Attachments ───────────────────────────────────────────────────
          const AppDivider(indent: AppSpacing.md),
          ListTile(
            leading: Icon(Icons.attach_file_rounded,
                color: AppColors.accent, size: 20),
            title: Text(
              entry.attachments.isEmpty
                  ? 'Add Attachment'
                  : '${entry.attachments.length} attachment(s)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accent,
                  ),
            ),
            trailing: widget.isEditable
                ? (widget.editor.uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary(context), size: 18))
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 0),
            minLeadingWidth: 0,
            dense: true,
            onTap: widget.isEditable && !widget.editor.uploading
                ? widget.onAddAttachment
                : null,
          ),

          if (entry.attachments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: entry.attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, attachmentIndex) {
                    final att = entry.attachments[attachmentIndex];
                    return _AttachmentItem(
                      attachment: att,
                      isEditable: widget.isEditable,
                      onDelete: () => widget.onDeleteAttachment(att.id),
                      onTap: () => widget.onTapAttachment(att.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectDropdown extends StatelessWidget {
  final List<dynamic> projects;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _ProjectDropdown({
    required this.projects,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = projects.where((p) => p.id == selectedId).firstOrNull;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected?.name ?? 'Select Project',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selectedId.isEmpty
                      ? AppColors.textSecondary(context)
                      : AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.accent,
            size: 18,
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.separator(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Project',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            for (final p in projects) ...[
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                title: Text(p.name,
                    style: Theme.of(context).textTheme.bodyLarge),
                trailing: p.id == selectedId
                    ? Icon(Icons.check_rounded,
                        color: AppColors.accent, size: 20)
                    : null,
                onTap: () {
                  onSelected(p.id);
                  Navigator.pop(context);
                },
              ),
              if (projects.last.id != p.id)
                const AppDivider(indent: 20),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _QuickPresets extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _QuickPresets({required this.onSelect});

  static const _presets = [
    'Bug Fix',
    'Feature Development',
    'Code Review',
    'Meeting',
    'Testing',
    'Documentation',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick tags',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _presets
                .map((p) => GestureDetector(
                      onTap: () => onSelect(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.separator(context),
                              width: 0.5),
                        ),
                        child: Text(
                          p,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontSize: 12,
                                  ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final AttachmentModel attachment;
  final bool isEditable;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _AttachmentItem({
    required this.attachment,
    required this.isEditable,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget previewWidget;
    bool isImage = attachment.type == AttachmentType.image;

    if (isImage && attachment.url != null) {
      previewWidget = Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.separator(context),
            width: 0.5,
          ),
          image: DecorationImage(
            image: NetworkImage(attachment.fullUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      IconData iconData;
      Color iconColor;

      switch (attachment.type) {
        case AttachmentType.pdf:
          iconData = Icons.picture_as_pdf_rounded;
          iconColor = Colors.red;
          break;
        case AttachmentType.zip:
          iconData = Icons.archive_rounded;
          iconColor = Colors.orange;
          break;
        case AttachmentType.apk:
          iconData = Icons.android_rounded;
          iconColor = Colors.green;
          break;
        case AttachmentType.video:
          iconData = Icons.movie_creation_rounded;
          iconColor = Colors.blue;
          break;
        default:
          iconData = Icons.insert_drive_file_rounded;
          iconColor = AppColors.textSecondary(context);
      }

      previewWidget = Container(
        width: 160,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.separator(context),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (attachment.fileSizeBytes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatBytes(attachment.fileSizeBytes!),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary(context),
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          previewWidget,
          if (isEditable)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }
}

enum AttachmentSource { camera, gallery, files }
