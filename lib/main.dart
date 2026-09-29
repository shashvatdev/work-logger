import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/api/api_client.dart';

void main() {
  // Preserve the native splash — we'll remove it ourselves once auth is ready
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const ProviderScope(child: TrackItApp()));
}

class TrackItApp extends ConsumerStatefulWidget {
  const TrackItApp({super.key});

  @override
  ConsumerState<TrackItApp> createState() => _TrackItAppState();
}

class _TrackItAppState extends ConsumerState<TrackItApp> {
  bool _splashRemoved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ApiClient.onUnauthorized = () {
      Future.microtask(() {
        if (ref.read(currentUserProvider) != null) {
          ref.read(currentUserProvider.notifier).state = null;
          ref.invalidate(allProjectsProvider);
          ref.invalidate(myProjectsProvider);
          ref.invalidate(todayLogProvider);
          ref.invalidate(allUsersProvider);
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authCheckProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // Remove the native splash exactly once — as soon as auth check finishes
    if (!authAsync.isLoading && !_splashRemoved) {
      _splashRemoved = true;
      // Post-frame so the correct screen is already built before splash disappears
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }

    return MaterialApp.router(
      title: 'Track It',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
