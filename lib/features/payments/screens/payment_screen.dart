import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/payment_provider.dart';
import '../../bookings/providers/booking_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/receipt_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const PaymentScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  bool _showCardFields = false;
  bool _acceptTerms = false;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'airtel_money', 'name': 'Airtel Money', 'icon': Icons.phone_android, 'color': const Color(0xFFED1C24)},
    {'id': 'orange_money', 'name': 'Orange Money', 'icon': Icons.phone_iphone, 'color': const Color(0xFFFF7900)},
    {'id': 'moov_money', 'name': 'Moov Money', 'icon': Icons.phone_android, 'color': const Color(0xFF00A2E8)},
    {'id': 'card', 'name': 'Carte bancaire', 'icon': Icons.credit_card, 'color': const Color(0xFF2C3E50)},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vehicleProvider.notifier).selectVehicle(widget.vehicleId);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    final method = ref.read(paymentProvider).selectedMethod;
    if (method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un moyen de paiement')),
      );
      return;
    }
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acceptez les conditions générales')),
      );
      return;
    }

    if (method == 'card') {
      if (_cardNumberController.text.length < 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro de carte invalide')),
        );
        return;
      }
    } else {
      if (_phoneController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro de téléphone invalide')),
        );
        return;
      }
    }

    final user = ref.read(authProvider).user;
    final vehicle = ref.read(vehicleProvider).selectedVehicle;
    final booking = ref.read(bookingProvider).currentBooking;

    if (user == null || vehicle == null || booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: réservation introuvable')),
      );
      return;
    }

    final success = await ref.read(paymentProvider.notifier).processPayment(
          bookingId: booking.id,
          userId: user.id,
          amount: booking.totalAmount,
          method: method,
          phoneNumber: method != 'card' ? _phoneController.text : null,
        );

    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              'Paiement réussi !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre réservation a été confirmée.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Télécharger le reçu',
              icon: Icons.receipt,
              onPressed: () async {
                final user = ref.read(authProvider).user;
                final vehicle = ref.read(vehicleProvider).selectedVehicle;
                final booking = ref.read(bookingProvider).currentBooking;
                if (user != null && vehicle != null && booking != null) {
                  final bytes = await ReceiptService.generateReceipt(
                    booking: booking,
                    vehicle: vehicle,
                    user: user,
                  );
                  await ReceiptService.saveAndOpen(bytes);
                }
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Voir mes réservations',
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/my-bookings');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicle = vehicleState.selectedVehicle;
    final bookingState = ref.watch(bookingProvider);
    final paymentState = ref.watch(paymentProvider);

    final booking = bookingState.currentBooking;
    final totalAmount = booking?.totalAmount ?? vehicle?.pricePerDay ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicle != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(vehicle.fullName),
                  subtitle:
                      Text('${totalAmount.toStringAsFixed(0)} FCFA'),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Moyen de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._methods.map((method) {
              final selected =
                  ref.watch(paymentProvider).selectedMethod == method['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(paymentProvider.notifier).setMethod(method['id']);
                    setState(() {
                      _showCardFields = method['id'] == 'card';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            (method['color'] as Color).withValues(alpha: 0.1),
                        child: Icon(method['icon'] as IconData,
                            color: method['color']),
                      ),
                      title: Text(method['name'] as String),
                      trailing: selected
                          ? const Icon(Icons.check_circle,
                              color: AppColors.primary)
                          : const Icon(Icons.circle_outlined),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            if (!_showCardFields)
              CustomTextField(
                controller: _phoneController,
                label: 'Numéro de téléphone Mobile Money',
                hint: 'Ex: 0601020304',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
                onChanged: (v) =>
                    ref.read(paymentProvider.notifier).setPhoneNumber(v),
              ),
            if (_showCardFields) ...[
              CustomTextField(
                controller: _cardNumberController,
                label: 'Numéro de carte',
                hint: '1234 5678 9012 3456',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.credit_card),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cardExpiryController,
                      label: 'Date d\'expiration',
                      hint: 'MM/AA',
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _cardCvvController,
                      label: 'CVV',
                      hint: '123',
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Card(
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total à payer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalAmount.toStringAsFixed(0)} FCFA',
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
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text(
                'J\'accepte les conditions générales de location',
                style: TextStyle(fontSize: 13),
              ),
              value: _acceptTerms,
              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (paymentState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                paymentState.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Payer ${totalAmount.toStringAsFixed(0)} FCFA',
              isLoading: paymentState.isLoading,
              onPressed: _handlePayment,
              icon: Icons.lock,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
