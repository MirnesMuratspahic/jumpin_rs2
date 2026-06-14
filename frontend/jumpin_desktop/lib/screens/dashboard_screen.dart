import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/providers/user_provider.dart';
import 'package:jumpin_admin/providers/ad_provider.dart';
import 'package:jumpin_admin/providers/request_provider.dart';
import 'package:jumpin_admin/providers/review_provider.dart';
import 'package:jumpin_admin/providers/support_provider.dart';
import 'package:jumpin_admin/screens/user_list_screen.dart';
import 'package:jumpin_admin/screens/ad_list_screen.dart';
import 'package:jumpin_admin/screens/request_list_screen.dart';
import 'package:jumpin_admin/screens/review_list_screen.dart';
import 'package:jumpin_admin/screens/support_list_screen.dart';
import 'package:jumpin_admin/screens/statistics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalAds = 0;
  int _totalRequests = 0;
  int _totalReviews = 0;
  int _totalSupport = 0;
  int _vipUsers = 0;
  int _activeAds = 0;
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final adProvider = context.read<AdProvider>();
      final requestProvider = context.read<RequestProvider>();
      final reviewProvider = context.read<ReviewProvider>();
      final supportProvider = context.read<SupportProvider>();

      final results = await Future.wait([
        userProvider.get().catchError((_) => throw _),
        adProvider.get().catchError((_) => throw _),
        requestProvider.get().catchError((_) => throw _),
        reviewProvider.get().catchError((_) => throw _),
        supportProvider.get().catchError((_) => throw _),
      ].map((f) => f.catchError((_) => null)));

      if (mounted) {
        setState(() {
          if (results[0] != null) {
            _totalUsers = results[0]!.count ?? results[0]!.result?.length ?? 0;
            _vipUsers = results[0]!.result?.cast<dynamic>().where((u) => u.isVip == true).length ?? 0;
          }
          if (results[1] != null) {
            _totalAds = results[1]!.count ?? results[1]!.result?.length ?? 0;
            _activeAds = results[1]!.result?.cast<dynamic>().where((a) => a.status == 'Active').length ?? 0;
          }
          if (results[2] != null) {
            _totalRequests = results[2]!.count ?? results[2]!.result?.length ?? 0;
            _pendingRequests = results[2]!.result?.cast<dynamic>().where((r) => r.status == 'Pending').length ?? 0;
          }
          if (results[3] != null) {
            _totalReviews = results[3]!.count ?? results[3]!.result?.length ?? 0;
          }
          if (results[4] != null) {
            _totalSupport = results[4]!.count ?? results[4]!.result?.length ?? 0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Dashboard',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D47A1),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to JumpIn Admin',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here is an overview of the platform activity.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildStatCards(),
                    const SizedBox(height: 30),
                    _buildQuickActions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Users',
                value: _totalUsers.toString(),
                icon: Icons.people,
                color: const Color(0xFF1565C0),
                subtitle: '$_vipUsers VIP users',
                onTap: () => _navigateTo(const UserListScreen()),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                title: 'Active Ads',
                value: _activeAds.toString(),
                icon: Icons.article,
                color: const Color(0xFF2E7D32),
                subtitle: '$_totalAds total ads',
                onTap: () => _navigateTo(const AdListScreen()),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Requests',
                value: _pendingRequests.toString(),
                icon: Icons.swap_horiz,
                color: const Color(0xFFE65100),
                subtitle: '$_totalRequests total requests',
                onTap: () => _navigateTo(const RequestListScreen()),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                title: 'VIP Users',
                value: _vipUsers.toString(),
                icon: Icons.workspace_premium,
                color: const Color(0xFF6A1B9A),
                subtitle: 'Premium members',
                onTap: () => _navigateTo(const UserListScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Reviews',
                value: _totalReviews.toString(),
                icon: Icons.star,
                color: const Color(0xFFF9A825),
                subtitle: 'User feedback',
                onTap: () => _navigateTo(const ReviewListScreen()),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                title: 'Support Messages',
                value: _totalSupport.toString(),
                icon: Icons.support_agent,
                color: const Color(0xFF00838F),
                subtitle: 'Tickets to handle',
                onTap: () => _navigateTo(const SupportListScreen()),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                title: 'Total Ads',
                value: _totalAds.toString(),
                icon: Icons.campaign,
                color: const Color(0xFF4527A0),
                subtitle: '$_activeAds currently active',
                onTap: () => _navigateTo(const AdListScreen()),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                title: 'Total Requests',
                value: _totalRequests.toString(),
                icon: Icons.inbox,
                color: const Color(0xFF37474F),
                subtitle: '$_pendingRequests pending',
                onTap: () => _navigateTo(const RequestListScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.people,
                    label: 'Manage Users',
                    color: const Color(0xFF1565C0),
                    onTap: () => _navigateTo(const UserListScreen()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.article,
                    label: 'View Ads',
                    color: const Color(0xFF2E7D32),
                    onTap: () => _navigateTo(const AdListScreen()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Handle Requests',
                    color: const Color(0xFFE65100),
                    onTap: () => _navigateTo(const RequestListScreen()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.bar_chart,
                    label: 'View Statistics',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => _navigateTo(const StatisticsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
}
