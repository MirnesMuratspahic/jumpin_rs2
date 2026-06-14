class SupportMessage {
  String? id;
  String? userId;
  String? userUsername;
  String? userFullName;
  String? userEmail;
  String? subject;
  String? message;
  String? status;
  String? priority;
  String? category;
  DateTime? createdAt;
  DateTime? respondedAt;
  String? adminResponse;
  String? respondedByAdminId;
  String? respondedByAdminUsername;
  List<ChatMessage>? chatMessages;

  SupportMessage({
    this.id,
    this.userId,
    this.userUsername,
    this.userFullName,
    this.userEmail,
    this.subject,
    this.message,
    this.status,
    this.priority,
    this.category,
    this.createdAt,
    this.respondedAt,
    this.adminResponse,
    this.respondedByAdminId,
    this.respondedByAdminUsername,
    this.chatMessages,
  });

  SupportMessage.fromJson(Map<String, dynamic> json) {
    id = _parseString(json['id']);
    userId = _parseString(json['userId']);
    userUsername = _parseString(json['userUsername']);
    userFullName = _parseString(json['userFullName']);
    userEmail = _parseString(json['userEmail']);
    subject = _parseString(json['subject']);
    message = _parseString(json['message']);
    status = _parseString(json['status']);
    priority = _parseString(json['priority']);
    category = _parseString(json['category']);
    createdAt = _parseDateTime(json['createdAt']);
    respondedAt = _parseDateTime(json['respondedAt']);
    adminResponse = _parseString(json['adminResponse']);
    respondedByAdminId = _parseString(json['respondedByAdminId']);
    respondedByAdminUsername = _parseString(json['respondedByAdminUsername']);
    if (json['chatMessages'] is List) {
      chatMessages = (json['chatMessages'] as List)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList();
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['userUsername'] = userUsername;
    data['userFullName'] = userFullName;
    data['userEmail'] = userEmail;
    data['subject'] = subject;
    data['message'] = message;
    data['status'] = status;
    data['priority'] = priority;
    data['category'] = category;
    data['createdAt'] = createdAt?.toIso8601String();
    data['respondedAt'] = respondedAt?.toIso8601String();
    data['adminResponse'] = adminResponse;
    data['respondedByAdminId'] = respondedByAdminId;
    data['respondedByAdminUsername'] = respondedByAdminUsername;
    if (chatMessages != null) {
      data['chatMessages'] = chatMessages!.map((msg) => msg.toJson()).toList();
    }
    return data;
  }
}

class ChatMessage {
  String? id;
  String? message;
  bool isAdminMessage;
  DateTime? createdAt;

  ChatMessage({
    this.id,
    this.message,
    this.isAdminMessage = false,
    this.createdAt,
  });

  ChatMessage.fromJson(Map<String, dynamic> json)
      : id = json['id']?.toString(),
        message = json['message']?.toString(),
        isAdminMessage = json['isAdminMessage'] ?? false,
        createdAt = _parseDateTime(json['createdAt']);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isAdminMessage': isAdminMessage,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
