import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vehicleProvider.notifier).selectVehicle(widget.vehicleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleProvider);
    final vehicle = state.selectedVehicle;

    return Scaffold(
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehicle == null
              ? const Center(child: Text('Véhicule introuvable'))
              : _buildContent(vehicle),
    );
  }

  Widget _buildContent(VehicleModel vehicle) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(vehicle),
        SliverToBoxAdapter(child: _buildBody(vehicle)),
      ],
    );
  }

  Widget _buildAppBar(VehicleModel vehicle) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: vehicle.images.isNotEmpty
            ? Stack(
                children: [
                  PageView.builder(
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemCount: vehicle.images.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: vehicle.images[i],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[200]),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        vehicle.images.length,
                        (i) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == i
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(color: Colors.grey[200]),
      ),
    );
  }

  Widget _buildBody(VehicleModel vehicle) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  vehicle.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: vehicle.available
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  vehicle.available ? 'Disponible' : 'Indisponible',
                  style: TextStyle(
                    color:
                        vehicle.available ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (vehicle.rating != null) ...[
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${vehicle.rating!.toStringAsFixed(1)} (${vehicle.ratingCount ?? 0})',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Text('/ jour', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          const Text(
            'Caractéristiques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFeature(Icons.calendar_today, '${vehicle.year}'),
              _buildFeature(Icons.car_repair,
                  vehicle.transmission ?? 'Manuelle'),
              _buildFeature(Icons.event_seat, '${vehicle.seats ?? 5} places'),
              _buildFeature(Icons.local_gas_station,
                  vehicle.fuelType ?? 'Essence'),
              if (vehicle.fuelConsumption != null)
                _buildFeature(
                    Icons.speed, '${vehicle.fuelConsumption} L/100km'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            vehicle.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (vehicle.location != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Localisation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(vehicle.location!),
              ],
            ),
          ],
          const SizedBox(height: 32),
          CustomButton(
            text: 'Réserver maintenant',
            onPressed: vehicle.available
                ? () => context.push('/booking/${vehicle.id}')
                : null,
            icon: Icons.calendar_month,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
