import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/supabase_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Graceful fallback if .env is missing or invalid
  }

  // Initialize Supabase client
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: LocalLensTravelerApp(),
    ),
  );
}

class LocalLensTravelerApp extends ConsumerWidget {
  const LocalLensTravelerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LocalLens Traveler',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
