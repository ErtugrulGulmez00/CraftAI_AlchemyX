import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/local_storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.initHive();

  await SupabaseService.init();
  final remote = SupabaseService();

  runApp(MyApp(remote: remote));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.remote});

  final SupabaseService remote;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'CraftAI',
            debugShowCheckedModeBanner: false,
            // The game is dark-only by design — every screen is built on
            // the cosmic starfield, so a light theme never fit.
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            themeAnimationDuration: Duration.zero,
            home: SplashView(remote: remote),
          );
        },
      ),
    );
  }
}
