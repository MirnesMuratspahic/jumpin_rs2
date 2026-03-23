class SupportMessage {
  final int? id;
  final String subject;
  final String message;
  final String? response;
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final int userId;
  final String? userName;
  final String? userEmail;

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

    return SupportMessage(
      id: json['id'],
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      response: json['response'],
      status: mapStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
      userId: json['userId'] ?? 0,
      userName: json['userName'],
      userEmail: json['userEmail'],
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
