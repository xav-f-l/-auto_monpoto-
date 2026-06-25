import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/providers/notification_preferences_provider.dart';

final unreadNotificationCountProvider = StateProvider<int?>((ref) => null);

class NotificationWatcher {
  final Ref _ref;
  StreamSubscription<QuerySnapshot>? _subscription;
  final Set<String> _processedIds = {};
  bool _isFirstSnapshot = true;

  NotificationWatcher(this._ref);

  void start() {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    _ref.read(unreadNotificationCountProvider.notifier).state = 0;

    final cutoff = user.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
        ? user.createdAt
        : DateTime.now().subtract(const Duration(days: 7));

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('createdAt', isGreaterThan: cutoff)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          if (_isFirstSnapshot) {
            _processedIds.add(change.doc.id);
          } else if (!_processedIds.contains(change.doc.id)) {
            _processedIds.add(change.doc.id);
            _showNotification(change.doc);
            final count = _ref.read(unreadNotificationCountProvider) ?? 0;
            _ref.read(unreadNotificationCountProvider.notifier).state = count + 1;
            _cleanupOldNotifications(user.id);
          }
        }
      }
      _isFirstSnapshot = false;
    });
  }

  Future<void> _cleanupOldNotifications(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .get();

    final docs = snapshot.docs;
    if (docs.length <= 6) return;

    final toDelete = docs.skip(6);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in toDelete) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void _showNotification(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final user = _ref.read(authProvider).user;
    if (user == null) return;

    final prefs = _ref.read(notificationPrefsProvider);
    final topic = data['topic'] as String?;
    final targetUserId = data['userId'] as String?;

    if (targetUserId != null && targetUserId != user.id) return;

    final topicAllowed = switch (topic) {
      'new_cars' => prefs.newCars,
      'promotions' => prefs.promotions,
      'booking_reminders' => prefs.bookingReminders,
      'offers' => prefs.offers,
      _ => true,
    };

    if (!topicAllowed) return;

    NotificationService.instance.showLocalNotification(
      title: data['title'] ?? 'Auto Monpoto',
      body: data['body'] ?? '',
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
