import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../bookings/models/booking_model.dart';

class AdminState {
  final List<VehicleModel> vehicles;
  final List<BookingModel> bookings;
  final int totalUsers;
  final double totalRevenue;
  final int activeBookings;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.vehicles = const [],
    this.bookings = const [],
    this.totalUsers = 0,
    this.totalRevenue = 0,
    this.activeBookings = 0,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<VehicleModel>? vehicles,
    List<BookingModel>? bookings,
    int? totalUsers,
    double? totalRevenue,
    int? activeBookings,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      vehicles: vehicles ?? this.vehicles,
      bookings: bookings ?? this.bookings,
      totalUsers: totalUsers ?? this.totalUsers,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      activeBookings: activeBookings ?? this.activeBookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  StreamSubscription? _vehiclesSubscription;

  AdminNotifier() : super(const AdminState()) {
    _setupVehiclesListener();
  }

  void _setupVehiclesListener() {
    _vehiclesSubscription = _firestore
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final vehicles = snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();
      state = state.copyWith(vehicles: vehicles, isLoading: false, error: null);
    }, onError: (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    });
  }

  Future<void> loadDashboard() async {
    try {
      final bookingsSnap = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();
      final bookings = bookingsSnap.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();

      final usersSnap = await _firestore.collection('users').get();
      final totalUsers = usersSnap.docs.length;

      final totalRevenue = bookings
          .where((b) => b.status == 'completed' || b.status == 'confirmed')
          .fold<double>(0, (total, b) => total + b.totalAmount);

      final activeBookings =
          bookings.where((b) => b.isActive).length;

      state = state.copyWith(
        bookings: bookings,
        totalUsers: totalUsers,
        totalRevenue: totalRevenue,
        activeBookings: activeBookings,
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur de chargement du dashboard');
    }
  }

  Future<bool> addVehicle(VehicleModel vehicle, List<String> imagePaths) async {
    try {
      final imageUrls = <String>[];
      for (final path in imagePaths) {
        final file = File(path);
        final ref = _storage
            .ref()
            .child('vehicles/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      final vehicleWithImages = vehicle.copyWith(images: imageUrls);
      await _firestore
          .collection('vehicles')
          .add(vehicleWithImages.toMap());

      try {
        await _firestore.collection('notifications').add({
          'type': 'new_vehicle',
          'title': 'Nouveau véhicule disponible',
          'body':
              '🚗 ${vehicle.brand} ${vehicle.model} ${vehicle.year} disponible dès maintenant à partir de ${vehicle.pricePerDay.toStringAsFixed(0)} FCFA/jour.',
          'category': vehicle.category,
          'topic': 'new_cars',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'ajout du véhicule');
      return false;
    }
  }

  Future<void> updateVehicle(VehicleModel vehicle, List<String> newImagePaths) async {
    try {
      var images = List<String>.from(vehicle.images);
      for (final path in newImagePaths) {
        final file = File(path);
        final ref = _storage
            .ref()
            .child('vehicles/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        images.add(url);
      }
      final updated = vehicle.copyWith(images: images);
      await _firestore
          .collection('vehicles')
          .doc(vehicle.id)
          .update(updated.toMap());
      await loadDashboard();
    } catch (e) {
      state = state.copyWith(error: 'Erreur de mise à jour');
    }
  }

  Future<bool> deleteVehicle(String id) async {
    try {
      await _firestore.collection('vehicles').doc(id).delete();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur de suppression');
      return false;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      final bookingSnap =
          await _firestore.collection('bookings').doc(bookingId).get();
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      if (bookingSnap.exists) {
        final data = bookingSnap.data()!;
        final userId = data['userId'] ?? '';
        try {
          await _firestore.collection('notifications').add({
            'type': 'booking_$status',
            'userId': userId,
            'title': status == 'confirmed'
                ? 'Réservation confirmée ✅'
                : status == 'completed'
                    ? 'Location terminée'
                    : 'Réservation $status',
            'body': status == 'confirmed'
                ? 'Votre réservation a été confirmée. Préparez-vous pour votre location !'
                : status == 'completed'
                    ? 'Merci d\'avoir loué chez Auto Monpoto. À bientôt !'
                    : 'Votre réservation a été ${status == 'cancelled' ? 'annulée' : 'mise à jour'}.',
            'topic': 'booking_reminders',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur de mise à jour');
    }
  }

  List<Map<String, dynamic>> get monthlyRevenue {
    final revenueByMonth = <String, double>{};
    for (final booking in state.bookings) {
      if (booking.status == 'completed' || booking.status == 'confirmed') {
        final key = '${booking.createdAt.month}/${booking.createdAt.year}';
        revenueByMonth.update(key, (v) => v + booking.totalAmount,
            ifAbsent: () => booking.totalAmount);
      }
    }
    return revenueByMonth.entries
        .map((e) => {'month': e.key, 'revenue': e.value})
        .toList()
      ..sort((a, b) => a['month'].toString().compareTo(b['month'].toString()));
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    super.dispose();
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
