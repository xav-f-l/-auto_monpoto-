import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel extends Equatable {
  final String id;
  final String vehicleId;
  final String userId;
  final String? driverName;
  final String? driverPhone;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final double? amountPaid;
  final String status;
  final String? pickupLocation;
  final String? returnLocation;
  final String? paymentMethod;
  final String? paymentId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.vehicleId,
    required this.userId,
    this.driverName,
    this.driverPhone,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    this.amountPaid,
    this.status = 'pending',
    this.pickupLocation,
    this.returnLocation,
    this.paymentMethod,
    this.paymentId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  int get numberOfDays => endDate.difference(startDate).inDays;
  bool get isActive => status == 'confirmed' || status == 'in_progress';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicleId': vehicleId,
        'userId': userId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'totalAmount': totalAmount,
        'amountPaid': amountPaid,
        'status': status,
        'pickupLocation': pickupLocation,
        'returnLocation': returnLocation,
        'paymentMethod': paymentMethod,
        'paymentId': paymentId,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      vehicleId: map['vehicleId'] ?? '',
      userId: map['userId'] ?? '',
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      amountPaid: (map['amountPaid'] as num?)?.toDouble(),
      status: map['status'] ?? 'pending',
      pickupLocation: map['pickupLocation'],
      returnLocation: map['returnLocation'],
      paymentMethod: map['paymentMethod'],
      paymentId: map['paymentId'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  BookingModel copyWith({
    String? id,
    String? vehicleId,
    String? userId,
    String? driverName,
    String? driverPhone,
    DateTime? startDate,
    DateTime? endDate,
    double? totalAmount,
    double? amountPaid,
    String? status,
    String? pickupLocation,
    String? returnLocation,
    String? paymentMethod,
    String? paymentId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      returnLocation: returnLocation ?? this.returnLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        userId,
        driverName,
        driverPhone,
        startDate,
        endDate,
        totalAmount,
        amountPaid,
        status,
        pickupLocation,
        returnLocation,
        paymentMethod,
        paymentId,
        notes,
        createdAt,
        updatedAt,
      ];
}
