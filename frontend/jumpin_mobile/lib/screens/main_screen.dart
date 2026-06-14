import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/support_provider.dart';
import '../providers/notification_provider.dart';
import '../models/support_message.dart';
import '../utils/app_logger.dart';
import 'home_screen.dart';
import 'requests_screen.dart';
import 'profile_screen.dart';
import 'support_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const MainScreen({super.key, required this.authProvider});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const Color _primaryColor = Color(0xFF1565C0);

  static const int _supportIndex = 3;
  static const int _notificationsIndex = 4;
  final GlobalKey<SupportScreenState> _supportKey = GlobalKey<SupportScreenState>();
  final GlobalKey<NotificationsScreenState> _notificationsKey =
      GlobalKey<NotificationsScreenState>();

  final SupportProvider _supportProvider = SupportProvider();
  bool _hasUnreadSupport = false;
  DateTime? _lastReadSupport;
  Timer? _supportPollTimer;

  final NotificationProvider _notificationProvider = NotificationProvider();
  int _unreadNotifications = 0;
  Timer? _notificationPollTimer;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(authProvider: widget.authProvider),
      RequestsScreen(authProvider: widget.authProvider),
      ProfileScreen(authProvider: widget.authProvider),
      SupportScreen(key: _supportKey, authProvider: widget.authProvider),
      NotificationsScreen(key: _notificationsKey, authProvider: widget.authProvider),
    ];

    _supportProvider.setToken(widget.authProvider.token);
    _checkUnreadSupport();
    _supportPollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkUnreadSupport(),
    );

    _notificationProvider.setToken(widget.authProvider.token);
    _checkUnreadNotifications();
    _notificationPollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkUnreadNotifications(),
    );
  }

  @override
  void dispose() {
    _supportPollTimer?.cancel();
    _notificationPollTimer?.cancel();
    super.dispose();
  }

  /// Polls the unread notification count for the bell badge.
  Future<void> _checkUnreadNotifications() async {
    if (widget.authProvider.currentUser == null) return;
    try {
      final count = await _notificationProvider.getUnreadCount();
      if (mounted && count != _unreadNotifications) {
        setState(() => _unreadNotifications = count);
      }
    } catch (e) {
      logError('Notification unread poll failed', e);
    }
  }

  /// Polls the support conversation and flags the tab when the latest message
  /// is an unread admin reply. Viewing the Support tab marks it as read.
  Future<void> _checkUnreadSupport() async {
    final userId = widget.authProvider.currentUser?.id;
    if (userId == null) return;

    List<SupportMessage> messages;
    try {
      messages = await _supportProvider.getMessages(userId: userId);
    } catch (e) {
      // Background unread poll: stay silent on failure, just skip this tick.
      logError('Support unread poll failed', e);
      return;
    }

    ChatMessage? latest;
    for (final msg in messages) {
      for (final chat in msg.chatMessages) {
        final latestTime = latest?.createdAt;
        if (latest == null ||
            (chat.createdAt != null &&
                latestTime != null &&
                chat.createdAt!.isAfter(latestTime))) {
          latest = chat;
        }
      }
    }

    // If the user is currently viewing Support, treat everything as read.
    if (_currentIndex == _supportIndex && latest != null) {
      _lastReadSupport = latest.createdAt;
    }

    final hasUnread = latest != null &&
        latest.isAdminMessage &&
        latest.createdAt != null &&
        (_lastReadSupport == null ||
            latest.createdAt!.isAfter(_lastReadSupport!));

    if (mounted && hasUnread != _hasUnreadSupport) {
      setState(() => _hasUnreadSupport = hasUnread);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == _supportIndex) {
              _hasUnreadSupport = false;
            }
            if (index == _notificationsIndex) {
              // Opening the tab marks everything read.
              _unreadNotifications = 0;
            }
          });
          if (index == _supportIndex) {
            _supportKey.currentState?.reload();
          }
          if (index == _notificationsIndex) {
            _notificationsKey.currentState?.reload();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Requests',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.support_agent),
                if (_hasUnreadSupport)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Support',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
