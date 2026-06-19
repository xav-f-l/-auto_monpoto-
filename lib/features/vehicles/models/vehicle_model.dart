import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel extends Equatable {
  final String id;
  final String brand;
  final String model;
  final int year;
  final double pricePerDay;
  final List<String> images;
  final String description;
  final String category;
  final bool available;
  final double? rating;
  final int? ratingCount;
  final String? transmission;
  final int? seats;
  final double? fuelConsumption;
  final String? fuelType;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.pricePerDay,
    required this.images,
    required this.description,
    this.category = 'standard',
    this.available = true,
    this.rating,
    this.ratingCount,
    this.transmission,
    this.seats,
    this.fuelConsumption,
    this.fuelType,
    this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$brand $model';

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        'pricePerDay': pricePerDay,
        'images': images,
        'description': description,
        'category': category,
        'available': available,
        'rating': rating,
        'ratingCount': ratingCount,
        'transmission': transmission,
        'seats': seats,
        'fuelConsumption': fuelConsumption,
        'fuelType': fuelType,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      description: map['description'] ?? '',
      category: map['category'] ?? 'standard',
      available: map['available'] ?? true,
      rating: (map['rating'] as num?)?.toDouble(),
      ratingCount: map['ratingCount'],
      transmission: map['transmission'],
      seats: map['seats'],
      fuelConsumption: (map['fuelConsumption'] as num?)?.toDouble(),
      fuelType: map['fuelType'],
      location: map['location'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  VehicleModel copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    double? pricePerDay,
    List<String>? images,
    String? description,
    String? category,
    bool? available,
    double? rating,
    int? ratingCount,
    String? transmission,
    int? seats,
    double? fuelConsumption,
    String? fuelType,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      images: images ?? this.images,
      description: description ?? this.description,
      category: category ?? this.category,
      available: available ?? this.available,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      transmission: transmission ?? this.transmission,
      seats: seats ?? this.seats,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      fuelType: fuelType ?? this.fuelType,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brand,
        model,
        year,
        pricePerDay,
        images,
        description,
        category,
        available,
        rating,
        ratingCount,
        transmission,
        seats,
        fuelConsumption,
        fuelType,
        location,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      ];
}
