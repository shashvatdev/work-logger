import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../../data/mock/mock_data.dart';

// ─── Current User ────────────────────────────────────────────────────────────
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// ─── All Users (for Admin) ───────────────────────────────────────────────────
final allUsersProvider = StateProvider<List<UserModel>>((ref) => mockUsers);

// ─── Projects ─────────────────────────────────────────────────────────────────
final allProjectsProvider = StateProvider<List<ProjectModel>>((ref) => mockProjects);

final myProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final projects = ref.watch(allProjectsProvider);
  if (user == null) return [];
  if (user.isAdmin) return projects.where((p) => !p.archived).toList();
  return projects
      .where((p) => !p.archived && p.memberIds.contains(user.id))
      .toList();
});

// ─── Daily Logs ───────────────────────────────────────────────────────────────
final allLogsProvider =
    StateProvider<Map<String, DailyLogModel>>((ref) => Map.from(mockDailyLogs));

String _logKey(String uid, DateTime date) =>
    '${uid}_${DateFormat('yyyy-MM-dd').format(date)}';

final todayLogProvider = Provider<DailyLogModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  final logs = ref.watch(allLogsProvider);
  if (user == null) return null;
  return logs[_logKey(user.id, DateTime.now())];
});

final yesterdayLogProvider = Provider<DailyLogModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  final logs = ref.watch(allLogsProvider);
  if (user == null) return null;
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return logs[_logKey(user.id, yesterday)];
});

// ─── Employee Today Status (Admin) ──────────────────────────────────────────
final employeeTodayStatusProvider = Provider.family<bool, String>((ref, uid) {
  final logs = ref.watch(allLogsProvider);
  final today = DateTime.now();
  return logs.containsKey(_logKey(uid, today));
});

// ─── Log for specific uid + date ─────────────────────────────────────────────
final logForDateProvider =
    Provider.family<DailyLogModel?, ({String uid, DateTime date})>((ref, args) {
  final logs = ref.watch(allLogsProvider);
  return logs[_logKey(args.uid, args.date)];
});

// ─── Dates with logs (for calendar) ─────────────────────────────────────────
final datesWithLogsProvider = Provider.family<Set<String>, String>((ref, uid) {
  final logs = ref.watch(allLogsProvider);
  return logs.entries
      .where((e) => e.value.userId == uid)
      .map((e) => e.value.date)
      .toSet();
});

// ─── Search ───────────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return [];

  final logs = ref.watch(allLogsProvider);
  final users = ref.watch(allUsersProvider);
  final projects = ref.watch(allProjectsProvider);
  final currentUser = ref.watch(currentUserProvider);

  final userMap = {for (final u in users) u.id: u};
  final projectMap = {for (final p in projects) p.id: p};

  final results = <SearchResult>[];

  for (final log in logs.values) {
    // Employee can only see their own logs
    if (currentUser != null && !currentUser.isAdmin) {
      if (log.userId != currentUser.id) continue;
    }
    for (final entry in log.entries) {
      final project = projectMap[entry.projectId];
      final user = userMap[log.userId];
      if (project == null || user == null) continue;

      final matchDesc = entry.description.toLowerCase().contains(query);
      final matchProject = project.name.toLowerCase().contains(query);
      final matchUser = user.name.toLowerCase().contains(query);

      if (matchDesc || matchProject || matchUser) {
        results.add(SearchResult(
          date: log.date,
          projectName: project.name,
          excerpt: _excerpt(entry.description, query),
          userId: log.userId,
          userName: user.name,
          logId: log.id,
        ));
      }
    }
  }

  results.sort((a, b) => b.date.compareTo(a.date));
  return results;
});

String _excerpt(String text, String query) {
  final lower = text.toLowerCase();
  final idx = lower.indexOf(query);
  if (idx == -1) return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  final start = (idx - 30).clamp(0, text.length);
  final end = (idx + query.length + 50).clamp(0, text.length);
  final excerpt = text.substring(start, end);
  return '${start > 0 ? '…' : ''}$excerpt${end < text.length ? '…' : ''}';
}

// ─── Save Log ─────────────────────────────────────────────────────────────────
void saveLog(WidgetRef ref, DailyLogModel log) {
  ref.read(allLogsProvider.notifier).update((state) {
    final updated = Map<String, DailyLogModel>.from(state);
    updated[log.id] = log;
    return updated;
  });
}
