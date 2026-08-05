import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure GoogleFonts runtime fetching
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Hive local NoSQL storage boxes safely before runApp
  try {
    await HiveService.init();
  } catch (e, stack) {
    debugPrint('Hive initialization error in main: $e\n$stack');
  }

  runApp(
    const ProviderScope(
      child: PureDropAquaApp(),
    ),
  );
}

class PureDropAquaApp extends StatelessWidget {
  const PureDropAquaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
