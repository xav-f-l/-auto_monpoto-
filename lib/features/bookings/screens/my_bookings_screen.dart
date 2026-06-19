import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/services/receipt_service.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBookings);
  }

  void _loadBookings() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(bookingProvider.notifier).loadUserBookings(user.id);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadBookings(),
        child: state.isLoading
            ? const LoadingWidget()
            : state.bookings.isEmpty
                ? const EmptyWidget(
                    message: 'Aucune réservation pour le moment',
                    icon: Icons.calendar_today,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: state.bookings.length,
                    itemBuilder: (context, index) {
                      final booking = state.bookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
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
                  'Réservation #${booking.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(booking.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(booking.status),
                    style: TextStyle(
                      color: _statusColor(booking.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Du ${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  'au ${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.pickupLocation ?? 'Non spécifié',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  '${booking.totalAmount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (booking.status == 'confirmed' ||
                booking.status == 'completed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt, size: 16),
                    label: const Text('Télécharger le reçu',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () => _downloadReceipt(booking),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReceipt(BookingModel booking) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(booking.vehicleId)
          .get();
      if (!vehicleDoc.exists) return;
      final vehicle = VehicleModel.fromMap(vehicleDoc.data()!, vehicleDoc.id);

      final bytes = await ReceiptService.generateReceipt(
        booking: booking,
        vehicle: vehicle,
        user: user,
      );
      await ReceiptService.saveAndOpen(bytes);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la génération du reçu')),
        );
      }
    }
  }
}
