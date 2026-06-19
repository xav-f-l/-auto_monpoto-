import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/providers/notification_preferences_provider.dart';

class NotificationWatcher {
  final Ref _ref;
  StreamSubscription<QuerySnapshot>? _subscription;

  NotificationWatcher(this._ref);

  void start() {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('createdAt', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNotification(change.doc);
        }
      }
    });
  }

  void _handleNotification(DocumentSnapshot doc) {
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

    doc.reference.delete();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
