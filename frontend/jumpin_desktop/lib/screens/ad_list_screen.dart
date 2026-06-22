import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/models/ad.dart';
import 'package:jumpin_admin/models/search_result.dart';
import 'package:jumpin_admin/providers/ad_provider.dart';
import 'package:jumpin_admin/providers/helper_providers/utils.dart';
import 'package:jumpin_admin/widgets/detail_dialog.dart';
import 'package:jumpin_admin/services/report_service.dart';

class AdListScreen extends StatefulWidget {
  const AdListScreen({super.key});

  @override
  State<AdListScreen> createState() => _AdListScreenState();
}

class _AdListScreenState extends State<AdListScreen> {
  late AdProvider _adProvider;
  SearchResult<Ad>? _adsResult;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;

  int _currentPage = 1;
  int _pageSize = 50;
  final List<int> _pageSizeOptions = [50, 100, 200];

  @override
  void initState() {
    super.initState();
    _adProvider = context.read<AdProvider>();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);

    try {
      var filter = <String, dynamic>{
        'Page': _currentPage,
        'PageSize': _pageSize,
      };

      if (_searchController.text.isNotEmpty) {
        filter['SearchTerm'] = _searchController.text;
      }
      if (_selectedType != null) {
        filter['AdType'] = _selectedType;
      }

      var result = await _adProvider.get(filter: filter);

      if (mounted) {
        setState(() {
          _adsResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ads: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Ads',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildAdTable()),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search ads by title...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              onSubmitted: (_) => _handleSearch(),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Ad Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(value: 'CAR', child: Text('Car')),
                DropdownMenuItem(value: 'ROUTE', child: Text('Route')),
                DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment')),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
                _handleSearch();
              },
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(130, 50),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            onPressed: _handleSearch,
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 50),
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: _handleClear,
            icon: const Icon(Icons.clear, size: 20),
            label: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(140, 50),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 50),
              foregroundColor: const Color(0xFF1565C0),
              side: const BorderSide(color: Color(0xFF1565C0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _exportCsv,
            icon: const Icon(Icons.table_chart, size: 20),
            label: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: DropdownButton<int>(
              value: _pageSize,
              underline: const SizedBox(),
              items: _pageSizeOptions.map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text('$size per page', style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _pageSize = value;
                    _currentPage = 1;
                    _loadAds();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
      );
    }

    final ads = _adsResult?.result;
    if (ads == null || ads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No ads found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0D47A1)),
              headingRowHeight: 56,
              dataRowHeight: 60,
              columnSpacing: 32,
              horizontalMargin: 24,
              dividerThickness: 1,
              columns: const [
                DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Created', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
              ],
              rows: ads.asMap().entries.map((entry) {
                return _buildAdRow(ads[entry.key], entry.key.isEven);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildAdRow(Ad ad, bool isEven) {
    Color statusColor;
    switch (ad.status) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Inactive':
        statusColor = Colors.grey;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return DataRow(
      color: WidgetStateProperty.all(
        isEven ? Colors.grey.withOpacity(0.02) : Colors.white,
      ),
      cells: [
        DataCell(
          SizedBox(
            width: 280,
            child: Text(
              ad.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ad.type ?? '-',
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(ad.ownerUsername ?? '-')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Text(
              ad.status ?? '-',
              style: TextStyle(
                color: statusColor.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(formatDate(ad.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF0D47A1), size: 20),
                tooltip: 'View Details',
                onPressed: () => _showAdDetails(ad),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Delete Ad',
                onPressed: () => _deleteAd(ad),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    final totalCount = _adsResult?.count ?? 0;
    final totalPages = (totalCount / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadAds();
                  }
                : null,
          ),
          const SizedBox(width: 8),
          Text('Page $_currentPage of $totalPages', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadAds();
                  }
                : null,
          ),
          const SizedBox(width: 20),
          Text('Total: $totalCount ads', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  void _handleSearch() {
    _currentPage = 1;
    _loadAds();
  }

  void _handleClear() {
    _searchController.clear();
    setState(() => _selectedType = null);
    _currentPage = 1;
    _loadAds();
  }

  Future<void> _exportPdf() async {
    final ads = _adsResult?.result ?? [];
    if (ads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ads to export.')),
      );
      return;
    }
    final filters = <String>[];
    if (_searchController.text.isNotEmpty) filters.add('search="${_searchController.text}"');
    if (_selectedType != null) filters.add('type=$_selectedType');
    try {
      final bytes = await ReportService.buildAdsReport(
        ads,
        filterLabel: filters.isEmpty ? null : filters.join(', '),
      );
      final path = await ReportService.exportPdf(bytes, 'jumpin-ads-report');
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

  Future<void> _exportCsv() async {
    final ads = _adsResult?.result ?? [];
    if (ads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ads to export.')),
      );
      return;
    }
    try {
      final csv = ReportService.buildAdsCsv(ads);
      final path = await ReportService.exportCsv(csv, 'jumpin-ads');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate CSV: $e')),
        );
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showAdDetails(Ad ad) {
    showDialog(
      context: context,
      builder: (context) {
        return DetailDialog(
          icon: Icons.article,
          title: ad.title ?? 'Ad Details',
          subtitle: ad.type,
          children: [
            DetailRow(icon: Icons.category, label: 'Type', value: ad.type),
            const DetailDivider(),
            DetailRow(icon: Icons.payments, label: 'Price', value: formatCurrency(ad.price)),
            const DetailDivider(),
            DetailRow(
              icon: Icons.flag,
              label: 'Status',
              valueWidget: Align(
                alignment: Alignment.centerLeft,
                child: DetailBadge(text: ad.status ?? '-', color: _statusColor(ad.status)),
              ),
            ),
            const DetailDivider(),
            DetailRow(icon: Icons.location_on, label: 'Location', value: ad.location),
            const DetailDivider(),
            DetailRow(icon: Icons.person, label: 'Owner', value: ad.ownerUsername),
            const DetailDivider(),
            DetailRow(icon: Icons.calendar_today, label: 'Created', value: formatDate(ad.createdAt)),
            if (ad.description != null && ad.description!.isNotEmpty)
              DetailSection(label: 'Description', content: ad.description!),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAd(Ad ad) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Ad'),
          content: Text('Are you sure you want to delete "${ad.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _adProvider.delete(ad.id!);
        if (context.mounted) {
          await buildSuccessAlert(context, 'Ad deleted', 'The ad has been deleted successfully.');
        }
        _loadAds();
      } catch (e) {
        if (context.mounted) {
          await buildErrorAlert(context, 'Could not delete ad', e.toString(), e as Exception);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
