import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/api/api_exception.dart';

// ─── Paginated Users Notifier ─────────────────────────────────────────────────
class _UsersListState {
  final List<UserModel> users;
  final int total;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String searchQuery;

  const _UsersListState({
    this.users = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.searchQuery = '',
  });

  _UsersListState copyWith({
    List<UserModel>? users,
    int? total,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? searchQuery,
  }) =>
      _UsersListState(
        users: users ?? this.users,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() =>
      _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends ConsumerState<AdminEmployeesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  _UsersListState _state = const _UsersListState();
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage(reset: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_state.isLoading) return;
    if (!reset && !_state.hasMore) return;

    final nextPage = reset ? 1 : _state.page;
    setState(() => _state = _state.copyWith(isLoading: true));

    try {
      final userRepo = UserRepository();
      final result = await userRepo.getAllUsers(page: nextPage, pageSize: _pageSize);

      switch (result) {
        case ApiSuccess(data: final newUsers):
          final all = reset ? newUsers : [..._state.users, ...newUsers];
          setState(() {
            _state = _state.copyWith(
              users: all,
              total: all.length, // accumulate
              page: nextPage + 1,
              isLoading: false,
              hasMore: newUsers.length == _pageSize,
            );
          });
        case ApiError(exception: final ex):
          setState(() => _state = _state.copyWith(isLoading: false));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ex.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
      }
    } catch (_) {
      setState(() => _state = _state.copyWith(isLoading: false));
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(allUsersProvider);
    await _loadPage(reset: true);
  }

  List<UserModel> get _filtered {
    final q = _state.searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _state.users;
    return _state.users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final filtered = _filtered;
    final logged = filtered.where((u) => u.hasLoggedToday).length;
    final notLogged = filtered.length - logged;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_state.users.length} members',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Add employee button
                            _AddButton(onTap: () async {
                              await context.push('/admin/employees/add');
                              _refresh();
                            }),
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: () async {
                                await AuthRepository().logout();
                                ref
                                    .read(currentUserProvider.notifier)
                                    .state = null;
                                ref.invalidate(allUsersProvider);
                                ref.invalidate(allProjectsProvider);
                                ref.invalidate(myProjectsProvider);
                                ref.invalidate(todayLogProvider);
                              },
                              child: InitialsAvatar(
                                  name: currentUser?.name ?? 'Admin',
                                  radius: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // ── Today Status Summary ─────────────────────────────────
                    _TodayStatusSummary(
                        logged: logged, notLogged: notLogged),
                    const SizedBox(height: AppSpacing.md),
                    // ── Search Bar ──────────────────────────────────────────
                    _SearchBar(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _state = _state.copyWith(searchQuery: v)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section label ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                child: Text(
                  'ALL MEMBERS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary(context),
                      ),
                ),
              ),
            ),

            // ── Employee list ────────────────────────────────────────────────
            if (filtered.isEmpty && _state.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _state.searchQuery.isEmpty
                          ? 'No employees yet'
                          : 'No results for "${_state.searchQuery}"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (int i = 0; i < filtered.length; i++) ...[
                          _EmployeeRow(
                            employee: filtered[i],
                            onTap: () => context
                                .push('/admin/employees/${filtered[i].id}'),
                          ),
                          if (i < filtered.length - 1)
                            const AppDivider(indent: 72),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // ── Load-more indicator ─────────────────────────────────────────
            if (_state.isLoading && _state.users.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }
}

// ─── Add Button ──────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─── Today Status Summary ─────────────────────────────────────────────────────
class _TodayStatusSummary extends StatelessWidget {
  final int logged;
  final int notLogged;
  const _TodayStatusSummary({required this.logged, required this.notLogged});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '$logged',
              label: 'Updated Today',
              color: AppColors.logDot,
            ),
          ),
          Container(
            width: 0.5,
            height: 36,
            color: AppColors.separator(context),
          ),
          Expanded(
            child: _StatCell(
              value: '$notLogged',
              label: 'No Update',
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w300,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary(context),
              ),
        ),
      ],
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search name or email…',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary(context),
              ),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: AppColors.textSecondary(context)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─── Employee Row ─────────────────────────────────────────────────────────────
class _EmployeeRow extends StatelessWidget {
  final UserModel employee;
  final VoidCallback onTap;
  const _EmployeeRow({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isInactive = !employee.isActive;

    return Opacity(
      opacity: isInactive ? 0.45 : 1.0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
        leading: InitialsAvatar(name: employee.name, radius: 20),
        title: Row(
          children: [
            Expanded(
              child: Text(employee.name,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(width: 6),
            _RoleBadge(role: employee.role),
          ],
        ),
        subtitle: Row(
          children: [
            StatusDot(active: employee.hasLoggedToday, size: 7),
            const SizedBox(width: 6),
            Text(
              employee.hasLoggedToday ? 'Updated Today' : 'No Update',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: employee.hasLoggedToday
                        ? AppColors.logDot
                        : AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
            ),
            if (isInactive) ...[
              const SizedBox(width: 8),
              Text(
                '• Inactive',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary(context), size: 20),
        onTap: onTap,
      ),
    );
  }
}

// ─── Role Badge ───────────────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isAdmin ? AppColors.accent : AppColors.textSecondary(context))
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Employee',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isAdmin
                  ? AppColors.accent
                  : AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
