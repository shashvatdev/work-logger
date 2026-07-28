import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/log/log_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/admin/admin_employees_screen.dart';
import '../../features/admin/add_employee_screen.dart';
import '../../features/admin/employee_detail_screen.dart';
import '../../features/admin/admin_project_list_screen.dart';
import '../../features/admin/admin_project_detail_screen.dart';
import '../../features/admin/admin_employee_calendar_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth',
    redirect: (context, state) {
      final loggedIn = currentUser != null;
      final onAuth = state.matchedLocation == '/auth';

      if (!loggedIn && !onAuth) return '/auth';
      if (loggedIn && onAuth) {
        return currentUser.isAdmin ? '/admin/employees' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),

      // ── Employee routes ────────────────────────────────────────────────────
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/log/:date',
        builder: (_, state) {
          final dateStr = state.pathParameters['date']!;
          final date = DateTime.parse(dateStr);
          final viewUserId = state.uri.queryParameters['viewUserId'];
          final projectId = state.uri.queryParameters['projectId'];
          return LogScreen(
            date: date,
            viewUserId: viewUserId,
            initialProjectId: projectId,
          );
        },
      ),
      GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),

      // ── Admin routes ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/employees',
            builder: (_, __) => const AdminEmployeesScreen(),
          ),
          GoRoute(
            path: '/admin/projects',
            builder: (_, __) => const AdminProjectListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/projects/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return AdminProjectDetailScreen(projectId: id);
        },
      ),
      // /admin/employees/add must come BEFORE /admin/employees/:uid
      GoRoute(
        path: '/admin/employees/add',
        builder: (_, __) => const AddEmployeeScreen(),
      ),
      GoRoute(
        path: '/admin/employees/:uid',
        builder: (_, state) {
          final uid = state.pathParameters['uid']!;
          return EmployeeDetailScreen(userId: uid);
        },
      ),
      GoRoute(
        path: '/admin/employees/:uid/calendar',
        builder: (_, state) {
          final uid = state.pathParameters['uid']!;
          return AdminEmployeeCalendarScreen(userId: uid);
        },
      ),
    ],
  );
});
