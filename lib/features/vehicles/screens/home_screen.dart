import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/notification_watcher.dart';

class _NotifBadge extends ConsumerWidget {
  const _NotifBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeCount = ref.watch(unreadNotificationCountProvider);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: null,
          ),
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, user),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBanner(),
                  const SizedBox(height: 24),
                  _buildSearchBar(context, ref),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Catégories', () {
                    ref.read(vehicleProvider.notifier).setCategory(null);
                    context.push('/vehicles');
                  }),
                  const SizedBox(height: 12),
                  _buildCategories(context, ref),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Véhicules populaires', () {
                    context.push('/vehicles');
                  }),
                  const SizedBox(height: 12),
                  if (vehicleState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    SizedBox(
                      height: 240,
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final topPadding = MediaQuery.of(context).padding.top + 16;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withAlpha(51),
            backgroundImage: user?.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null
                ? Text(
                    (user?.firstName.isNotEmpty == true
                            ? user!.firstName[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bonjour, ${user?.firstName ?? "..."}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Prêt pour l'aventure ?",
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: const _NotifBadge(),
          ),
        ],
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
                  "Jusqu'à -20%",
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
                    color: Colors.white.withAlpha(230),
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
              color: Colors.white.withAlpha(51),
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
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _buildCategories(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(vehicleProvider).selectedCategory;
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
          final label = cat['label'] as String;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              avatar: Icon(cat['icon'] as IconData, size: 20),
              label: Text(label),
              selected: selectedCategory == label,
              onSelected: (_) {
                ref.read(vehicleProvider.notifier).setCategory(
                      selectedCategory == label ? null : label,
                    );
                context.push('/vehicles');
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
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
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
              child: Stack(
                children: [
                  vehicle.images.isNotEmpty
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: vehicle.available
                            ? AppColors.success.withAlpha(204)
                            : AppColors.error.withAlpha(204),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicle.available ? 'Disponible' : 'Indisponible',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
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
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
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
              child: Stack(
                children: [
                  vehicle.images.isNotEmpty
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
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: vehicle.available
                            ? AppColors.success.withAlpha(204)
                            : AppColors.error.withAlpha(204),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vehicle.available ? 'Dispo' : 'Indispo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
