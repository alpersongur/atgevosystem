import 'package:flutter/material.dart';

import 'package:atgevosystem/core/services/notification_service.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final notifications = await service
                  .streamNotifications(unreadOnly: true)
                  .first;
              await Future.wait(
                notifications.map((item) => service.markAsRead(item.id)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tüm bildirimler okundu.')),
                );
              }
            },
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('Tümünü Okundu Yap'),
          ),
        ],
      ),
      body: StreamBuilder<List<SystemNotification>>(
        stream: service.streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Bildirimler yüklenemedi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = snapshot.data ?? const <SystemNotification>[];
          if (items.isEmpty) {
            return const Center(
              child: Text('Yeni bildirim yok.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = items[index];
              final isUnread = !notification.read;
              return ListTile(
                leading: Icon(
                  _iconForType(notification.type),
                  color: _colorForType(context, notification.type),
                ),
                title: Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                      ),
                ),
                subtitle: Text(notification.message),
                trailing: isUnread
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.indigo,
                        ),
                      )
                    : null,
                onTap: () async {
                  await service.markAsRead(notification.id);
                  if (notification.target.isEmpty) return;
                  if (!context.mounted) return;
                  try {
                    await Navigator.of(context)
                        .pushNamed(notification.target.trim());
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bildirim hedefi açılamadı: ${notification.target}',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_outlined;
      case 'task':
        return Icons.checklist_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorForType(BuildContext context, String type) {
    switch (type) {
      case 'alert':
        return Colors.redAccent;
      case 'task':
        return Colors.blueAccent;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
