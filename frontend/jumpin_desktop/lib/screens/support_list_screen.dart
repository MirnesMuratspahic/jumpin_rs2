import 'dart:async';
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
  int _pageSize = 50;
  final List<int> _pageSizeOptions = [50, 100, 200];

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _supportProvider = context.read<SupportProvider>();
    _loadMessages();
    // Auto-refresh so new user messages (and the red dot) appear without manual refresh.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

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
                    _loadMessages();
                  });
                }
              },
            ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTableWidth = constraints.maxWidth * 0.8;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: minTableWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFF0D47A1).withOpacity(0.05)),
                    columnSpacing: 32,
                    horizontalMargin: 24,
                    columns: const [
                      DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                      DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                      DataColumn(label: Text('Last Message', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                    ],
                    rows: messages.map((msg) => _buildSupportRow(msg)).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime? _lastMessageDate(SupportMessage msg) {
    DateTime? last;
    if (msg.chatMessages != null) {
      for (final chat in msg.chatMessages!) {
        if (chat.createdAt != null &&
            (last == null || chat.createdAt!.isAfter(last))) {
          last = chat.createdAt;
        }
      }
    }
    return last ?? msg.respondedAt ?? msg.createdAt;
  }

  bool _hasNewUserMessage(SupportMessage msg) {
    final chats = msg.chatMessages;
    if (chats != null && chats.isNotEmpty) {
      return chats.last.isAdminMessage == false;
    }
    return msg.adminResponse == null;
  }

  DataRow _buildSupportRow(SupportMessage msg) {
    final hasNew = _hasNewUserMessage(msg);

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasNew) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(msg.userUsername ?? '-', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        DataCell(Text(msg.userEmail ?? '-')),
        DataCell(Text(formatDateTime(_lastMessageDate(msg)))),
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


  void _showMessageDialog(SupportMessage msg) {
    final TextEditingController responseController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final scrollController = ScrollController();
    Timer? dialogTimer;
    void Function(void Function())? refreshDialog;

    // Live-refresh the open chat so new user messages appear without reopening.
    Future<void> pollDialog() async {
      if (msg.id == null) return;
      try {
        final updated = await _supportProvider.getById(msg.id!);
        final newChats = updated.chatMessages ?? [];
        // Only update when there is new content; never wipe a populated thread.
        final changed = newChats.length > (msg.chatMessages?.length ?? 0);
        if (changed && refreshDialog != null) {
          refreshDialog!(() {
            msg.chatMessages = List<ChatMessage>.from(newChats);
            msg.adminResponse = updated.adminResponse;
          });
          await Future.delayed(const Duration(milliseconds: 200));
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            refreshDialog = setState;
            dialogTimer ??= Timer.periodic(
              const Duration(seconds: 4),
              (_) => pollDialog(),
            );
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.support_agent, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.subject ?? 'Support Ticket',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${msg.userUsername} (${msg.userEmail})',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 700,
                height: 500,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: msg.chatMessages?.isNotEmpty == true
                              ? msg.chatMessages!
                                  .map((chat) => _buildChatBubble(
                                    message: chat.message ?? '',
                                    isAdmin: chat.isAdminMessage,
                                    timestamp: chat.createdAt,
                                  ))
                                  .toList()
                              : [
                                  _buildChatBubble(
                                    message: msg.message ?? '',
                                    isAdmin: false,
                                    timestamp: msg.createdAt,
                                  ),
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: responseController,
                              decoration: InputDecoration(
                                hintText: 'Type your response...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              maxLines: 3,
                              minLines: 1,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Response is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final response = responseController.text;
                                responseController.clear();
                                final updatedMsg = await _respondToMessage(msg.id!, response);
                                if (updatedMsg != null && mounted) {
                                  setState(() {
                                    msg.chatMessages = List<ChatMessage>.from(updatedMsg.chatMessages ?? []);
                                    msg.adminResponse = updatedMsg.adminResponse;
                                  });
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  if (mounted && scrollController.hasClients) {
                                    scrollController.jumpTo(scrollController.position.maxScrollExtent);
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Send'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => dialogTimer?.cancel());
  }

  Widget _buildChatBubble({
    required String message,
    required bool isAdmin,
    required DateTime? timestamp,
  }) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFF0D47A1).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAdmin ? const Color(0xFF0D47A1) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin ? 'Admin Response' : 'User Message',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isAdmin ? const Color(0xFF0D47A1) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 6),
              Text(
                formatDateTime(timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<SupportMessage?> _respondToMessage(String id, String response) async {
    try {
      final updatedMsg = await _supportProvider.respondToMessage(id, response);
      if (mounted) {
        await _loadMessages();
      }
      return updatedMsg;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return null;
    }
  }
}
