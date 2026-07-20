import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_extensions.dart';
import '../../data/models/models.dart';

class LogScreen extends ConsumerStatefulWidget {
  final DateTime date;
  const LogScreen({super.key, required this.date});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  final _uuid = const Uuid();
  late List<_EntryEditor> _editors;
  bool _saving = false;
  bool _saved = false;

  bool get _isEditable => widget.date.isToday;

  @override
  void initState() {
    super.initState();
    _initEditors();
  }

  void _initEditors() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    final logId = '${user.id}_$dateStr';
    final existingLog = ref.read(allLogsProvider)[logId];

    if (existingLog != null && existingLog.entries.isNotEmpty) {
      _editors = existingLog.entries
          .map((e) => _EntryEditor(
                entry: e,
                controller: TextEditingController(text: e.description),
              ))
          .toList();
    } else {
      _editors = [_newEditor(user.id, logId)];
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
      _editors.add(_newEditor(user.id, logId));
    });
  }

  void _removeEntry(int index) {
    if (_editors.length == 1) return;
    setState(() {
      _editors[index].controller.dispose();
      _editors.removeAt(index);
    });
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !_isEditable) return;

    final valid = _editors.where((e) =>
        e.entry.projectId.isNotEmpty &&
        e.controller.text.trim().isNotEmpty);
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a project and add a description.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    final logId = '${user.id}_$dateStr';
    final entries = _editors
        .where((e) =>
            e.entry.projectId.isNotEmpty &&
            e.controller.text.trim().isNotEmpty)
        .map((e) => e.entry.copyWith(description: e.controller.text.trim()))
        .toList();

    final log = DailyLogModel(
      id: logId,
      userId: user.id,
      date: dateStr,
      entries: entries,
      updatedAt: DateTime.now(),
    );

    saveLog(ref, log);

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

  @override
  void dispose() {
    for (final e in _editors) {
      e.controller.dispose();
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                    bottom: 24, top: 8, left: AppSpacing.md, right: AppSpacing.md),
                physics: const BouncingScrollPhysics(),
                children: [
                  for (int i = 0; i < _editors.length; i++) ...[
                    _EntrySection(
                      key: ValueKey(_editors[i].entry.id),
                      editor: _editors[i],
                      index: i,
                      totalCount: _editors.length,
                      projects: myProjects,
                      isEditable: _isEditable,
                      onRemove: () => _removeEntry(i),
                      onProjectSelected: (projectId) {
                        setState(() {
                          _editors[i] = _EntryEditor(
                            entry: _editors[i].entry.copyWith(projectId: projectId),
                            controller: _editors[i].controller,
                          );
                        });
                      },
                      onChanged: (_) => setState(() {}),
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
  _EntryEditor({required this.entry, required this.controller});
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
                ? Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary(context), size: 18)
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 0),
            minLeadingWidth: 0,
            dense: true,
            onTap: widget.isEditable
                ? () {
                    // Attachment picker stub
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Attachment support coming soon.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                : null,
          ),
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
