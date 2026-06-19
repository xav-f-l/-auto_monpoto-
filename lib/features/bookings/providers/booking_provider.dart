import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../../vehicles/models/vehicle_model.dart';

class BookingState {
  final List<BookingModel> bookings;
  final BookingModel? currentBooking;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? pickupLocation;
  final String? returnLocation;
  final double? calculatedTotal;

  const BookingState({
    this.bookings = const [],
    this.currentBooking,
    this.isLoading = false,
    this.error,
    this.startDate,
    this.endDate,
    this.pickupLocation,
    this.returnLocation,
    this.calculatedTotal,
  });

  BookingState copyWith({
    List<BookingModel>? bookings,
    BookingModel? currentBooking,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? pickupLocation,
    String? returnLocation,
    double? calculatedTotal,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      currentBooking: currentBooking ?? this.currentBooking,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      returnLocation: returnLocation ?? this.returnLocation,
      calculatedTotal: calculatedTotal ?? this.calculatedTotal,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BookingNotifier() : super(const BookingState());

  void setStartDate(DateTime? date) {
    state = state.copyWith(startDate: date);
    _recalculateTotal();
  }

  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: date);
    _recalculateTotal();
  }

  void setPickupLocation(String location) {
    state = state.copyWith(pickupLocation: location);
  }

  void setReturnLocation(String location) {
    state = state.copyWith(returnLocation: location);
  }

  void _recalculateTotal() {
    if (state.startDate != null && state.endDate != null) {
      final days = state.endDate!.difference(state.startDate!).inDays;
      if (days > 0) {
        state = state.copyWith(calculatedTotal: null);
      }
    }
  }

  double calculateTotal(VehicleModel vehicle) {
    if (state.startDate == null || state.endDate == null) {
      return vehicle.pricePerDay;
    }
    final days = state.endDate!.difference(state.startDate!).inDays;
    return vehicle.pricePerDay * (days > 0 ? days : 1);
  }

  Future<void> createBooking({
    required VehicleModel vehicle,
    required String userId,
    required double totalAmount,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final booking = BookingModel(
        id: '',
        vehicleId: vehicle.id,
        userId: userId,
        startDate: state.startDate ?? now,
        endDate: state.endDate ?? now.add(const Duration(days: 1)),
        totalAmount: totalAmount,
        pickupLocation: state.pickupLocation,
        returnLocation: state.returnLocation,
        createdAt: now,
        updatedAt: now,
      );

      final docRef =
          await _firestore.collection('bookings').add(booking.toMap());
      final created = booking.copyWith(id: docRef.id);

      try {
        await _firestore.collection('notifications').add({
          'type': 'booking_confirmed',
          'userId': userId,
          'title': 'Réservation confirmée',
          'body':
              'Votre réservation ${vehicle.fullName} est confirmée du ${booking.startDate.day}/${booking.startDate.month} au ${booking.endDate.day}/${booking.endDate.month}.',
          'topic': 'booking_reminders',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      state = state.copyWith(
        currentBooking: created,
        isLoading: false,
        startDate: null,
        endDate: null,
        pickupLocation: null,
        returnLocation: null,
        calculatedTotal: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création de la réservation',
      );
    }
  }

  Future<void> loadUserBookings(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();

      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<void> loadAllBookings() async {
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();

      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      state = state.copyWith(
        bookings: state.bookings.map((b) {
          if (b.id == bookingId) return b.copyWith(status: status);
          return b;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Erreur de mise à jour');
    }
  }

  void reset() {
    state = const BookingState();
  }
}

final bookingProvider =
    StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier();
});
