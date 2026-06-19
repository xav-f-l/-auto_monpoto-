import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/local_storage_service.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.instance.initialize();
  await FirebaseService.instance.initialize();
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: AutoMonpotoApp(),
    ),
  );
}

class AutoMonpotoApp extends ConsumerWidget {
  const AutoMonpotoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Auto Monpoto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
