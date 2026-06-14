class ChatMessage {
  final String? id;
  final String message;
  final bool isAdminMessage;
  final DateTime? createdAt;

  ChatMessage({
    this.id,
    required this.message,
    required this.isAdminMessage,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString(),
      message: json['message'] ?? '',
      isAdminMessage: json['isAdminMessage'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class SupportMessage {
  final String? id;
  final String subject;
  final String message;
  final String? response;
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final String userId;
  final String? userName;
  final String? userEmail;
  final List<ChatMessage> chatMessages;

  SupportMessage({
    this.id,
    required this.subject,
    required this.message,
    this.response,
    this.status = 'Open',
    this.createdAt,
    this.respondedAt,
    required this.userId,
    this.userName,
    this.userEmail,
    this.chatMessages = const [],
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    String mapStatus(dynamic status) {
      if (status == null) return 'Open';

      final statusValue =
          status is int ? status : int.tryParse(status.toString());

      switch (statusValue) {
        case 0:
          return 'Open';
        case 1:
          return 'InProgress';
        case 2:
          return 'Resolved';
        case 3:
          return 'Closed';
        default:
          return status.toString();
      }
    }

    final chatJson = json['chatMessages'];
    final chatMessages = chatJson is List
        ? chatJson
            .map((c) => ChatMessage.fromJson(c as Map<String, dynamic>))
            .toList()
        : <ChatMessage>[];

    return SupportMessage(
      id: json['id']?.toString(),
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      response: json['adminResponse'] ?? json['response'],
      status: mapStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
      userId: (json['userId'] ?? '').toString(),
      userName: json['userUsername'] ?? json['userName'],
      userEmail: json['userEmail'],
      chatMessages: chatMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'message': message,
      'response': response,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
    };
  }

  bool get isResolved => status == 'Resolved' || status == 'Closed';
  bool get hasResponse => response != null && response!.isNotEmpty;
}
