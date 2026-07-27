import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../api/api_exception.dart';
import '../api/token_storage.dart';

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

final yesterdayLogProvider = FutureProvider<DailyLogModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final dateStr = DateFormat('yyyy-MM-dd').format(yesterday);
  final repo = LogRepository();
  final result = await repo.getLogByDate(dateStr);
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
