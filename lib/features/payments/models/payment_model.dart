import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel extends Equatable {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String method;
  final String status;
  final String? transactionId;
  final String? phoneNumber;
  final String? reference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.method,
    this.status = 'pending',
    this.transactionId,
    this.phoneNumber,
    this.reference,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookingId': bookingId,
        'userId': userId,
        'amount': amount,
        'method': method,
        'status': status,
        'transactionId': transactionId,
        'phoneNumber': phoneNumber,
        'reference': reference,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      method: map['method'] ?? '',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      phoneNumber: map['phoneNumber'],
      reference: map['reference'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? method,
    String? status,
    String? transactionId,
    String? phoneNumber,
    String? reference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        userId,
        amount,
        method,
        status,
        transactionId,
        phoneNumber,
        reference,
        createdAt,
        updatedAt,
      ];
}
