import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_preferences.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationPrefsNotifier extends StateNotifier<NotificationPreferences> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  NotificationPrefsNotifier() : super(const NotificationPreferences());

  void setUserId(String userId) {
    _userId = userId;
    _loadPrefs(userId);
  }

  Future<void> _loadPrefs(String userId) async {
    try {
      final doc =
          await _firestore.collection('notification_prefs').doc(userId).get();
      if (doc.exists) {
        state = NotificationPreferences.fromMap(doc.data()!);
      }
    } catch (_) {}
  }

  Future<void> _savePrefs() async {
    if (_userId == null) return;
    await _firestore
        .collection('notification_prefs')
        .doc(_userId!)
        .set(state.toMap());
  }

  Future<void> togglePromotions() async {
    state = state.copyWith(promotions: !state.promotions);
    await _savePrefs();
  }

  Future<void> toggleNewCars() async {
    state = state.copyWith(newCars: !state.newCars);
    await _savePrefs();
  }

  Future<void> toggleBookingReminders() async {
    state = state.copyWith(bookingReminders: !state.bookingReminders);
    await _savePrefs();
  }

  Future<void> toggleOffers() async {
    state = state.copyWith(offers: !state.offers);
    await _savePrefs();
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPreferences>(
        (ref) {
  final notifier = NotificationPrefsNotifier();
  final authState = ref.watch(authProvider);
  if (authState.user != null) {
    notifier.setUserId(authState.user!.id);
  }
  return notifier;
});
