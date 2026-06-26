import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AdminVehiclesScreen extends ConsumerWidget {
  const AdminVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des véhicules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await context.push<bool>('/admin/add-vehicle');
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Véhicule ajouté')),
                );
              }
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(state.error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: state.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = state.vehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: vehicle.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: vehicle.images.first,
                                  width: 100,
                                  height: 75,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 100,
                                  height: 75,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.directions_car, size: 32),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                              Row(
                                children: [
                                  Icon(Icons.local_offer,
                                      size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    vehicle.available
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 14,
                                    color: vehicle.available
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    vehicle.available
                                        ? 'Disponible'
                                        : 'Indisponible',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: vehicle.available
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.category,
                                      size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    vehicle.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                vehicle.available
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                                color: vehicle.available
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              onPressed: () => ref
                                  .read(adminProvider.notifier)
                                  .toggleVehicleAvailability(
                                      vehicle.id, vehicle.available),
                              tooltip: vehicle.available
                                  ? 'Rendre indisponible'
                                  : 'Rendre disponible',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 20, color: AppColors.info),
                              onPressed: () => context.push(
                                '/admin/edit-vehicle',
                                extra: vehicle,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 20, color: AppColors.error),
                              onPressed: () => _confirmDelete(
                                  context, ref, vehicle.id, vehicle.fullName),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer $name ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(adminProvider.notifier).deleteVehicle(id);
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '$name supprimé' : 'Erreur lors de la suppression'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
