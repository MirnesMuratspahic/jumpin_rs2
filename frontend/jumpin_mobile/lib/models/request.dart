class Request {
  final int id;
  final String? requestNumber;
  final int senderId;
  final String? senderName;
  final String? senderEmail;
  final String? senderProfileImage;
  final int receiverId;
  final String? receiverName;
  final int adId;
  final String? adTitle;
  final String? adType;
  final String status;
  final String? message;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  Request({
    required this.id,
    this.requestNumber,
    required this.senderId,
    this.senderName,
    this.senderEmail,
    this.senderProfileImage,
    required this.receiverId,
    this.receiverName,
    required this.adId,
    this.adTitle,
    this.adType,
    required this.status,
    this.message,
    this.createdAt,
    this.respondedAt,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    String mapStatus(dynamic status) {
      if (status == null) return 'Pending';

      // Handle integer status
      final statusValue =
          status is int ? status : int.tryParse(status.toString());

      if (statusValue != null) {
        switch (statusValue) {
          case 0:
            return 'Pending';
          case 1:
            return 'Accepted';
          case 2:
            return 'Declined';
        }
      }

      // Handle string status (case-insensitive)
      final statusStr = status.toString().toUpperCase();
      switch (statusStr) {
        case 'PENDING':
          return 'Pending';
        case 'ACCEPTED':
          return 'Accepted';
        case 'DECLINED':
          return 'Declined';
        default:
          return status.toString();
      }
    }

    return Request(
      id: json['id'],
      requestNumber: json['requestNumber'],
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'],
      senderEmail: json['senderEmail'],
      senderProfileImage: json['senderProfileImage'],
      receiverId: json['receiverId'] ?? 0,
      receiverName: json['receiverName'],
      adId: json['adId'] ?? 0,
      adTitle: json['adTitle'],
      adType: json['adType'],
      status: mapStatus(json['status']),
      message: json['message'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestNumber': requestNumber,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderProfileImage': senderProfileImage,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'adId': adId,
      'adTitle': adTitle,
      'adType': adType,
      'status': status,
      'message': message,
      'createdAt': createdAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'Pending';
  bool get isAccepted => status == 'Accepted';
  bool get isDeclined => status == 'Declined';
}
