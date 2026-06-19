import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_watcher.dart';
import '../../features/auth/providers/auth_provider.dart';

final notificationWatcherProvider = Provider<NotificationWatcher?>((ref) {
  final authState = ref.watch(authProvider);
  final watcher = NotificationWatcher(ref);

  ref.onDispose(() => watcher.dispose());

  if (authState.status == AuthStatus.authenticated) {
    watcher.start();
  }

  return watcher;
});
