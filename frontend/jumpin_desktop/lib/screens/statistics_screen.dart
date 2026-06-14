import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/providers/statistics_provider.dart';
import 'package:jumpin_admin/services/report_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsProvider _statsProvider = StatisticsProvider();

  bool _isLoading = true;
  Map<String, dynamic> _overviewData = {};
  Map<String, dynamic> _adStats = {};
  Map<String, dynamic> _requestStats = {};
  Map<String, dynamic> _userStats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _statsProvider.getOverview().catchError((_) => <String, dynamic>{}),
        _statsProvider.getAdStatistics().catchError((_) => <String, dynamic>{}),
        _statsProvider.getRequestStatistics().catchError((_) => <String, dynamic>{}),
        _statsProvider.getUserStatistics().catchError((_) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _overviewData = results[0];
          _adStats = results[1];
          _requestStats = results[2];
          _userStats = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      // The provider returns the full statistics object on each call, so any
      // of the maps holds every key; merge to be safe.
      final merged = <String, dynamic>{
        ..._overviewData,
        ..._adStats,
        ..._requestStats,
        ..._userStats,
      };
      final bytes = await ReportService.buildStatisticsReport(merged);
      final path = await ReportService.exportPdf(bytes, 'jumpin-statistics-report');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Statistics',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 30),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildAdTypePieChart()),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: _buildRequestStatusBarChart()),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildUserStatsCard()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildPlatformHealthCard()),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalUsers = _overviewData['totalUsers'] ?? _userStats['totalUsers'] ?? 0;
    final totalAds = _overviewData['totalAds'] ?? _adStats['totalAds'] ?? 0;
    final totalRequests = _overviewData['totalRequests'] ?? _requestStats['totalRequests'] ?? 0;
    final totalReviews = _overviewData['totalReviews'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Users',
            totalUsers.toString(),
            Icons.people,
            const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildSummaryCard(
            'Total Ads',
            totalAds.toString(),
            Icons.article,
            const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildSummaryCard(
            'Total Requests',
            totalRequests.toString(),
            Icons.swap_horiz,
            const Color(0xFFE65100),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildSummaryCard(
            'Total Reviews',
            totalReviews.toString(),
            Icons.star,
            const Color(0xFFF9A825),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
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
                Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 24),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypePieChart() {
    final adByType = _adStats['adsByType'] as Map<String, dynamic>? ?? {};

    final routes = (adByType['Route'] ?? adByType['route'] ?? 0).toDouble();
    final cars = (adByType['Car'] ?? adByType['car'] ?? 0).toDouble();
    final apartments = (adByType['Apartment'] ?? adByType['apartment'] ?? 0).toDouble();

    final total = routes + cars + apartments;

    final List<PieChartSectionData> sections = [];
    final List<_LegendItem> legendItems = [];

    if (routes > 0) {
      sections.add(PieChartSectionData(
        value: routes,
        title: '${(routes / total * 100).toStringAsFixed(0)}%',
        color: const Color(0xFF1565C0),
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ));
      legendItems.add(_LegendItem('Routes', const Color(0xFF1565C0), routes.toInt()));
    }
    if (cars > 0) {
      sections.add(PieChartSectionData(
        value: cars,
        title: '${(cars / total * 100).toStringAsFixed(0)}%',
        color: const Color(0xFF2E7D32),
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ));
      legendItems.add(_LegendItem('Cars', const Color(0xFF2E7D32), cars.toInt()));
    }
    if (apartments > 0) {
      sections.add(PieChartSectionData(
        value: apartments,
        title: '${(apartments / total * 100).toStringAsFixed(0)}%',
        color: const Color(0xFFE65100),
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ));
      legendItems.add(_LegendItem('Apartments', const Color(0xFFE65100), apartments.toInt()));
    }

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        title: 'N/A',
        color: Colors.grey[300]!,
        radius: 80,
        titleStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
      ));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ads by Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...legendItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(
                    item.count.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStatusBarChart() {
    final statusData = _requestStats['requestsByStatus'] as Map<String, dynamic>? ?? {};

    final pending = (statusData['Pending'] ?? statusData['pending'] ?? 0).toDouble();
    final accepted = (statusData['Accepted'] ?? statusData['accepted'] ?? 0).toDouble();
    final declined = (statusData['Declined'] ?? statusData['declined'] ?? 0).toDouble();
    final completed = (statusData['Completed'] ?? statusData['completed'] ?? 0).toDouble();
    final cancelled = (statusData['Cancelled'] ?? statusData['cancelled'] ?? 0).toDouble();

    final maxY = [pending, accepted, declined, completed, cancelled]
        .reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requests by Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY * 1.2 : 10,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final labels = ['Pending', 'Accepted', 'Declined', 'Completed', 'Cancelled'];
                        return BarTooltipItem(
                          '${labels[groupIndex]}: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Pending', 'Accepted', 'Declined', 'Completed', 'Cancelled'];
                          if (value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarGroup(0, pending, Colors.orange),
                    _makeBarGroup(1, accepted, Colors.green),
                    _makeBarGroup(2, declined, Colors.red),
                    _makeBarGroup(3, completed, const Color(0xFF1565C0)),
                    _makeBarGroup(4, cancelled, Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatsCard() {
    final activeUsers = _userStats['activeUsers'] ?? 0;
    final blockedUsers = _userStats['blockedUsers'] ?? 0;
    final vipUsers = _userStats['vipUsers'] ?? 0;
    final newUsersThisMonth = _userStats['newUsersThisMonth'] ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatRow('Active Users', activeUsers.toString(), Colors.green),
            const Divider(height: 20),
            _buildStatRow('Blocked Users', blockedUsers.toString(), Colors.red),
            const Divider(height: 20),
            _buildStatRow('VIP Members', vipUsers.toString(), Colors.amber),
            const Divider(height: 20),
            _buildStatRow('New This Month', newUsersThisMonth.toString(), const Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformHealthCard() {
    final avgRating = _overviewData['averageRating'] ?? 0.0;
    final responseRate = _overviewData['supportResponseRate'] ?? 0.0;
    final adCompletionRate = _overviewData['adCompletionRate'] ?? 0.0;
    final requestAcceptRate = _overviewData['requestAcceptRate'] ?? 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Health',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatRow(
              'Average Rating',
              '${(avgRating is num ? avgRating.toDouble() : 0.0).toStringAsFixed(1)} / 5.0',
              const Color(0xFFF9A825),
            ),
            const Divider(height: 20),
            _buildStatRow(
              'Support Response Rate',
              '${(responseRate is num ? responseRate.toDouble() : 0.0).toStringAsFixed(0)}%',
              const Color(0xFF00838F),
            ),
            const Divider(height: 20),
            _buildStatRow(
              'Ad Completion Rate',
              '${(adCompletionRate is num ? adCompletionRate.toDouble() : 0.0).toStringAsFixed(0)}%',
              const Color(0xFF2E7D32),
            ),
            const Divider(height: 20),
            _buildStatRow(
              'Request Accept Rate',
              '${(requestAcceptRate is num ? requestAcceptRate.toDouble() : 0.0).toStringAsFixed(0)}%',
              const Color(0xFF6A1B9A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final int count;

  _LegendItem(this.label, this.color, this.count);
}
