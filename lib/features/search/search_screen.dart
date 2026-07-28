import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.valueOrNull ?? <SearchResult>[];
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final user = ref.read(currentUserProvider);
              if (user?.isAdmin == true) {
                context.go('/admin/employees');
              } else {
                context.go('/home');
              }
            }
          },
        ),
        title: Text('Search', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
                  AppSpacing.md, AppSpacing.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 12),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: _focus.hasFocus ? 1.1 : 1.0,
                        child: Icon(Icons.search_rounded,
                            color: _focus.hasFocus ? AppColors.accent : AppColors.textSecondary(context), size: 20),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        onChanged: (v) {
                          setState(() {});
                          ref.read(searchQueryProvider.notifier).state = v;
                        },
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'Search logs, projects, team...',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, left: 8),
                          child: Icon(Icons.cancel_rounded,
                              color: AppColors.textSecondary(context),
                              size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Results ───────────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: query.isEmpty
                    ? _EmptySearchState(key: const ValueKey('empty'))
                    : resultsAsync.hasError
                        ? Center(
                            key: const ValueKey('error'),
                            child: Text(
                              'Failed to perform search.',
                              style: TextStyle(color: AppColors.error),
                            ),
                          )
                        : resultsAsync.isLoading
                            ? ListView.separated(
                                key: const ValueKey('loading'),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: 3,
                                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (_, __) => const SkeletonLoader(width: double.infinity, height: 120, borderRadius: 16),
                              )
                            : results.isEmpty
                                ? _NoResultsState(
                                    key: const ValueKey('noResults'),
                                    query: query,
                                  )
                                : ListView.separated(
                            key: const ValueKey('results'),
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) =>
                                StaggeredItem(index: i, child: _SearchResultCard(result: results[i])),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  final dynamic result;
  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateDisplay = _formatDate(result.date);
    final currentUser = ref.watch(currentUserProvider);
    final showEmployee = currentUser?.isAdmin ?? false;

    return SurfaceCard(
      onTap: () {
        final isSelf = currentUser != null && currentUser.id == result.userId;
        final viewQuery = (!isSelf && showEmployee) ? '&viewUserId=${result.userId}' : '';
        final projQuery = result.projectId.isNotEmpty ? '?projectId=${result.projectId}$viewQuery' : (viewQuery.isNotEmpty ? '?${viewQuery.substring(1)}' : '');
        context.push('/log/${result.date}$projQuery');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChipLabel(label: result.projectName, color: AppColors.projectColor(result.projectId)),
              if ((result.timeSpent ?? result.hoursSpent ?? result.duration) != null &&
                  (result.timeSpent ?? result.hoursSpent ?? result.duration).toString().isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled_rounded,
                          size: 10, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(
                        (result.timeSpent ?? result.hoursSpent ?? result.duration).toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                dateDisplay,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          if (showEmployee) ...[
            Text(
              result.userName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            result.excerpt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('d MMM').format(date);
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyStateWidget(
        icon: Icons.manage_search_rounded,
        title: 'Search your work',
        subtitle: 'Find by keyword, project, or team member.',
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No results',
        subtitle: 'Try different keywords or date range.',
      ),
    );
  }
}
