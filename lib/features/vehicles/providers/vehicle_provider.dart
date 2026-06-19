import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

class VehicleState {
  final List<VehicleModel> vehicles;
  final List<VehicleModel> popularVehicles;
  final VehicleModel? selectedVehicle;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final double? maxPrice;
  final String? searchQuery;

  const VehicleState({
    this.vehicles = const [],
    this.popularVehicles = const [],
    this.selectedVehicle,
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.maxPrice,
    this.searchQuery,
  });

  VehicleState copyWith({
    List<VehicleModel>? vehicles,
    List<VehicleModel>? popularVehicles,
    VehicleModel? selectedVehicle,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    double? maxPrice,
    String? searchQuery,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      popularVehicles: popularVehicles ?? this.popularVehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      maxPrice: maxPrice ?? this.maxPrice,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<VehicleModel> get filteredVehicles {
    var result = vehicles;
    if (selectedCategory != null) {
      result = result.where((v) => v.category == selectedCategory).toList();
    }
    if (maxPrice != null) {
      result = result.where((v) => v.pricePerDay <= maxPrice!).toList();
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result
          .where((v) =>
              v.brand.toLowerCase().contains(query) ||
              v.model.toLowerCase().contains(query))
          .toList();
    }
    return result;
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  VehicleNotifier() : super(const VehicleState()) {
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection('vehicles')
          .orderBy('createdAt', descending: true)
          .get();

      final vehicles = snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();

      final popular = vehicles.where((v) => v.rating != null && v.rating! >= 4.0).toList();
      popular.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      state = state.copyWith(
        vehicles: vehicles,
        popularVehicles: popular.take(10).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des véhicules',
      );
    }
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setMaxPrice(double? price) {
    state = state.copyWith(maxPrice: price);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      maxPrice: null,
      searchQuery: null,
    );
  }

  Future<void> selectVehicle(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final doc = await _firestore.collection('vehicles').doc(id).get();
      if (doc.exists) {
        final vehicle = VehicleModel.fromMap(doc.data()!, doc.id);
        state = state.copyWith(selectedVehicle: vehicle, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Véhicule introuvable');
    }
  }

  Future<void> refresh() => _loadVehicles();
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>(
    (ref) => VehicleNotifier());

final filteredVehiclesProvider = Provider<List<VehicleModel>>((ref) {
  return ref.watch(vehicleProvider).filteredVehicles;
});
