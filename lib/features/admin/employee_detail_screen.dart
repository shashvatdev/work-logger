import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/api/api_exception.dart';
import '../../data/models/models.dart';
import '../../data/repositories/user_repository.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const EmployeeDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  final _logsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logsScrollController.addListener(_onLogsScroll);
    // Trigger initial log load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(employeeLogsProvider(widget.userId).notifier)
          .load(reset: true);
    });
  }

  @override
  void dispose() {
    _logsScrollController.dispose();
    super.dispose();
  }

  void _onLogsScroll() {
    if (_logsScrollController.position.pixels >=
        _logsScrollController.position.maxScrollExtent - 200) {
      ref.read(employeeLogsProvider(widget.userId).notifier).load();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(employeeDetailProvider(widget.userId));
    ref.invalidate(employeeTodayStatusProvider(widget.userId));
    await ref
        .read(employeeLogsProvider(widget.userId).notifier)
        .load(reset: true);
  }

  void _showEditSheet(UserModel employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditEmployeeSheet(
        employee: employee,
        onUpdated: () {
          ref.invalidate(employeeDetailProvider(widget.userId));
          ref.invalidate(allUsersProvider);
        },
      ),
    );
  }

  Future<void> _confirmDeactivate(UserModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deactivate Employee'),
        content: Text(
          'Are you sure you want to deactivate ${employee.name}? This action soft-deletes the account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary(context))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deactivate',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = UserRepository();
    final result = await repo.deleteUser(widget.userId);
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        ref.invalidate(allUsersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${employee.name} has been deactivated.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (mounted) Navigator.of(context).pop();
      case ApiError(exception: final ex):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ex.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(employeeDetailProvider(widget.userId));
    final todayAsync = ref.watch(employeeTodayStatusProvider(widget.userId));
    final logsState = ref.watch(employeeLogsProvider(widget.userId));

    return employeeAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          backgroundColor: AppColors.background(context),
          surfaceTintColor: Colors.transparent,
          leading: const BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          leading: const BackButton(),
          backgroundColor: AppColors.background(context),
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
      data: (employee) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          appBar: AppBar(
            backgroundColor: AppColors.background(context),
            surfaceTintColor: Colors.transparent,
            leading: const BackButton(),
            title: Text(employee.name,
                style: Theme.of(context).textTheme.titleLarge),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.accent,
                onPressed: () => _showEditSheet(employee),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.person_off_outlined),
                color: AppColors.error,
                onPressed: () => _confirmDeactivate(employee),
                tooltip: 'Deactivate',
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.accent,
            child: CustomScrollView(
              controller: _logsScrollController,
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                // ── Profile Card ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _ProfileCard(employee: employee),
                  ),
                ),

                // ── Today Status ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: _TodayStatusCard(todayAsync: todayAsync),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg)),

                // ── Log History label ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LOG HISTORY',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontSize: 11,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary(context),
                              ),
                        ),
                        if (logsState.total > 0)
                          Text(
                            '${logsState.total} entries',
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: AppColors.textSecondary(context),
                                      fontSize: 11,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Date Filter ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: _DateFilterBar(
                      userId: widget.userId,
                      currentFrom: logsState.from,
                      currentTo: logsState.to,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sm)),

                // ── Logs ─────────────────────────────────────────────────
                if (logsState.logs.isEmpty && logsState.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (logsState.logs.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded,
                                color: AppColors.textSecondary(context),
                                size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'No logs found',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0;
                                i < logsState.logs.length;
                                i++) ...[
                              _LogRow(log: logsState.logs[i]),
                              if (i < logsState.logs.length - 1)
                                const AppDivider(indent: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Load more indicator ──────────────────────────────────
                if (logsState.isLoading && logsState.logs.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),

                if (logsState.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        logsState.error!,
                        style: TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final UserModel employee;
  const _ProfileCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final isAdmin = employee.role == UserRole.admin;
    final joinedDate = employee.createdAt != null
        ? DateFormat('d MMM yyyy').format(employee.createdAt!)
        : '—';

    return SurfaceCard(
      child: Column(
        children: [
          // Avatar + name
          InitialsAvatar(name: employee.name, radius: 32),
          const SizedBox(height: 12),
          Text(
            employee.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            employee.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(
                label: isAdmin ? 'Admin' : 'Employee',
                color: isAdmin ? AppColors.accent : AppColors.textSecondary(context),
              ),
              const SizedBox(width: 8),
              _Badge(
                label: employee.isActive ? 'Active' : 'Inactive',
                color: employee.isActive ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppDivider(),
          const SizedBox(height: 12),
          // Joined date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textSecondary(context)),
              const SizedBox(width: 6),
              Text(
                'Joined $joinedDate',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
      ),
    );
  }
}

// ─── Today Status Card ────────────────────────────────────────────────────────
class _TodayStatusCard extends StatelessWidget {
  final AsyncValue<bool> todayAsync;
  const _TodayStatusCard({required this.todayAsync});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          Icon(Icons.today_rounded,
              color: AppColors.textSecondary(context), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Today\'s Log',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          todayAsync.when(
            loading: () => const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Icon(Icons.help_outline,
                color: AppColors.textSecondary(context), size: 20),
            data: (hasLogged) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasLogged ? '✅ Submitted' : '❌ Not Submitted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasLogged
                            ? AppColors.success
                            : AppColors.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Filter Bar ──────────────────────────────────────────────────────────
class _DateFilterBar extends ConsumerStatefulWidget {
  final String userId;
  final String? currentFrom;
  final String? currentTo;
  const _DateFilterBar(
      {required this.userId, this.currentFrom, this.currentTo});

  @override
  ConsumerState<_DateFilterBar> createState() => _DateFilterBarState();
}

class _DateFilterBarState extends ConsumerState<_DateFilterBar> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.currentFrom != null
        ? DateTime.tryParse(widget.currentFrom!)
        : null;
    _to = widget.currentTo != null
        ? DateTime.tryParse(widget.currentTo!)
        : null;
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_from ?? now) : (_to ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.accent,
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
    _applyFilter();
  }

  void _clearFilter() {
    setState(() {
      _from = null;
      _to = null;
    });
    ref
        .read(employeeLogsProvider(widget.userId).notifier)
        .applyDateFilter(null, null);
  }

  void _applyFilter() {
    final fmt = DateFormat('yyyy-MM-dd');
    ref.read(employeeLogsProvider(widget.userId).notifier).applyDateFilter(
          _from != null ? fmt.format(_from!) : null,
          _to != null ? fmt.format(_to!) : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM');
    final hasFilter = _from != null || _to != null;

    return Row(
      children: [
        Expanded(
          child: _DateChip(
            label: _from != null ? fmt.format(_from!) : 'From',
            isSet: _from != null,
            icon: Icons.calendar_month_outlined,
            onTap: () => _pickDate(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DateChip(
            label: _to != null ? fmt.format(_to!) : 'To',
            isSet: _to != null,
            icon: Icons.calendar_month_outlined,
            onTap: () => _pickDate(false),
          ),
        ),
        if (hasFilter) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close_rounded,
                  color: AppColors.error, size: 18),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSet;
  final IconData icon;
  final VoidCallback onTap;
  const _DateChip(
      {required this.label,
      required this.isSet,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.accent.withOpacity(0.1)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: isSet
              ? Border.all(color: AppColors.accent.withOpacity(0.3))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: isSet
                    ? AppColors.accent
                    : AppColors.textSecondary(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSet
                        ? AppColors.accent
                        : AppColors.textSecondary(context),
                    fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Log Row ──────────────────────────────────────────────────────────────────
class _LogRow extends StatelessWidget {
  final DailyLogModel log;
  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = () {
      try {
        final d = DateFormat('yyyy-MM-dd').parse(log.date);
        return DateFormat('EEE, d MMM yyyy').format(d);
      } catch (_) {
        return log.date;
      }
    }();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormatted,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (log.entries.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...log.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${e.projectName ?? e.projectId}: ${e.description}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ] else
                  Text(
                    '${log.entries.length} entries',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${log.entries.length} ${log.entries.length == 1 ? 'entry' : 'entries'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Employee Bottom Sheet ───────────────────────────────────────────────
class _EditEmployeeSheet extends ConsumerStatefulWidget {
  final UserModel employee;
  final VoidCallback onUpdated;
  const _EditEmployeeSheet(
      {required this.employee, required this.onUpdated});

  @override
  ConsumerState<_EditEmployeeSheet> createState() =>
      _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends ConsumerState<_EditEmployeeSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedRole;
  late bool _isActive;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.employee.name);
    _selectedRole =
        widget.employee.role == UserRole.admin ? 'Admin' : 'Employee';
    _isActive = widget.employee.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters')),
      );
      return;
    }
    setState(() => _loading = true);

    final repo = UserRepository();
    final result = await repo.updateUser(
      widget.employee.id,
      name: _nameCtrl.text.trim(),
      role: _selectedRole,
      isActive: _isActive,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case ApiSuccess():
        widget.onUpdated();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Employee updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      case ApiError(exception: final ex):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ex.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, bottomPadding + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.separator(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Edit Employee',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Name field
          SurfaceCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 4),
            child: TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle:
                    TextStyle(color: AppColors.textSecondary(context)),
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.textSecondary(context), size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Role dropdown
          SurfaceCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: AppColors.elevated(context),
              decoration: const InputDecoration(
                labelText: 'Role',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary(context)),
              items: const [
                DropdownMenuItem(
                    value: 'Employee', child: Text('Employee')),
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Active toggle
          SurfaceCard(
            child: Row(
              children: [
                Icon(Icons.toggle_on_outlined,
                    color: AppColors.textSecondary(context), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Active Status',
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
                Switch.adaptive(
                  value: _isActive,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          PremiumButton(
            label: 'Save Changes',
            loading: _loading,
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
    );
  }
}
