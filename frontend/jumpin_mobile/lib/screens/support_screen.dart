import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/support_message.dart';
import '../providers/support_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class SupportScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const SupportScreen({super.key, required this.authProvider});

  @override
  State<SupportScreen> createState() => SupportScreenState();
}

class SupportScreenState extends State<SupportScreen> {
  final _supportProvider = SupportProvider();
  List<SupportMessage> _messages = [];
  bool _isLoading = true;
  final _messageController = TextEditingController();
  bool _isSending = false;
  Timer? _pollTimer;

  static const Color _primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _supportProvider.setToken(widget.authProvider.token);
    _loadMessages();
    // Live-refresh the chat so admin replies appear while the screen is open.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMessages();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  /// Reloads the chat. Called when the Support tab becomes active again.
  void reload() => _loadMessages();

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    final userId = widget.authProvider.currentUser?.id;
    if (userId != null) {
      try {
        final messages = await _supportProvider.getMessages(userId: userId);
        if (!mounted) return;
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        // Don't interrupt with a SnackBar (or force logout) on the 5s poll;
        // only surface errors on an explicit/foreground load.
        if (silent) {
          logError('Support poll failed', e);
        } else {
          showApiError(context, e);
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _supportProvider.sendMessage(
        userId: widget.authProvider.currentUser?.id ?? '',
        subject: 'Support',
        message: _messageController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _messageController.clear();
        _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        showApiError(context, e);
      }
    }
  }

  List<Widget> _buildChatBubbles() {
    final bubbles = <Widget>[];

    for (final msg in _messages) {
      if (msg.chatMessages.isNotEmpty) {
        for (final chat in msg.chatMessages) {
          bubbles.add(_buildBubble(
            text: chat.message,
            isAdmin: chat.isAdminMessage,
            time: chat.createdAt,
          ));
        }
      } else {
        bubbles.add(_buildBubble(
          text: msg.message,
          isAdmin: false,
          time: msg.createdAt,
        ));
        if (msg.hasResponse) {
          bubbles.add(_buildBubble(
            text: msg.response!,
            isAdmin: true,
            time: msg.respondedAt,
          ));
        }
      }
    }

    return bubbles;
  }

  Widget _buildBubble({
    required String text,
    required bool isAdmin,
    required DateTime? time,
  }) {
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.grey[200] : _primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isAdmin) ...[
              const Text(
                'Support Team',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            SelectableText(
              text,
              style: TextStyle(
                color: isAdmin ? Colors.black87 : Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, HH:mm').format(time ?? DateTime.now()),
              style: TextStyle(
                color: isAdmin ? Colors.grey[600] : Colors.white.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: _primaryColor,
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No messages yet. Send a message to start chatting with support.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildChatBubbles(),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        maxLength: 500,
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: (_isSending || _messageController.text.trim().isEmpty) ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                      color: _primaryColor,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Text(
                      '${_messageController.text.length}/500',
                      style: TextStyle(
                        fontSize: 12,
                        color: _messageController.text.length > 500
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
