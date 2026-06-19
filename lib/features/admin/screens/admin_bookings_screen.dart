import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../../bookings/models/booking_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des réservations'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) {
                final booking = state.bookings[index];
                return _buildBookingCard(context, ref, booking);
              },
            ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, WidgetRef ref, BookingModel booking) {
    Color statusColor;
    switch (booking.status) {
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'confirmed':
        statusColor = AppColors.success;
        break;
      case 'in_progress':
        statusColor = AppColors.info;
        break;
      case 'completed':
        statusColor = AppColors.primary;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${booking.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(booking.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.person, 'Client', booking.userId),
            _buildInfoRow(
              Icons.calendar_today,
              'Dates',
              '${booking.startDate.day}/${booking.startDate.month} - ${booking.endDate.day}/${booking.endDate.month}',
            ),
            _buildInfoRow(
              Icons.monetization_on,
              'Montant',
              '${booking.totalAmount.toStringAsFixed(0)} FCFA',
            ),
            const SizedBox(height: 12),
            if (booking.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        onPressed: () {
                          ref
                              .read(adminProvider.notifier)
                              .updateBookingStatus(booking.id, 'confirmed');
                        },
                        child: const Text('Confirmer',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () {
                          ref
                              .read(adminProvider.notifier)
                              .updateBookingStatus(booking.id, 'cancelled');
                        },
                        child: const Text('Annuler',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            if (booking.status == 'confirmed')
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(adminProvider.notifier)
                        .updateBookingStatus(booking.id, 'completed');
                  },
                  child:
                      const Text('Marquer comme terminée', style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}
