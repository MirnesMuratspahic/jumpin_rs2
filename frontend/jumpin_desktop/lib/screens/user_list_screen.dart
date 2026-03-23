import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/models/user.dart';
import 'package:jumpin_admin/models/search_result.dart';
import 'package:jumpin_admin/providers/user_provider.dart';
import 'package:jumpin_admin/providers/helper_providers/utils.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late UserProvider _userProvider;
  SearchResult<User>? _usersResult;
  bool _isLoading = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int _currentPage = 1;
  final int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      var filter = <String, dynamic>{
        'Page': _currentPage,
        'PageSize': _pageSize,
      };

      if (_usernameController.text.isNotEmpty) {
        filter['Username'] = _usernameController.text;
      }
      if (_emailController.text.isNotEmpty) {
        filter['Email'] = _emailController.text;
      }

      var result = await _userProvider.get(filter: filter);

      if (mounted) {
        setState(() {
          _usersResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Users',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildUserTable()),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
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
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0D47A1)),
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
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Search by email...',
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0D47A1)),
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
        ],
      ),
    );
  }

  Widget _buildUserTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
      );
    }

    final users = _usersResult?.result;
    if (users == null || users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
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
              columnSpacing: 30,
              columns: const [
                DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Full Name', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('VIP', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Registered', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D47A1)))),
              ],
              rows: users.map((user) => _buildUserRow(user)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(User user) {
    return DataRow(
      cells: [
        DataCell(Text(user.username ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(user.fullName)),
        DataCell(Text(user.email ?? '')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.isBlocked
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isBlocked ? Colors.red : Colors.green,
                width: 1,
              ),
            ),
            child: Text(
              user.isBlocked ? 'Blocked' : 'Active',
              style: TextStyle(
                color: user.isBlocked ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          user.isVip == true
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text('VIP', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                )
              : const Text('-', style: TextStyle(color: Colors.grey)),
        ),
        DataCell(Text(user.roleName)),
        DataCell(Text(formatDate(user.registrationDate))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.isBlocked)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _unblockUser(user),
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('Unblock', style: TextStyle(fontSize: 12)),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _blockUser(user),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Block', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    final totalCount = _usersResult?.count ?? 0;
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
                    _loadUsers();
                  }
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Page $_currentPage of $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadUsers();
                  }
                : null,
          ),
          const SizedBox(width: 20),
          Text(
            'Total: $totalCount users',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _handleSearch() {
    _currentPage = 1;
    _loadUsers();
  }

  void _handleClear() {
    _usernameController.clear();
    _emailController.clear();
    _currentPage = 1;
    _loadUsers();
  }

  Future<void> _blockUser(User user) async {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to block "${user.username}"?'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Block Reason',
                      hintText: 'Enter the reason for blocking...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Block reason is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Block User'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _userProvider.blockUser(user.id!, reasonController.text);
        if (context.mounted) {
          await buildSuccessAlert(context, 'Success', 'User has been blocked successfully.');
        }
        _loadUsers();
      } catch (e) {
        if (context.mounted) {
          await buildErrorAlert(context, 'Error', e.toString(), e as Exception);
        }
      }
    }
  }

  Future<void> _unblockUser(User user) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unblock User'),
          content: Text('Are you sure you want to unblock "${user.username}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unblock'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _userProvider.unblockUser(user.id!);
        if (context.mounted) {
          await buildSuccessAlert(context, 'Success', 'User has been unblocked successfully.');
        }
        _loadUsers();
      } catch (e) {
        if (context.mounted) {
          await buildErrorAlert(context, 'Error', e.toString(), e as Exception);
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
