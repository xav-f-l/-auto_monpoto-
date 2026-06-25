import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_watcher.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(unreadNotificationCountProvider.notifier).state = 0;
    });
  }

  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: user == null
          ? const Center(
              child: Text('Connecte-toi pour voir tes notifications'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where(
                    'createdAt',
                    isGreaterThan: user.createdAt.isAfter(
                            DateTime.now().subtract(const Duration(days: 7)))
                        ? user.createdAt
                        : DateTime.now()
                            .subtract(const Duration(days: 7)),
                  )
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Aucune notification'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                        doc.data() as Map<String, dynamic>;
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
                          backgroundColor:
                              color.withValues(alpha: 0.1),
                          child: Icon(icon, color: color),
                        ),
                        title:
                            Text(data['title'] ?? 'Notification'),
                        subtitle: Text(data['body'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(
                                  (data['createdAt']
                                          as Timestamp?)
                                      ?.toDate()),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18,
                                  color: AppColors.textSecondary),
                              onPressed: () =>
                                  _deleteNotification(doc.id),
                            ),
                          ],
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
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
