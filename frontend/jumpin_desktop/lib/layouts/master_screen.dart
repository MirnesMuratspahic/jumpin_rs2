import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/providers/helper_providers/auth_provider.dart';
import 'package:jumpin_admin/providers/user_provider.dart';
import 'package:jumpin_admin/screens/dashboard_screen.dart';
import 'package:jumpin_admin/screens/user_list_screen.dart';
import 'package:jumpin_admin/screens/ad_list_screen.dart';
import 'package:jumpin_admin/screens/request_list_screen.dart';
import 'package:jumpin_admin/screens/review_list_screen.dart';
import 'package:jumpin_admin/screens/support_list_screen.dart';
import 'package:jumpin_admin/screens/statistics_screen.dart';
import 'package:jumpin_admin/main.dart';

class MasterScreen extends StatefulWidget {
  final String title;
  final Widget child;

  const MasterScreen({super.key, required this.title, required this.child});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF1565C0);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _sidebarBg = Color(0xFF0A2740);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: _sidebarBg,
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF081E30),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1A3A5C), width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.directions_car, color: Color(0xFF42A5F5), size: 32),
                SizedBox(width: 12),
                Text(
                  'JumpIn Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isActive: widget.title == 'Dashboard',
                  onTap: () => _navigateTo(const DashboardScreen()),
                ),
                _buildNavItem(
                  icon: Icons.people,
                  label: 'Users',
                  isActive: widget.title == 'Users',
                  onTap: () => _navigateTo(const UserListScreen()),
                ),
                _buildNavItem(
                  icon: Icons.article,
                  label: 'Ads',
                  isActive: widget.title == 'Ads',
                  onTap: () => _navigateTo(const AdListScreen()),
                ),
                _buildNavItem(
                  icon: Icons.swap_horiz,
                  label: 'Requests',
                  isActive: widget.title == 'Requests',
                  onTap: () => _navigateTo(const RequestListScreen()),
                ),
                _buildNavItem(
                  icon: Icons.star,
                  label: 'Reviews',
                  isActive: widget.title == 'Reviews',
                  onTap: () => _navigateTo(const ReviewListScreen()),
                ),
                _buildNavItem(
                  icon: Icons.support_agent,
                  label: 'Support',
                  isActive: widget.title == 'Support',
                  onTap: () => _navigateTo(const SupportListScreen()),
                ),
                _buildNavItem(
                  icon: Icons.bar_chart,
                  label: 'Statistics',
                  isActive: widget.title == 'Statistics',
                  onTap: () => _navigateTo(const StatisticsScreen()),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1A3A5C), width: 1),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthProvider.username ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Administrator',
                        style: TextStyle(
                          color: Color(0xFF64B5F6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? _primaryDark.withOpacity(0.4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          hoverColor: _primaryDark.withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? _accent : const Color(0xFF90CAF9),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFB0BEC5),
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0D47A1)),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _handleLogout(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _handleLogout() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (context.mounted) {
        var userProvider = context.read<UserProvider>();
        userProvider.logout();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}
