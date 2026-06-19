import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../providers/booking_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const BookingScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _pickupController = TextEditingController();
  final _returnController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vehicleProvider.notifier).selectVehicle(widget.vehicleId);
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          ref.read(bookingProvider.notifier).setStartDate(picked);
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 1));
            ref.read(bookingProvider.notifier).setEndDate(_endDate);
          }
        } else {
          _endDate = picked;
          ref.read(bookingProvider.notifier).setEndDate(picked);
        }
      });
    }
  }

  void _handleBooking() {
    final vehicle = ref.read(vehicleProvider).selectedVehicle;
    if (vehicle == null) return;
    final user = ref.read(authProvider).user;
    if (user == null) {
      context.go('/login');
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates')),
      );
      return;
    }
    final total = ref.read(bookingProvider.notifier).calculateTotal(vehicle);
    ref.read(bookingProvider.notifier).createBooking(
          vehicle: vehicle,
          userId: user.id,
          totalAmount: total,
        );
    context.push('/payment/${vehicle.id}');
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicle = vehicleState.selectedVehicle;
    if (vehicle == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = ref.read(bookingProvider.notifier).calculateTotal(vehicle);

    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_car, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA/jour',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dates de location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Départ',
                    _startDate,
                    () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    'Retour',
                    _endDate,
                    () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Lieux',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _pickupController,
              label: 'Lieu de récupération',
              hint: 'Adresse de départ',
              prefixIcon: const Icon(Icons.location_on),
              onChanged: (v) =>
                  ref.read(bookingProvider.notifier).setPickupLocation(v),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _returnController,
              label: 'Lieu de retour',
              hint: 'Adresse de retour',
              prefixIcon: const Icon(Icons.location_on),
              onChanged: (v) =>
                  ref.read(bookingProvider.notifier).setReturnLocation(v),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total estimé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Continuer vers le paiement',
              onPressed: _handleBooking,
              icon: Icons.payment,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Sélectionner',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: date != null ? AppColors.textPrimary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
