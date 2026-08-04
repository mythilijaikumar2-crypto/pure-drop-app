import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    try {
      // 1. Asynchronously initialize Hive storage while Splash is on screen
      await HiveService.init();

      // 2. Clear initial demo data & ensure clean storage state
      await ref.read(appRepositoryProvider).seedInitialDataIfEmpty();

      // 3. Re-check saved user session
      ref.read(authProvider.notifier).checkSavedSession();
    } catch (e) {
      debugPrint('Splash initialization error: $e');
    }

    // Min splash display time for visual polish
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.user != null) {
      if (authState.user!.role == UserRole.admin) {
        context.go('/dashboard');
      } else {
        context.go('/delivery');
      }
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: const AppLogo(size: 240)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1.06, 1.06),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}
