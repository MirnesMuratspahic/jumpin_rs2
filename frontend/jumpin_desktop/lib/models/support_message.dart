class SupportMessage {
  int? id;
  int? userId;
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
  int? respondedByAdminId;
  String? respondedByAdminUsername;

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
  });

  SupportMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    userUsername = json['userUsername'];
    userFullName = json['userFullName'];
    userEmail = json['userEmail'];
    subject = json['subject'];
    message = json['message'];
    status = json['status'];
    priority = json['priority'];
    category = json['category'];
    createdAt =
        json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null;
    respondedAt = json['respondedAt'] != null
        ? DateTime.parse(json['respondedAt'])
        : null;
    adminResponse = json['adminResponse'];
    respondedByAdminId = json['respondedByAdminId'];
    respondedByAdminUsername = json['respondedByAdminUsername'];
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
    return data;
  }
}
