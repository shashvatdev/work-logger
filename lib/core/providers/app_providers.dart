import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../api/api_exception.dart';
import '../api/token_storage.dart';

// ─── Employee Logs State ──────────────────────────────────────────────────────
class EmployeeLogsState {
  final List<DailyLogModel> logs;
  final int total;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? from;
  final String? to;

  const EmployeeLogsState({
    this.logs = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.from,
    this.to,
  });

  EmployeeLogsState copyWith({
    List<DailyLogModel>? logs,
    int? total,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? from,
    String? to,
  }) {
    return EmployeeLogsState(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

// ─── Current User ────────────────────────────────────────────────────────────
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final authCheckProvider = FutureProvider<void>((ref) async {
  final token = await TokenStorage.getAccessToken();
  if (token != null) {
    final repo = UserRepository();
    final result = await repo.getMe();
    if (result is ApiSuccess<UserModel>) {
      ref.read(currentUserProvider.notifier).state = result.data;
    } else {
      await TokenStorage.clearAll();
    }
  }
});

// ─── All Users (for Admin) ───────────────────────────────────────────────────
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isAdmin) return <UserModel>[];
  
  final repo = UserRepository();
  final result = await repo.getAllUsers();
  return switch (result) {
    ApiSuccess(data: final users) => users,
    ApiError(exception: final ex) => throw ex,
  };
});

// ─── Projects ─────────────────────────────────────────────────────────────────
final allProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <ProjectModel>[];

  final repo = ProjectRepository();
  final result = await repo.getProjects();
  return switch (result) {
    ApiSuccess(data: final projects) => projects,
    ApiError(exception: final ex) => throw ex,
  };
});

final myProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <ProjectModel>[];
  
  final projects = await ref.watch(allProjectsProvider.future);
  if (user.isAdmin) return projects.where((p) => !p.archived).toList();
  // The API already filters the project list to show only assigned projects for employees.
  return projects.where((p) => !p.archived).toList();
});

final projectTimelineProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  final repo = ProjectRepository();
  final result = await repo.getProjectTimeline(projectId);
  return switch (result) {
    ApiSuccess(data: final data) => List<Map<String, dynamic>>.from(data['entries'] ?? []),
    ApiError(exception: final ex) => throw ex,
  };
});

// ─── Daily Logs ───────────────────────────────────────────────────────────────
final todayLogProvider = FutureProvider<DailyLogModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = LogRepository();
  final result = await repo.getTodayLog();
  return switch (result) {
    ApiSuccess(data: final log) => log,
    ApiError(exception: final ex) => throw ex,
  };
});

final logForDateProvider = FutureProvider.family<DailyLogModel?, ({String uid, DateTime date})>((ref, args) async {
  final currentUser = ref.watch(currentUserProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(args.date);
  final repo = LogRepository();
  final isSelf = currentUser != null && currentUser.id == args.uid;

  final result = isSelf
      ? await repo.getLogByDate(dateStr)
      : await repo.getUserLogByDate(args.uid, dateStr);

  return switch (result) {
    ApiSuccess(data: final log) => log,
    ApiError(exception: final ex) => throw ex,
  };
});

// ─── Employee Today Status (Admin) ──────────────────────────────────────────
final employeeTodayStatusProvider = FutureProvider.family<bool, String>((ref, uid) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isAdmin) return false;

  final repo = UserRepository();
  final result = await repo.getTodayStatus(uid);
  return switch (result) {
    ApiSuccess(data: final status) => status['hasLoggedToday'] == true,
    ApiError(exception: final ex) => throw ex,
  };
});

// ─── Dates with logs (for calendar) ─────────────────────────────────────────
final datesWithLogsProvider = FutureProvider.family<Set<String>, ({String uid, int year, int month})>((ref, args) async {
  final currentUser = ref.watch(currentUserProvider);
  final repo = LogRepository();
  
  final from = DateTime(args.year, args.month, 1);
  final to = DateTime(args.year, args.month + 1, 0); // Last day of month
  
  final fromStr = DateFormat('yyyy-MM-dd').format(from);
  final toStr = DateFormat('yyyy-MM-dd').format(to);
  
  final isSelf = currentUser != null && currentUser.id == args.uid;
  
  final result = isSelf
      ? await repo.getLogs(from: fromStr, to: toStr, pageSize: 100)
      : await repo.getUserLogs(args.uid, from: fromStr, to: toStr, pageSize: 100);

  return switch (result) {
    ApiSuccess(data: final data) => (data['logs'] as List).map((l) => l['logDate'] as String).toSet(),
    ApiError(exception: final ex) => throw ex,
  };
});

// ─── Search ───────────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return [];
  
  final repo = SearchRepository();
  final result = await repo.search(query: query);
  
  return switch (result) {
    ApiSuccess(data: final data) => (data['results'] as List)
        .map((r) => SearchResult(
              date: r['logDate'] ?? '',
              projectName: r['projectName'] ?? '',
              projectId: r['projectId'] ?? '',
              excerpt: r['excerpt'] ?? '',
              userId: r['userId'] ?? '',
              userName: r['userName'] ?? '',
              logId: r['logId'] ?? '', // backend does not return logId in search? Let's use empty or adjust
              logEntryId: r['logEntryId'] ?? '',
            ))
        .toList(),
    ApiError(exception: final ex) => throw ex,
  };
});

// ─── Employee Detail (Admin) ──────────────────────────────────────────────────
final employeeDetailProvider = FutureProvider.family<UserModel, String>((ref, uid) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isAdmin) throw Exception('Unauthorized');
  final repo = UserRepository();
  final result = await repo.getUserById(uid);
  return switch (result) {
    ApiSuccess(data: final u) => u,
    ApiError(exception: final ex) => throw ex,
  };
});

// ─── Employee Logs Notifier (paginated, with date filter) ─────────────────────
class EmployeeLogsNotifier extends StateNotifier<EmployeeLogsState> {
  final String userId;
  static const int _pageSize = 20;

  EmployeeLogsNotifier(this.userId, Ref ref) : super(const EmployeeLogsState());

  Future<void> load({bool reset = false, String? from, String? to}) async {
    if (state.isLoading) return;
    if (!reset && !state.hasMore) return;

    final nextPage = reset ? 1 : state.page;
    state = state.copyWith(
      isLoading: true,
      error: null,
      logs: reset ? [] : state.logs,
      page: nextPage,
      hasMore: reset ? true : state.hasMore,
      from: from ?? (reset ? null : state.from),
      to: to ?? (reset ? null : state.to),
    );

    final fromFilter = from ?? (reset ? null : state.from);
    final toFilter = to ?? (reset ? null : state.to);

    final repo = UserRepository();
    final result = await repo.getUserLogs(
      userId,
      from: fromFilter,
      to: toFilter,
      page: nextPage,
      pageSize: _pageSize,
    );

    switch (result) {
      case ApiSuccess(data: final data):
        final rawLogs = (data['logs'] as List? ?? []);
        final newLogs = rawLogs.map((l) => DailyLogModel.fromJson(l)).toList();
        final total = data['total'] as int? ?? 0;
        final allLogs = reset ? newLogs : [...state.logs, ...newLogs];
        state = state.copyWith(
          logs: allLogs,
          total: total,
          page: nextPage + 1,
          isLoading: false,
          hasMore: allLogs.length < total,
          from: fromFilter,
          to: toFilter,
        );
      case ApiError(exception: final ex):
        state = state.copyWith(isLoading: false, error: ex.message);
    }
  }

  Future<void> applyDateFilter(String? from, String? to) async {
    await load(reset: true, from: from, to: to);
  }
}

final employeeLogsProvider = StateNotifierProvider.family<EmployeeLogsNotifier, EmployeeLogsState, String>(
  (ref, userId) => EmployeeLogsNotifier(userId, ref),
);
