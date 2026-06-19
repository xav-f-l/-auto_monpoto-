import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_preferences_provider.dart';
import '../../../core/theme/app_colors.dart';

class NotificationPrefsSection extends ConsumerWidget {
  const NotificationPrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Préférences de notification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildSwitch(
          icon: Icons.discount_outlined,
          iconColor: Colors.amber,
          title: 'Promotions',
          subtitle: 'Réductions et offres spéciales',
          value: prefs.promotions,
          onChanged: (_) =>
              ref.read(notificationPrefsProvider.notifier).togglePromotions(),
        ),
        _buildSwitch(
          icon: Icons.directions_car_outlined,
          iconColor: AppColors.primary,
          title: 'Nouvelles voitures',
          subtitle: 'Véhicules ajoutés récemment',
          value: prefs.newCars,
          onChanged: (_) =>
              ref.read(notificationPrefsProvider.notifier).toggleNewCars(),
        ),
        _buildSwitch(
          icon: Icons.calendar_month_outlined,
          iconColor: AppColors.success,
          title: 'Rappels de réservation',
          subtitle: 'Confirmation, début et fin de location',
          value: prefs.bookingReminders,
          onChanged: (_) => ref
              .read(notificationPrefsProvider.notifier)
              .toggleBookingReminders(),
        ),
        _buildSwitch(
          icon: Icons.local_offer_outlined,
          iconColor: AppColors.accent,
          title: 'Offres spéciales',
          subtitle: 'Offres personnalisées et recommandations',
          value: prefs.offers,
          onChanged: (_) =>
              ref.read(notificationPrefsProvider.notifier).toggleOffers(),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}
