import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/tech_lead_projects_screen.dart';
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
import '../../features/log/team_logs_screen.dart';
import '../../features/attendance/presentation/pages/attendance_calendar_screen.dart';
import '../../features/admin/admin_attendance_screen.dart';
import '../../features/admin/geofence_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/regularization/presentation/employee/my_requests_screen.dart';
import '../../features/regularization/presentation/admin/admin_requests_screen.dart';
import '../widgets/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  // Watch authCheckProvider so the router rebuilds when auth state changes
  ref.watch(authCheckProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth',
    redirect: (context, state) {
      // While auth check is still running, don't redirect — native splash is still visible
      final authAsync = ref.read(authCheckProvider);
      if (authAsync.isLoading) return null;

      final loggedIn = currentUser != null;
      final onAuth = state.matchedLocation == '/auth';
      final isPublic = onAuth || state.matchedLocation == '/change-password';

      if (!loggedIn && !isPublic) return '/auth';
      if (loggedIn && onAuth) {
        return currentUser.isAdmin ? '/admin/employees' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(
          path: '/change-password',
          builder: (_, __) => const ChangePasswordScreen()),

      // ── Employee & Tech Lead routes ─────────────────────────────────────────
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/projects/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return AdminProjectDetailScreen(projectId: id);
        },
      ),
      GoRoute(
        path: '/tech-lead/projects',
        builder: (_, __) => const TechLeadProjectsScreen(),
      ),
      GoRoute(path: '/team-logs', builder: (_, __) => const TeamLogsScreen()),
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
      GoRoute(path: '/attendance', builder: (_, __) => const AttendanceCalendarScreen()),

      // ── Admin routes ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/employees',
                builder: (_, __) => const AdminEmployeesScreen(),
                routes: [
                  // /admin/employees/add must come BEFORE /admin/employees/:uid
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddEmployeeScreen(),
                  ),
                  GoRoute(
                    path: ':uid',
                    builder: (_, state) {
                      final uid = state.pathParameters['uid']!;
                      return EmployeeDetailScreen(userId: uid);
                    },
                    routes: [
                      GoRoute(
                        path: 'calendar',
                        builder: (_, state) {
                          final uid = state.pathParameters['uid']!;
                          return AdminEmployeeCalendarScreen(userId: uid);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/projects',
                builder: (_, __) => const AdminProjectListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final id = state.pathParameters['id']!;
                      return AdminProjectDetailScreen(projectId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/attendance',
                builder: (_, __) => const AdminAttendanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/offices',
                builder: (_, __) => const GeofenceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/search',
                builder: (_, __) => const SearchScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Profile route (all users) ──────────────────────────────────────────
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/regularization/my', builder: (_, __) => const MyRequestsScreen()),
      GoRoute(path: '/regularization/admin', builder: (_, __) => const AdminRequestsScreen()),
    ],
  );
});
