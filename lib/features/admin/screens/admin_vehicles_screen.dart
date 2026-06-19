import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/admin_provider.dart';
import '../../vehicles/models/vehicle_model.dart';
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
            onPressed: () =>
                Navigator.pushNamed(context, '/admin/add-vehicle'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
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
                                  width: 80,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.directions_car),
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
                              Text(
                                '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    vehicle.available ? 'Disponible' : 'Indisponible',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: vehicle.available
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                          children: [
                            IconButton(
                              icon: const Icon(Icons.image,
                                  size: 20, color: AppColors.info),
                              onPressed: () => _addImageDialog(context, ref, vehicle),
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

  void _addImageDialog(
      BuildContext context, WidgetRef ref, VehicleModel vehicle) {
    final controller = TextEditingController(
      text: 'https://upload.wikimedia.org/wikipedia/commons/7/72/2019_Tesla_Model_3_Standard_Range_Plus.jpg',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter une image - ${vehicle.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Colle l'URL de l'image :"),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "URL de l'image",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final updated = vehicle.copyWith(
                  images: [...vehicle.images, controller.text],
                );
                ref.read(adminProvider.notifier).updateVehicle(updated);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
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
            onPressed: () {
              ref.read(adminProvider.notifier).deleteVehicle(id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
