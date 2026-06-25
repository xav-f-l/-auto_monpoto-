import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: user == null
          ? const Center(child: Text('Connecte-toi pour voir tes notifications'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('createdAt',
                      isGreaterThan:
                          DateTime.now().subtract(const Duration(days: 7)))
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Aucune notification'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final topic = data['topic'] as String?;
                    IconData icon;
                    Color color;
                    switch (topic) {
                      case 'new_cars':
                        icon = Icons.directions_car;
                        color = AppColors.primary;
                        break;
                      case 'promotions':
                        icon = Icons.discount;
                        color = Colors.amber;
                        break;
                      case 'booking_reminders':
                        icon = Icons.calendar_month;
                        color = AppColors.success;
                        break;
                      case 'offers':
                        icon = Icons.local_offer;
                        color = AppColors.accent;
                        break;
                      default:
                        icon = Icons.notifications;
                        color = AppColors.info;
                    }
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(data['title'] ?? 'Notification'),
                        subtitle: Text(data['body'] ?? ''),
                        trailing: Text(
                          _formatTime((data['createdAt'] as Timestamp?)?.toDate()),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
