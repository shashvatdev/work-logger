import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _LogScreenState extends ConsumerState<LogScreen>
    with SingleTickerProviderStateMixin {
  final _uuid = const Uuid();
  List<_EntryEditor>? _editors;
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  DailyLogModel? _existingLog;
  final List<String> _deletedEntryIds = [];

  // For save success animation
  late final AnimationController _savedAnimCtrl;
  late final Animation<double> _savedScale;

  bool get _isEditable => widget.viewUserId == null && widget.date.isToday;

  @override
  void initState() {
    super.initState();
    _savedAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _savedScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _savedAnimCtrl, curve: Curves.elasticOut),
    );
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
          final existing =
              oldEditors?.where((ed) => ed.entry.id == e.id).firstOrNull;
          if (existing != null) {
            newEditors.add(_EntryEditor(
              entry: e,
              tasks: existing.tasks,
              uploading: existing.uploading,
            ));
          } else {
            newEditors.add(_EntryEditor(
              entry: e,
              tasks: _parseTasksFromEntry(e),
            ));
          }
        }
      } else if (widget.viewUserId != null || !widget.date.isToday) {
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
              entry: blankEntry.entry
                  .copyWith(projectId: widget.initialProjectId!),
              tasks: blankEntry.tasks,
              uploading: blankEntry.uploading,
            );
          } else {
            final newEd = _newEditor(user.id, '${user.id}_$dateStr');
            newEditors.add(_EntryEditor(
              entry: newEd.entry
                  .copyWith(projectId: widget.initialProjectId!),
              tasks: newEd.tasks,
            ));
          }
        }
      }

      // Dispose old task editors that are no longer used
      if (oldEditors != null) {
        for (final old in oldEditors) {
          if (!newEditors.any((newEd) => newEd.tasks == old.tasks)) {
            for (final t in old.tasks) {
              t.dispose();
            }
          }
        }
      }

      _editors = newEditors;

      setState(() {
        _loading = false;
      });
    }
  }

  _EntryEditor _newEditor(String userId, String logId, {String defaultProjectId = ''}) {
    return _EntryEditor(
      entry: LogEntryModel(
        id: _uuid.v4(),
        logId: logId,
        projectId: defaultProjectId,
        description: '',
      ),
      tasks: [_TaskItemEditor()],
    );
  }

  void _addEntry() {
    final user = ref.read(currentUserProvider)!;
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    final logId = '${user.id}_$dateStr';

    final myProjects = ref.read(myProjectsProvider).valueOrNull ?? <ProjectModel>[];
    final selectedIds = _editors?.map((e) => e.entry.projectId).where((id) => id.isNotEmpty).toSet() ?? {};

    if (myProjects.isNotEmpty && selectedIds.length >= myProjects.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All your assigned projects have already been added.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final nextAvailable = myProjects.where((p) => !selectedIds.contains(p.id)).firstOrNull;

    setState(() {
      _editors ??= [];
      _editors!.add(_newEditor(user.id, logId, defaultProjectId: nextAvailable?.id ?? ''));
    });
  }


  void _removeEntry(int index) {
    if (_editors == null || _editors!.length == 1) return;
    setState(() {
      final removed = _editors![index];
      if (_existingLog != null &&
          _existingLog!.entries.any((e) => e.id == removed.entry.id)) {
        _deletedEntryIds.add(removed.entry.id);
      }
      for (final t in removed.tasks) {
        t.dispose();
      }
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
      final hasDesc = e.tasks.any((t) => t.descCtrl.text.trim().isNotEmpty);
      if (hasProject && hasDesc) {
        hasValid = true;
      } else if (hasProject || hasDesc) {
        hasInvalid = true;
      }
    }

    if (!hasValid || hasInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please ensure all entries have both a project and task description.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final repo = LogRepository();
    DailyLogModel? savedLog;

    final validEditors = _editors!
        .where((e) =>
            e.entry.projectId.isNotEmpty &&
            e.tasks.any((t) => t.descCtrl.text.trim().isNotEmpty))
        .toList();

    if (_existingLog != null) {
      final entriesData = validEditors.map((e) {
        final desc = _compileTasksDescription(e.tasks);
        final totalTime = _calculateTotalTime(e.tasks, e.entry.timeSpent);
        return <String, dynamic>{
          if (_existingLog!.entries.any((ext) => ext.id == e.entry.id))
            'id': e.entry.id,
          'projectId': e.entry.projectId,
          'description': desc,
          if (totalTime.isNotEmpty) 'timeSpent': totalTime,
        };
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
      final entriesData = validEditors.map((e) {
        final desc = _compileTasksDescription(e.tasks);
        final totalTime = _calculateTotalTime(e.tasks, e.entry.timeSpent);
        return <String, dynamic>{
          'projectId': e.entry.projectId,
          'description': desc,
          if (totalTime.isNotEmpty) 'timeSpent': totalTime,
        };
      }).toList();

      final result = await repo.createLog(entries: entriesData);
      if (result is ApiSuccess) {
        savedLog = result.data;
      }
    }

    if (savedLog != null) {
      _existingLog = savedLog;
      for (int i = 0; i < _editors!.length; i++) {
        final currentEditor = _editors![i];
        final backendEntry = savedLog.entries
            .where((e) => e.projectId == currentEditor.entry.projectId)
            .firstOrNull;

        if (backendEntry != null) {
          _editors![i] = _EntryEditor(
            entry: backendEntry,
            tasks: currentEditor.tasks,
            uploading: currentEditor.uploading,
          );
        }
      }
      ref.invalidate(todayLogProvider);
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = true;
        });
        _savedAnimCtrl.forward(from: 0.0);
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          _savedAnimCtrl.reverse();
          setState(() => _saved = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save log progress.')),
        );
      }
    }
  }

  Future<bool> _autoSave(int targetIndex) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !_isEditable || _editors == null) return false;

    final targetEditor = _editors![targetIndex];
    if (targetEditor.entry.projectId.isEmpty ||
        !targetEditor.tasks.any((t) => t.descCtrl.text.trim().isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please fill in the project and task description before adding an attachment.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }

    setState(() => _saving = true);

    final repo = LogRepository();
    DailyLogModel? savedLog;

    final validEditors = _editors!
        .where((e) =>
            e.entry.projectId.isNotEmpty &&
            e.tasks.any((t) => t.descCtrl.text.trim().isNotEmpty))
        .toList();

    if (_existingLog != null) {
      final entriesData = validEditors.map((e) {
        final desc = _compileTasksDescription(e.tasks);
        final totalTime = _calculateTotalTime(e.tasks, e.entry.timeSpent);
        return <String, dynamic>{
          if (_existingLog!.entries.any((ext) => ext.id == e.entry.id))
            'id': e.entry.id,
          'projectId': e.entry.projectId,
          'description': desc,
          if (totalTime.isNotEmpty) 'timeSpent': totalTime,
        };
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
      final entriesData = validEditors.map((e) {
        final desc = _compileTasksDescription(e.tasks);
        final totalTime = _calculateTotalTime(e.tasks, e.entry.timeSpent);
        return <String, dynamic>{
          'projectId': e.entry.projectId,
          'description': desc,
          if (totalTime.isNotEmpty) 'timeSpent': totalTime,
        };
      }).toList();

      final result = await repo.createLog(entries: entriesData);
      if (result is ApiSuccess) {
        savedLog = result.data;
      }
    }

    if (savedLog != null) {
      _existingLog = savedLog;
      for (int i = 0; i < _editors!.length; i++) {
        final currentEditor = _editors![i];
        final backendEntry = savedLog.entries
            .where((e) => e.projectId == currentEditor.entry.projectId)
            .firstOrNull;

        if (backendEntry != null) {
          _editors![i] = _EntryEditor(
            entry: backendEntry,
            tasks: currentEditor.tasks,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: AppColors.elevated(context),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHandle(
                title: 'Add Attachment',
                subtitle: 'Choose how you want to select a file',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    _AttachmentOptionTile(
                      icon: Icons.photo_camera_rounded,
                      color: AppColors.accent,
                      title: 'Camera',
                      subtitle: 'Take a photo',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickAttachment(index, AttachmentSource.camera);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AttachmentOptionTile(
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF5856D6),
                      title: 'Photo Library',
                      subtitle: 'Select from gallery',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickAttachment(index, AttachmentSource.gallery);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AttachmentOptionTile(
                      icon: Icons.insert_drive_file_rounded,
                      color: AppColors.warning,
                      title: 'Browse Files',
                      subtitle: 'Choose a document or PDF',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickAttachment(index, AttachmentSource.files);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
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
      if (source == AttachmentSource.camera ||
          source == AttachmentSource.gallery) {
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(AttachmentModel attachment) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );

    final repo = AttachmentRepository();
    final result = await repo.getDownloadUrl(attachment.id);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (result is ApiSuccess) {
      final downloadUrl = result.data['downloadUrl'] as String?;
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        String fullUrl = downloadUrl;
        if (!downloadUrl.startsWith('http://') &&
            !downloadUrl.startsWith('https://')) {
          fullUrl = 'https://worktracker.addonshareware.com$downloadUrl';
        }

        final isImage = attachment.type == AttachmentType.image ||
            _isImageFileName(attachment.fileName);

        if (isImage && mounted) {
          _showInAppImagePreview(context, attachment, fullUrl);
        } else {
          final uri = Uri.parse(fullUrl);
          try {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.inAppBrowserView,
            );
            if (!launched) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } else {
      if (mounted) {
        final err = (result as ApiError).exception;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to get download link: ${err.message}')),
        );
      }
    }
  }

  void _showInAppImagePreview(
      BuildContext context, AttachmentModel attachment, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.fileSizeBytes != null)
                  Text(
                    _formatBytes(attachment.fileSizeBytes!),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
                tooltip: 'Open in browser',
                onPressed: () async {
                  final uri = Uri.parse(imageUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.accent,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.broken_image_rounded,
                            color: Colors.white54, size: 64),
                        SizedBox(height: 12),
                        Text('Failed to load image preview',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isImageFileName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
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


  @override
  void dispose() {
    if (_editors != null) {
      for (final e in _editors!) {
        for (final t in e.tasks) {
          t.dispose();
        }
      }
    }
    _savedAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myProjects = ref.watch(myProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditable ? "Today's Log" : widget.date.shortDate,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.separator(context),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 12,
                        color: AppColors.textSecondary(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Read Only',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: AppColors.textSecondary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          if (_saving && !_saved)
            Padding(
              padding:
                  const EdgeInsets.only(right: AppSpacing.md),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildSkeleton()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(
                          bottom: 24,
                          top: AppSpacing.sm,
                          left: AppSpacing.md,
                          right: AppSpacing.md),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (_editors!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: EmptyStateWidget(
                              icon: Icons.event_note_outlined,
                              title: 'No log for this date',
                              subtitle:
                                  'No work entries were submitted for this day.',
                              iconColor: AppColors.textSecondary(context),
                            ),
                          ),
                        for (int i = 0; i < _editors!.length; i++) ...[
                          _EntrySection(
                            key: ValueKey(_editors![i].entry.id),
                            editor: _editors![i],
                            index: i,
                            totalCount: _editors!.length,
                            projects: myProjects.valueOrNull ??
                                <ProjectModel>[],
                            usedProjectIds: _editors!
                                .where((ed) =>
                                    ed.entry.id != _editors![i].entry.id &&
                                    ed.entry.projectId.isNotEmpty)
                                .map((ed) => ed.entry.projectId)
                                .toSet(),
                            isEditable: _isEditable,


                            onRemove: () => _removeEntry(i),
                            onProjectSelected: (projectId) {
                              setState(() {
                                _editors![i] = _EntryEditor(
                                  entry: _editors![i]
                                      .entry
                                      .copyWith(projectId: projectId),
                                  tasks: _editors![i].tasks,
                                  uploading: _editors![i].uploading,
                                );
                              });
                            },
                            onChanged: () => setState(() {}),

                            onAddAttachment: () =>
                                _showAttachmentPicker(i),
                            onDeleteAttachment: (attachmentId) =>
                                _deleteAttachment(i, attachmentId),
                            onTapAttachment: (att) =>
                                _openAttachment(att),
                          ),

                          const SizedBox(height: AppSpacing.md),
                        ],


                        // ── Add Another Project button ──────────────────
                        if (_isEditable)
                          _AddProjectButton(onTap: _addEntry),
                      ],
                    ),
                  ),

                  // ── Save Bar ───────────────────────────────────────────
                  if (_isEditable)
                    Container(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.background(context),
                        border: Border(
                          top: BorderSide(
                              color: AppColors.separator(context),
                              width: 0.5),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(
                                  opacity: anim, child: child),
                          child: _saved
                              ? ScaleTransition(
                                  scale: _savedScale,
                                  child: Container(
                                    key: const ValueKey('saved'),
                                    height: AppSpacing.buttonHeightLg,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.success,
                                          AppColors.success
                                              .withGreen(185),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.success
                                              .withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 22),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Log Saved',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                        ),
                                      ],
                                    ),
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

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                    width: 120, height: 14, borderRadius: 7),
                const SizedBox(height: AppSpacing.sm),
                SkeletonLoader(
                    width: double.infinity, height: 11, borderRadius: 6),
                const SizedBox(height: 6),
                SkeletonLoader(
                    width: 200, height: 11, borderRadius: 6),
                const SizedBox(height: 6),
                SkeletonLoader(
                    width: 160, height: 11, borderRadius: 6),
                const SizedBox(height: AppSpacing.md),
                SkeletonLoader(
                    width: double.infinity, height: 11, borderRadius: 6),
                const SizedBox(height: 6),
                SkeletonLoader(
                    width: 240, height: 11, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TaskItemEditor {
  final String id;
  final TextEditingController descCtrl;
  final TextEditingController timeCtrl;

  _TaskItemEditor({
    String? id,
    String description = '',
    String timeSpent = '',
  })  : id = id ?? const Uuid().v4(),
        descCtrl = TextEditingController(text: description),
        timeCtrl = TextEditingController(text: timeSpent);

  void dispose() {
    descCtrl.dispose();
    timeCtrl.dispose();
  }
}

class _EntryEditor {
  final LogEntryModel entry;
  final List<_TaskItemEditor> tasks;
  bool uploading;

  _EntryEditor({
    required this.entry,
    required this.tasks,
    this.uploading = false,
  });
}

List<_TaskItemEditor> _parseTasksFromEntry(LogEntryModel e) {
  if (e.description.trim().isEmpty) {
    return [_TaskItemEditor(timeSpent: e.timeSpent ?? '')];
  }

  final lines = e.description
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (lines.length > 1 ||
      lines.any((l) => l.startsWith('•') || l.startsWith('-'))) {
    final parsed = <_TaskItemEditor>[];
    for (final line in lines) {
      var clean = line;
      if (clean.startsWith('•')) clean = clean.substring(1).trim();
      if (clean.startsWith('-')) clean = clean.substring(1).trim();

      String desc = clean;
      String time = '';
      final match = RegExp(r'\(([^)]+)\)$').firstMatch(clean);
      if (match != null) {
        time = match.group(1) ?? '';
        desc = clean.substring(0, match.start).trim();
      }
      parsed.add(_TaskItemEditor(description: desc, timeSpent: time));
    }
    if (parsed.isNotEmpty) return parsed;
  }

  return [
    _TaskItemEditor(
      description: e.description,
      timeSpent: e.timeSpent ?? '',
    ),
  ];
}

String _compileTasksDescription(List<_TaskItemEditor> tasks) {
  final valid =
      tasks.where((t) => t.descCtrl.text.trim().isNotEmpty).toList();
  if (valid.isEmpty) return '';
  if (valid.length == 1) {
    final d = valid.first.descCtrl.text.trim();
    final time = valid.first.timeCtrl.text.trim();
    return time.isNotEmpty ? '$d ($time)' : d;
  }
  return valid.map((t) {
    final d = t.descCtrl.text.trim();
    final time = t.timeCtrl.text.trim();
    return time.isNotEmpty ? '• $d ($time)' : '• $d';
  }).join('\n');
}

String _calculateTotalTime(List<_TaskItemEditor> tasks, String? fallbackTime) {
  double totalHours = 0;
  bool foundNumeric = false;

  for (final t in tasks) {
    final raw = t.timeCtrl.text.trim().toLowerCase();
    if (raw.isEmpty) continue;

    if (raw.endsWith('h')) {
      final val = double.tryParse(raw.replaceAll('h', '').trim());
      if (val != null) {
        totalHours += val;
        foundNumeric = true;
      }
    } else if (raw.endsWith('m')) {
      final val = double.tryParse(raw.replaceAll('m', '').trim());
      if (val != null) {
        totalHours += val / 60.0;
        foundNumeric = true;
      }
    } else {
      final val = double.tryParse(raw);
      if (val != null) {
        totalHours += val;
        foundNumeric = true;
      }
    }
  }

  if (foundNumeric && totalHours > 0) {
    if (totalHours == totalHours.roundToDouble()) {
      return '${totalHours.toInt()}h';
    } else {
      return '${totalHours.toStringAsFixed(1)}h';
    }
  }

  final nonNumeric = tasks
      .map((t) => t.timeCtrl.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (nonNumeric.isNotEmpty) {
    return nonNumeric.join(', ');
  }
  return fallbackTime ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
/// Premium entry section card with multiple tasks support
// ─────────────────────────────────────────────────────────────────────────────
class _EntrySection extends StatefulWidget {
  final _EntryEditor editor;
  final int index;
  final int totalCount;
  final List<dynamic> projects;
  final Set<String> usedProjectIds;
  final bool isEditable;
  final VoidCallback onRemove;
  final ValueChanged<String> onProjectSelected;
  final VoidCallback onChanged;
  final VoidCallback onAddAttachment;
  final ValueChanged<String> onDeleteAttachment;
  final ValueChanged<AttachmentModel> onTapAttachment;

  const _EntrySection({
    super.key,
    required this.editor,
    required this.index,
    required this.totalCount,
    required this.projects,
    this.usedProjectIds = const {},
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
    final selectedProject =
        widget.projects.where((p) => p.id == entry.projectId).firstOrNull;
    final projectColor = entry.projectId.isNotEmpty
        ? AppColors.projectColor(entry.projectId)
        : AppColors.accent;

    final calculatedTime = _calculateTotalTime(
        widget.editor.tasks, entry.timeSpent);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent bar ────────────────────────────────────────
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      projectColor,
                      projectColor.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Project selector & Total time header ─────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: widget.isEditable
                                ? _ProjectDropdown(
                                    projects: widget.projects,
                                    selectedId: entry.projectId,
                                    usedProjectIds: widget.usedProjectIds,
                                    onSelected: widget.onProjectSelected,
                                  )
                                : Text(
                                    selectedProject?.name ?? 'Unknown Project',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: projectColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                          ),
                          if (calculatedTime.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: projectColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: projectColor.withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_filled_rounded,
                                      size: 12, color: projectColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    calculatedTime,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: projectColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (widget.isEditable && widget.totalCount > 1)
                            GestureDetector(
                              onTap: widget.onRemove,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.errorSoft,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusXs),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const AppDivider(),

                    // ── Tasks list section ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TASKS LOGGED',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary(context),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      fontSize: 10,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${widget.editor.tasks.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary(context),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // List of task items
                          for (int k = 0; k < widget.editor.tasks.length; k++) ...[
                            _buildTaskItemRow(context, k),
                            if (k < widget.editor.tasks.length - 1)
                              const SizedBox(height: AppSpacing.xs + 2),
                          ],

                          // Add Task Button (when editable)
                          if (widget.isEditable) ...[
                            const SizedBox(height: AppSpacing.sm),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  widget.editor.tasks.add(_TaskItemEditor());
                                });
                                widget.onChanged();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_rounded,
                                        size: 16, color: AppColors.accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Add Task',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Attachments ───────────────────────────────────────
                    const AppDivider(indent: AppSpacing.md),
                    _AttachmentRow(
                      entry: entry,
                      isEditable: widget.isEditable,
                      uploading: widget.editor.uploading,
                      onAdd: widget.onAddAttachment,
                      onDelete: widget.onDeleteAttachment,
                      onTap: widget.onTapAttachment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItemRow(BuildContext context, int taskIndex) {
    final task = widget.editor.tasks[taskIndex];

    if (!widget.isEditable) {
      final desc = task.descCtrl.text.trim();
      final time = task.timeCtrl.text.trim();
      if (desc.isEmpty && time.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 5, color: AppColors.accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                desc,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.separator(context),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Bullet Icon
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 8),

          // Task Description Text Field
          Expanded(
            child: TextField(
              controller: task.descCtrl,
              maxLines: null,
              minLines: 1,
              onChanged: (_) {
                setState(() {});
                widget.onChanged();
              },
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.4),
              decoration: const InputDecoration(
                hintText: 'Task description...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Task Time Picker Button
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: GestureDetector(
              onTap: () => _showTimePickerSheet(context, task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.timeCtrl.text.isNotEmpty
                      ? AppColors.accent.withOpacity(0.12)
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: task.timeCtrl.text.isNotEmpty
                        ? AppColors.accent.withOpacity(0.4)
                        : AppColors.separator(context),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: task.timeCtrl.text.isNotEmpty
                          ? AppColors.accent
                          : AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.timeCtrl.text.isNotEmpty
                          ? task.timeCtrl.text
                          : 'Time...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: task.timeCtrl.text.isNotEmpty
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: task.timeCtrl.text.isNotEmpty
                                ? AppColors.accent
                                : AppColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),


          // Delete Task Item Button
          if (widget.editor.tasks.length > 1) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  task.dispose();
                  widget.editor.tasks.removeAt(taskIndex);
                });
                widget.onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ],
        ],
      ),

    );
  }

  void _showTimePickerSheet(BuildContext context, _TaskItemEditor task) {
    int hrs = 0;
    int mins = 0;

    final raw = task.timeCtrl.text.trim().toLowerCase();
    if (raw.isNotEmpty) {
      final hMatch = RegExp(r'(\d+(?:\.\d+)?)\s*h').firstMatch(raw);
      final mMatch = RegExp(r'(\d+)\s*m').firstMatch(raw);

      if (hMatch != null) {
        final hVal = double.tryParse(hMatch.group(1) ?? '0') ?? 0;
        hrs = hVal.toInt();
        if (hVal % 1 != 0) {
          mins = ((hVal % 1) * 60).round();
        }
      }
      if (mMatch != null) {
        mins = int.tryParse(mMatch.group(1) ?? '0') ?? mins;
      }
      if (hMatch == null && mMatch == null) {
        final val = double.tryParse(raw);
        if (val != null) {
          hrs = val.toInt();
          if (val % 1 != 0) mins = ((val % 1) * 60).round();
        }
      }
    }

    final hrsCtrl =
        TextEditingController(text: hrs > 0 ? hrs.toString() : '');
    final minsCtrl =
        TextEditingController(text: mins > 0 ? mins.toString() : '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updatePreset(int h, int m) {
              hrsCtrl.text = h > 0 ? h.toString() : '';
              minsCtrl.text = m > 0 ? m.toString() : '';
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.elevated(sheetCtx),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SheetHandle(
                          title: 'Select Time Spent',
                          subtitle: 'Enter hours and minutes for this task',
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Numeric Inputs Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hours Box
                            _buildNumberBox(
                              context: sheetCtx,
                              label: 'HOURS',
                              controller: hrsCtrl,
                              hint: '0',
                              onChanged: (_) => setSheetState(() {}),
                              onIncrement: () {
                                final current =
                                    int.tryParse(hrsCtrl.text) ?? 0;
                                hrsCtrl.text = (current + 1).toString();
                                setSheetState(() {});
                              },
                              onDecrement: () {
                                final current =
                                    int.tryParse(hrsCtrl.text) ?? 0;
                                if (current > 0) {
                                  hrsCtrl.text = (current - 1 > 0
                                      ? (current - 1).toString()
                                      : '');
                                  setSheetState(() {});
                                }
                              },
                            ),

                            const Padding(
                              padding: EdgeInsets.only(top: 18, left: 12, right: 12),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),

                            // Minutes Box
                            _buildNumberBox(
                              context: sheetCtx,
                              label: 'MINUTES',
                              controller: minsCtrl,
                              hint: '00',
                              onChanged: (_) => setSheetState(() {}),
                              onIncrement: () {
                                final current =
                                    int.tryParse(minsCtrl.text) ?? 0;
                                final next = (current + 15) % 60;
                                if (current + 15 >= 60) {
                                  final h = int.tryParse(hrsCtrl.text) ?? 0;
                                  hrsCtrl.text = (h + 1).toString();
                                }
                                minsCtrl.text = next > 0 ? next.toString() : '';
                                setSheetState(() {});
                              },
                              onDecrement: () {
                                final current =
                                    int.tryParse(minsCtrl.text) ?? 0;
                                final prev = (current - 15) < 0
                                    ? 45
                                    : (current - 15);
                                minsCtrl.text = prev > 0 ? prev.toString() : '';
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Quick presets chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildPresetChip(
                                  '15m', () => updatePreset(0, 15)),
                              const SizedBox(width: 8),
                              _buildPresetChip(
                                  '30m', () => updatePreset(0, 30)),
                              const SizedBox(width: 8),
                              _buildPresetChip(
                                  '45m', () => updatePreset(0, 45)),
                              const SizedBox(width: 8),
                              _buildPresetChip(
                                  '1h', () => updatePreset(1, 0)),
                              const SizedBox(width: 8),
                              _buildPresetChip(
                                  '1.5h', () => updatePreset(1, 30)),
                              const SizedBox(width: 8),
                              _buildPresetChip(
                                  '2h', () => updatePreset(2, 0)),
                              const SizedBox(width: 8),
                              _buildPresetChip(
                                  '3h', () => updatePreset(3, 0)),
                              const SizedBox(width: 8),
                              _buildPresetChip(
                                  '4h', () => updatePreset(4, 0)),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Action Buttons
                        Row(
                          children: [
                            if (task.timeCtrl.text.isNotEmpty) ...[
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side:
                                        const BorderSide(color: AppColors.error),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    task.timeCtrl.text = '';
                                    setState(() {});
                                    widget.onChanged();
                                    Navigator.pop(sheetCtx);
                                  },
                                  child: const Text('Clear',
                                      style: TextStyle(color: AppColors.error)),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: 2,
                              child: PremiumButton(
                                label: 'Apply Duration',
                                onPressed: () {
                                  final h =
                                      int.tryParse(hrsCtrl.text.trim()) ?? 0;
                                  final m =
                                      int.tryParse(minsCtrl.text.trim()) ?? 0;

                                  String formatted = '';
                                  if (h > 0 && m > 0) {
                                    formatted = '${h}h ${m}m';
                                  } else if (h > 0) {
                                    formatted = '${h}h';
                                  } else if (m > 0) {
                                    formatted = '${m}m';
                                  }

                                  task.timeCtrl.text = formatted;
                                  setState(() {});
                                  widget.onChanged();
                                  Navigator.pop(sheetCtx);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNumberBox({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 95,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onIncrement,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Icon(Icons.keyboard_arrow_up_rounded,
                      color: AppColors.accent, size: 22),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 38,
                child: Center(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: onChanged,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          height: 1.0,
                        ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary(context),
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onDecrement,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.accent, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.25),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AttachmentRow extends StatelessWidget {
  final LogEntryModel entry;
  final bool isEditable;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;
  final ValueChanged<AttachmentModel> onTap;

  const _AttachmentRow({
    required this.entry,
    required this.isEditable,
    required this.uploading,
    required this.onAdd,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accentMid,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: const Icon(Icons.attach_file_rounded,
                color: AppColors.accent, size: 16),
          ),
          title: Text(
            entry.attachments.isEmpty
                ? 'Add Attachment'
                : '${entry.attachments.length} Attachment${entry.attachments.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: isEditable
              ? (uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
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
          onTap: isEditable && !uploading ? onAdd : null,
        ),
        if (entry.attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs,
                AppSpacing.md, AppSpacing.md),
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: entry.attachments.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 14),
                itemBuilder: (context, attachmentIndex) {
                  final att = entry.attachments[attachmentIndex];
                  return _AttachmentItem(
                    attachment: att,
                    isEditable: isEditable,
                    onDelete: () => onDelete(att.id),
                    onTap: onTap,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
class _ProjectDropdown extends StatelessWidget {
  final List<dynamic> projects;
  final String selectedId;
  final Set<String> usedProjectIds;
  final ValueChanged<String> onSelected;

  const _ProjectDropdown({
    required this.projects,
    required this.selectedId,
    this.usedProjectIds = const {},
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        projects.where((p) => p.id == selectedId).firstOrNull;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedId.isNotEmpty) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.projectColor(selectedId),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              selected?.name ?? 'Select Project',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selectedId.isEmpty
                        ? AppColors.textSecondary(context)
                        : AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
              overflow: TextOverflow.ellipsis,
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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.elevated(context),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHandle(title: 'Select Project'),
              for (final p in projects) ...[
                Builder(
                  builder: (context) {
                    final isUsed = usedProjectIds.contains(p.id) && p.id != selectedId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 4),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isUsed
                              ? AppColors.textTertiary(context).withOpacity(0.12)
                              : AppColors.projectColor(p.id).withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: Icon(Icons.folder_rounded,
                            color: isUsed
                                ? AppColors.textTertiary(context)
                                : AppColors.projectColor(p.id),
                            size: 16),
                      ),
                      title: Text(
                        p.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isUsed
                                  ? AppColors.textTertiary(context)
                                  : AppColors.textPrimary(context),
                            ),
                      ),
                      subtitle: isUsed
                          ? Text(
                              'Already selected in another entry',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary(context),
                                    fontSize: 11,
                                  ),
                            )
                          : null,
                      trailing: p.id == selectedId
                          ? Icon(Icons.check_rounded,
                              color: AppColors.accent, size: 20)
                          : null,
                      onTap: isUsed
                          ? null
                          : () {
                              onSelected(p.id);
                              Navigator.pop(context);
                            },
                    );
                  },
                ),
                if (projects.last.id != p.id)
                  const AppDivider(indent: AppSpacing.md + 46),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
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
            'QUICK TAGS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary(context),
                  letterSpacing: 1.0,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _presets
                .map((p) => _PresetChip(label: p, onTap: () => onSelect(p)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
                color: AppColors.separator(context), width: 0.5),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AttachmentItem extends StatelessWidget {
  final AttachmentModel attachment;
  final bool isEditable;
  final VoidCallback onDelete;
  final ValueChanged<AttachmentModel> onTap;

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
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
          iconColor = AppColors.error;
          break;
        case AttachmentType.zip:
          iconData = Icons.archive_rounded;
          iconColor = AppColors.warning;
          break;
        case AttachmentType.apk:
          iconData = Icons.android_rounded;
          iconColor = AppColors.success;
          break;
        case AttachmentType.video:
          iconData = Icons.movie_creation_rounded;
          iconColor = AppColors.accent;
          break;
        default:
          iconData = Icons.insert_drive_file_rounded;
          iconColor = AppColors.textSecondary(context);
      }

      previewWidget = Container(
        width: 160,
        height: 80,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXs),
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
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  if (attachment.fileSizeBytes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatBytes(attachment.fileSizeBytes!),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
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
      onTap: () => onTap(attachment),
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
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF453A),
                      Color(0xFFFF3B30),
                    ]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
class _AttachmentOptionTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachmentOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AttachmentOptionTile> createState() =>
      _AttachmentOptionTileState();
}

class _AttachmentOptionTileState extends State<_AttachmentOptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (c, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: widget.color.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(widget.icon,
                    color: widget.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            )),
                    Text(widget.subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textSecondary(context),
                            )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary(context), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AddProjectButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddProjectButton({required this.onTap});

  @override
  State<_AddProjectButton> createState() => _AddProjectButtonState();
}

class _AddProjectButtonState extends State<_AddProjectButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accentMid,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.accent, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Add Another Project',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AttachmentSource { camera, gallery, files }
