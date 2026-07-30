import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/api/api_client.dart';
import 'core/widgets/splash_screen.dart';

void main() {
  // Remove native splash immediately — our custom splash takes over
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: TrackItApp()));
}

class TrackItApp extends ConsumerStatefulWidget {
  const TrackItApp({super.key});

  @override
  ConsumerState<TrackItApp> createState() => _TrackItAppState();
}

class _TrackItAppState extends ConsumerState<TrackItApp> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    // Show our custom splash for exactly 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

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
    final authCheck = ref.watch(authCheckProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Show our animated splash until BOTH 3 seconds have passed AND auth check is done
    final showSplash = !_splashDone || authCheck.isLoading;

    if (showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const SplashScreen(),
      );
    }

    // Auth check done — go to real app (handle error same as success, router decides)
    final router = ref.watch(appRouterProvider);
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
