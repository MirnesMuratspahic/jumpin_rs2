import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class NotificationsScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const NotificationsScreen({super.key, required this.authProvider});

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final _provider = NotificationProvider();
  List<NotificationItem> _items = [];
  bool _isLoading = true;
  Timer? _pollTimer;

  static const Color _primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _provider.setToken(widget.authProvider.token);
    _load();
    // Live-refresh while the screen is open so new notifications appear.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Reloads the list. Called when the tab becomes active again.
  void reload() => _load();

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final items = await _provider.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (silent) {
        logError('Notification poll failed', e);
      } else {
        showApiError(context, e);
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _provider.markAllRead();
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'REQUEST_CREATED':
        return Icons.move_to_inbox;
      case 'REQUEST_ACCEPTED':
        return Icons.check_circle;
      case 'REQUEST_DECLINED':
        return Icons.cancel;
      case 'VIP_ACTIVATED':
        return Icons.workspace_premium;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _primaryColor,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = _items[index];
                      return Container(
                        color: n.isRead ? Colors.white : const Color(0xFFE3F2FD),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _primaryColor.withOpacity(0.1),
                            child: Icon(_iconFor(n.type), color: _primaryColor),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  n.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.message),
                              if (n.createdAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat('dd.MM.yyyy HH:mm')
                                        .format(n.createdAt!.toLocal()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: n.isRead
                              ? null
                              : () async {
                                  try {
                                    await _provider.markRead(n.id);
                                    await _load(silent: true);
                                  } catch (e) {
                                    if (mounted) showApiError(context, e);
                                  }
                                },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
