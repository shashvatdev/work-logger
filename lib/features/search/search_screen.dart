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
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 14, right: 8),
                      child: Icon(Icons.search_rounded,
                          color: AppColors.textSecondary(context), size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        onChanged: (v) {
                          ref.read(searchQueryProvider.notifier).state = v;
                        },
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Search logs, projects, team...',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
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
                            ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
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
                                _SearchResultCard(result: results[i]),
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
              ChipLabel(label: result.projectName),
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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded,
              size: 48, color: AppColors.textSecondary(context)),
          const SizedBox(height: 16),
          Text(
            'Search your work logs',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find by keyword, project or team member.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textSecondary(context)),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }
}
