import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/request.dart';
import '../models/user.dart';
import '../providers/request_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';
import 'user_profile_screen.dart';

class RequestsScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const RequestsScreen({super.key, required this.authProvider});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _requestProvider = RequestProvider();
  List<Request> _sentRequests = [];
  List<Request> _receivedRequests = [];
  bool _isLoading = true;

  static const Color _primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _requestProvider.setToken(widget.authProvider.token);
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    final userId = widget.authProvider.currentUser?.id;
    if (userId != null) {
      try {
        // Fetch sent + received in parallel.
        final results = await Future.wait([
          _requestProvider.getRequests(senderId: userId),
          _requestProvider.getRequests(receiverId: userId),
        ]);
        setState(() {
          _sentRequests = results[0];
          _receivedRequests = results[1];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) showApiError(context, e);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(Request request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Request'),
        content: Text(
          'Accept request from ${request.senderName ?? 'Unknown'} for "${request.adTitle ?? 'Ad'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _requestProvider.acceptRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _declineRequest(Request request) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Decline request from ${request.senderName ?? 'Unknown'}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Let them know why…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final reason = reasonController.text.trim();
      await _requestProvider.declineRequest(
        request.id,
        reason: reason.isEmpty ? null : reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request declined'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _openMessageApp(Request request, bool isSent) async {
    final phoneNumber = isSent ? request.receiverPhone : request.senderPhone;
    final userName = isSent ? request.receiverName : request.senderName;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${userName ?? "User"} has not provided a phone number.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Clean phone number
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]+'), '');

      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile: open SMS app
        final String smsUrl = 'sms:$cleanPhoneNumber';
        final Uri smsUri = Uri.parse(smsUrl);

        // ignore: deprecated_member_use
        if (await canLaunchUrl(smsUri)) {
          // ignore: deprecated_member_use
          await launchUrl(smsUri);
          return;
        }
      }

      // On desktop: show phone number with copy option
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Message ${userName ?? "User"}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phone number:'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        cleanPhoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cleanPhoneNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone number copied'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy phone number',
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(Request request, bool isSent) async {
    final phoneNumber = isSent ? request.receiverPhone : request.senderPhone;
    final userName = isSent ? request.receiverName : request.senderName;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${userName ?? "User"} has not provided a phone number.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Clean phone number - remove spaces, dashes, and parentheses
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]+'), '');

      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile: open phone dialer
        final String telUrl = 'tel:$cleanPhoneNumber';
        final Uri telUri = Uri.parse(telUrl);

        // ignore: deprecated_member_use
        if (await canLaunchUrl(telUri)) {
          // ignore: deprecated_member_use
          await launchUrl(telUri);
          return;
        }
      }

      // On desktop/other platforms: show phone number with copy option
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Call ${userName ?? "User"}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phone number:'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        cleanPhoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cleanPhoneNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone number copied'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy phone number',
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Requests'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Sent (${_sentRequests.length})'),
            Tab(text: 'Received (${_receivedRequests.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(_sentRequests, isSent: true),
                _buildRequestList(_receivedRequests, isSent: false),
              ],
            ),
    );
  }

  Widget _buildRequestList(List<Request> requests, {required bool isSent}) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 250,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSent ? Icons.send : Icons.inbox,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isSent ? 'No sent requests' : 'No received requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index], isSent: isSent);
        },
      ),
    );
  }

  Widget _buildRequestCard(Request request, {required bool isSent}) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'Accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withAlpha(25), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[300],
                  child: request.senderProfileImage != null
                      ? ClipOval(
                          child: Image.network(
                            request.senderProfileImage!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.grey[600],
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent
                            ? 'To: ${request.receiverName ?? 'Unknown'}'
                            : 'From: ${request.senderName ?? 'Unknown'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.adTitle ?? 'Ad',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        request.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request.adType != null)
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Type: ${request.adType}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                if (request.message != null &&
                    request.message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.message, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.message!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Decline reason shown to the sender on declined requests.
                if (request.isDeclined &&
                    request.declineReason != null &&
                    request.declineReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: ${request.declineReason!}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (request.requestNumber != null)
                      Text(
                        '#${request.requestNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (request.createdAt != null)
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(request.createdAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),

                // Accept/Decline buttons for received pending requests
                if (!isSent && request.isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _declineRequest(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text(
                            'Decline',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptRequest(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text(
                            'Accept',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Call and message icons for accepted requests
                if (request.isAccepted) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _sendMessage(request, isSent),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.white,
                            ),
                            alignment: Alignment.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openMessageApp(request, isSent),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.message,
                              size: 16,
                              color: Colors.white,
                            ),
                            alignment: Alignment.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Review is started from the accepted request — the counterparty's
                  // profile opens with the review action (no manual ID entry).
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveReview(request, isSent),
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Leave a review'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Opens the counterparty's profile (where the review modal lives). The user id
  // is passed in the background — never typed in by the user.
  void _leaveReview(Request request, bool isSent) {
    final counterpartId = isSent ? request.receiverId : request.senderId;
    final counterpartName = isSent ? request.receiverName : request.senderName;
    final counterpartImage = isSent ? null : request.senderProfileImage;

    final parts = (counterpartName ?? '').trim().split(' ');
    final counterpart = User(
      id: counterpartId,
      firstName: parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : null,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
      profileImageUrl: counterpartImage,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          user: counterpart,
          authProvider: widget.authProvider,
        ),
      ),
    );
  }
}
