import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/api/api_client.dart';

void main() {
  runApp(const ProviderScope(child: WorkLogApp()));
}

class WorkLogApp extends ConsumerWidget {
  const WorkLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ApiClient.onUnauthorized = () {
      // Defer to avoid updating providers during build
      Future.microtask(() {
        if (ref.read(currentUserProvider) != null) {
          ref.read(currentUserProvider.notifier).state = null;
          ref.invalidate(allProjectsProvider);
          ref.invalidate(myProjectsProvider);
          ref.invalidate(todayLogProvider);
          ref.invalidate(yesterdayLogProvider);
          ref.invalidate(allUsersProvider);
        }
      });
    };

    final authCheck = ref.watch(authCheckProvider);

    return authCheck.when(
      data: (_) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          title: 'WorkLog',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, stack) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          title: 'WorkLog',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
