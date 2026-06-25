import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  final _searchController = TextEditingController();
  double? _tempMaxPrice;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredVehicles = ref.watch(filteredVehiclesProvider);
    final vehicleState = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Véhicules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(vehicleProvider.notifier).setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Rechercher par marque ou modèle...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(vehicleProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (vehicleState.selectedCategory != null ||
              vehicleState.maxPrice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (vehicleState.selectedCategory != null)
                    FilterChip(
                      label: Text(vehicleState.selectedCategory!),
                      selected: true,
                      onSelected: (_) {
                        ref
                            .read(vehicleProvider.notifier)
                            .setCategory(null);
                      },
                    ),
                  if (vehicleState.maxPrice != null) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(
                          'Max: ${vehicleState.maxPrice!.toStringAsFixed(0)} FCFA'),
                      selected: true,
                      onSelected: (_) {
                        ref
                            .read(vehicleProvider.notifier)
                            .setMaxPrice(null);
                      },
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Effacer'),
                    onPressed: () =>
                        ref.read(vehicleProvider.notifier).clearFilters(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: vehicleState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Aucun véhicule trouvé'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredVehicles.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildVehicleCard(
                              context, filteredVehicles[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    return GestureDetector(
      onTap: () => context.push('/vehicle/${vehicle.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: vehicle.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: vehicle.images.first,
                      width: 130,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        width: 130,
                        height: 110,
                      ),
                    )
                  : Container(
                      width: 130,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(Icons.directions_car, size: 40),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (vehicle.available)
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 18)
                        else
                          const Icon(Icons.cancel,
                              color: AppColors.error, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.year} · ${vehicle.transmission ?? "Manuelle"} · ${vehicle.seats ?? 5} places',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (vehicle.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                vehicle.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    _tempMaxPrice = ref.read(vehicleProvider).maxPrice;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Prix maximum par jour'),
                  const SizedBox(height: 8),
                  Slider(
                    value: _tempMaxPrice ?? 200000,
                    min: 0,
                    max: 500000,
                    divisions: 50,
                    label:
                        '${(_tempMaxPrice ?? 200000).toStringAsFixed(0)} FCFA',
                    onChanged: (v) {
                      setSheetState(() {
                        _tempMaxPrice = v;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Catégorie'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Électrique',
                      'Essence',
                      'SUV',
                      'Berline',
                      'Utilitaire'
                    ].map((cat) {
                      final selected =
                          ref.read(vehicleProvider).selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) {
                          ref
                              .read(vehicleProvider.notifier)
                              .setCategory(selected ? null : cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(vehicleProvider.notifier).clearFilters();
                            setSheetState(() {
                              _tempMaxPrice = null;
                            });
                          },
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(vehicleProvider.notifier)
                                .setMaxPrice(_tempMaxPrice);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
