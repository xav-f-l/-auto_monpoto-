import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';


class PaymentState {
  final PaymentModel? currentPayment;
  final List<PaymentModel> payments;
  final bool isLoading;
  final String? error;
  final String? selectedMethod;
  final String? phoneNumber;

  const PaymentState({
    this.currentPayment,
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.selectedMethod,
    this.phoneNumber,
  });

  PaymentState copyWith({
    PaymentModel? currentPayment,
    List<PaymentModel>? payments,
    bool? isLoading,
    String? error,
    String? selectedMethod,
    String? phoneNumber,
  }) {
    return PaymentState(
      currentPayment: currentPayment ?? this.currentPayment,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PaymentNotifier() : super(const PaymentState());

  void setMethod(String method) {
    state = state.copyWith(selectedMethod: method);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  Future<bool> processPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String method,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final payment = PaymentModel(
        id: '',
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        method: method,
        status: 'completed',
        phoneNumber: phoneNumber,
        transactionId: 'TXN${now.millisecondsSinceEpoch}',
        reference: 'REF${now.millisecondsSinceEpoch}',
        createdAt: now,
        updatedAt: now,
      );

      final docRef =
          await _firestore.collection('payments').add(payment.toMap());
      final created = payment.copyWith(id: docRef.id);

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'confirmed',
        'paymentMethod': method,
        'paymentId': docRef.id,
        'updatedAt': Timestamp.now(),
      });

      state = state.copyWith(
        currentPayment: created,
        isLoading: false,
        selectedMethod: null,
        phoneNumber: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de paiement. Veuillez réessayer.',
      );
      return false;
    }
  }

  Future<void> loadPayments(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();

      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  void reset() {
    state = const PaymentState();
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});
