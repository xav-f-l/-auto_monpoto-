import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Monpoto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            const SizedBox(height: 24),
            _buildSearchBar(context, ref),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Catégories', () {}),
            const SizedBox(height: 12),
            _buildCategories(ref),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Véhicules populaires', () {
              context.push('/vehicles');
            }),
            const SizedBox(height: 12),
            if (vehicleState.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: vehicleState.popularVehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _buildVehicleCard(
                      context,
                      vehicleState.popularVehicles[index],
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Tous les véhicules', () {
              context.push('/vehicles');
            }),
            const SizedBox(height: 12),
            if (vehicleState.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ...vehicleState.vehicles
                  .take(4)
                  .map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildVehicleListItem(context, v),
                      )),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Jusqu\'à -20%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sur votre première location',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.discount,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (value) {
        ref.read(vehicleProvider.notifier).setSearchQuery(value);
      },
      decoration: InputDecoration(
        hintText: 'Rechercher une voiture...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color ?? Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('Voir tout'),
        ),
      ],
    );
  }

  Widget _buildCategories(WidgetRef ref) {
    final categories = [
      {'icon': Icons.electric_car, 'label': 'Électrique'},
      {'icon': Icons.local_gas_station, 'label': 'Essence'},
      {'icon': Icons.directions_car, 'label': 'SUV'},
      {'icon': Icons.airport_shuttle, 'label': 'Utilitaire'},
      {'icon': Icons.time_to_leave, 'label': 'Berline'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              avatar: Icon(cat['icon'] as IconData, size: 20),
              label: Text(cat['label'] as String),
              selected: false,
              onSelected: (_) {
                ref
                    .read(vehicleProvider.notifier)
                    .setCategory(cat['label'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    return GestureDetector(
      onTap: () => context.push('/vehicle/${vehicle.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: vehicle.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: vehicle.images.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        height: 120,
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      height: 120,
                      child: const Icon(Icons.directions_car, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleListItem(BuildContext context, VehicleModel vehicle) {
    return GestureDetector(
      onTap: () => context.push('/vehicle/${vehicle.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
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
                      width: 100,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 90,
                      color: Colors.grey[200],
                      child: const Icon(Icons.directions_car),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.year} · ${vehicle.transmission ?? "Manuelle"}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
}
