import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/models/request.dart';
import 'package:jumpin_admin/models/search_result.dart';
import 'package:jumpin_admin/providers/request_provider.dart';
import 'package:jumpin_admin/providers/helper_providers/utils.dart';
import 'package:jumpin_admin/widgets/detail_dialog.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  late RequestProvider _requestProvider;
  SearchResult<Request>? _requestsResult;
  bool _isLoading = true;

  String? _selectedStatus;

  int _currentPage = 1;
  int _pageSize = 50;
  final List<int> _pageSizeOptions = [50, 100, 200];

  @override
  void initState() {
    super.initState();
    _requestProvider = context.read<RequestProvider>();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      var filter = <String, dynamic>{
        'Page': _currentPage,
        'PageSize': _pageSize,
      };

      if (_selectedStatus != null) {
        filter['Status'] = _selectedStatus;
      }

      var result = await _requestProvider.get(filter: filter);

      if (mounted) {
        setState(() {
          _requestsResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Requests',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildRequestTable()),
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
            flex: 2,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Status',
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
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Accepted', child: Text('Accepted')),
                DropdownMenuItem(value: 'Declined', child: Text('Declined')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _currentPage = 1;
                _loadRequests();
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
            onPressed: () {
              _currentPage = 1;
              _loadRequests();
            },
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.bold)),
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
            onPressed: () {
              setState(() => _selectedStatus = null);
              _currentPage = 1;
              _loadRequests();
            },
            icon: const Icon(Icons.clear, size: 20),
            label: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    _loadRequests();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
      );
    }

    final requests = _requestsResult?.result;
    if (requests == null || requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No requests found',
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
                DataColumn(label: Text('Sender Email', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Receiver Email', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Ad', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
              ],
              rows: requests.asMap().entries.map((entry) {
                return _buildRequestRow(requests[entry.key], entry.key.isEven);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRequestRow(Request req, bool isEven) {
    Color statusColor;
    switch (req.status) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Accepted':
        statusColor = Colors.green;
        break;
      case 'Declined':
        statusColor = Colors.red;
        break;
      case 'Cancelled':
        statusColor = Colors.grey;
        break;
      case 'Completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return DataRow(
      color: WidgetStateProperty.all(
        isEven ? Colors.grey.withOpacity(0.02) : Colors.white,
      ),
      cells: [
        DataCell(Text(req.senderEmail ?? '-')),
        DataCell(Text(req.receiverEmail ?? '-')),
        DataCell(
          SizedBox(
            width: 220,
            child: Text(
              req.adTitle ?? '-',
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
              req.type ?? '-',
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Text(
              req.status ?? '-',
              style: TextStyle(
                color: _darkenColor(statusColor),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(formatDate(req.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF0D47A1), size: 20),
                tooltip: 'View Details',
                onPressed: () => _showRequestDetails(req),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Delete Request',
                onPressed: () => _deleteRequest(req),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    final totalCount = _requestsResult?.count ?? 0;
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
                    _loadRequests();
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
                    _loadRequests();
                  }
                : null,
          ),
          const SizedBox(width: 20),
          Text('Total: $totalCount requests', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showRequestDetails(Request req) {
    showDialog(
      context: context,
      builder: (context) {
        return DetailDialog(
          icon: Icons.swap_horiz,
          title: 'Request ${req.requestNumber ?? "#${req.id}"}',
          subtitle: req.adTitle,
          children: [
            DetailRow(icon: Icons.person, label: 'Sender', value: req.senderEmail ?? req.senderUsername),
            const DetailDivider(),
            DetailRow(icon: Icons.person_outline, label: 'Receiver', value: req.receiverEmail ?? req.receiverUsername),
            const DetailDivider(),
            DetailRow(icon: Icons.article, label: 'Ad', value: req.adTitle),
            const DetailDivider(),
            DetailRow(icon: Icons.category, label: 'Type', value: req.type),
            const DetailDivider(),
            DetailRow(
              icon: Icons.flag,
              label: 'Status',
              valueWidget: Align(
                alignment: Alignment.centerLeft,
                child: DetailBadge(text: req.status ?? '-', color: _statusColor(req.status)),
              ),
            ),
            const DetailDivider(),
            DetailRow(icon: Icons.calendar_today, label: 'Created', value: formatDateTime(req.createdAt)),
            const DetailDivider(),
            DetailRow(icon: Icons.reply, label: 'Responded', value: formatDateTime(req.respondedAt)),
            if (req.message != null && req.message!.isNotEmpty)
              DetailSection(label: 'Message', content: req.message!),
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

  Future<void> _deleteRequest(Request req) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Request'),
          content: Text('Are you sure you want to delete request ${req.requestNumber ?? "#${req.id}"}?'),
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
        await _requestProvider.delete(req.id!);
        if (context.mounted) {
          await buildSuccessAlert(context, 'Request deleted', 'The request has been deleted successfully.');
        }
        _loadRequests();
      } catch (e) {
        if (context.mounted) {
          await buildErrorAlert(context, 'Could not delete request', e.toString(), e as Exception);
        }
      }
    }
  }
}
