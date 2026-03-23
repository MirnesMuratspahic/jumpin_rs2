import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/models/support_message.dart';
import 'package:jumpin_admin/models/search_result.dart';
import 'package:jumpin_admin/providers/support_provider.dart';
import 'package:jumpin_admin/providers/helper_providers/utils.dart';

class SupportListScreen extends StatefulWidget {
  const SupportListScreen({super.key});

  @override
  State<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends State<SupportListScreen> {
  late SupportProvider _supportProvider;
  SearchResult<SupportMessage>? _supportResult;
  bool _isLoading = true;

  String? _selectedStatus;

  int _currentPage = 1;
  final int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _supportProvider = context.read<SupportProvider>();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      var filter = <String, dynamic>{
        'Page': _currentPage,
        'PageSize': _pageSize,
      };

      if (_selectedStatus != null) {
        filter['Status'] = _selectedStatus;
      }

      var result = await _supportProvider.get(filter: filter);

      if (mounted) {
        setState(() {
          _supportResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading support messages: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Support',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildSupportTable()),
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
          const Icon(Icons.support_agent, color: Color(0xFF0D47A1), size: 24),
          const SizedBox(width: 10),
          const Text(
            'Support Tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(width: 30),
          SizedBox(
            width: 220,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                isDense: true,
              ),
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'Open', child: Text('Open')),
                DropdownMenuItem(value: 'InProgress', child: Text('In Progress')),
                DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'Closed', child: Text('Closed')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _currentPage = 1;
                _loadMessages();
              },
            ),
          ),
          const Spacer(),
          Text(
            'Total: ${_supportResult?.count ?? 0} tickets',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(130, 45),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
      );
    }

    final messages = _supportResult?.result;
    if (messages == null || messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No support messages found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0D47A1).withOpacity(0.05)),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
              ],
              rows: messages.map((msg) => _buildSupportRow(msg)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildSupportRow(SupportMessage msg) {
    Color statusColor;
    switch (msg.status) {
      case 'Open':
        statusColor = Colors.blue;
        break;
      case 'InProgress':
        statusColor = Colors.orange;
        break;
      case 'Resolved':
        statusColor = Colors.green;
        break;
      case 'Closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    Color priorityColor;
    switch (msg.priority) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      case 'Low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return DataRow(
      cells: [
        DataCell(Text(msg.userUsername ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(msg.userEmail ?? '-')),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              msg.subject ?? '-',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        DataCell(Text(msg.category ?? '-')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: priorityColor, width: 1),
            ),
            child: Text(
              msg.priority ?? '-',
              style: TextStyle(
                color: _darkenColor(priorityColor),
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
              msg.status ?? '-',
              style: TextStyle(
                color: _darkenColor(statusColor),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(formatDate(msg.createdAt))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF0D47A1), size: 20),
                tooltip: 'View & Respond',
                onPressed: () => _showMessageDialog(msg),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    final totalCount = _supportResult?.count ?? 0;
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
                    _loadMessages();
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
                    _loadMessages();
                  }
                : null,
          ),
          const SizedBox(width: 20),
          Text('Total: $totalCount tickets', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  void _showMessageDialog(SupportMessage msg) {
    final TextEditingController responseController = TextEditingController(
      text: msg.adminResponse ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.support_agent, color: Color(0xFF0D47A1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg.subject ?? 'Support Ticket',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('From', msg.userUsername),
                  _detailRow('Email', msg.userEmail),
                  _detailRow('Category', msg.category),
                  _detailRow('Priority', msg.priority),
                  _detailRow('Status', msg.status),
                  _detailRow('Date', formatDateTime(msg.createdAt)),
                  if (msg.respondedAt != null)
                    _detailRow('Responded', formatDateTime(msg.respondedAt)),
                  if (msg.respondedByAdminUsername != null)
                    _detailRow('Responded By', msg.respondedByAdminUsername),
                  const SizedBox(height: 16),
                  const Text('User Message:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(msg.message ?? 'No message content.'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Admin Response:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 8),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: responseController,
                      decoration: InputDecoration(
                        hintText: 'Type your response here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Response is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _respondToMessage(msg.id!, responseController.text);
                }
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Send Response'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF616161))),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }

  Future<void> _respondToMessage(int id, String response) async {
    try {
      await _supportProvider.respondToMessage(id, response);
      if (context.mounted) {
        await buildSuccessAlert(context, 'Success', 'Response sent successfully.');
      }
      _loadMessages();
    } catch (e) {
      if (context.mounted) {
        await buildErrorAlert(context, 'Error', e.toString(), e as Exception);
      }
    }
  }
}
