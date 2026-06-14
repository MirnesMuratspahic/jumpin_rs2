class Request {
  String? id;
  String? requestNumber;
  String? senderId;
  String? senderUsername;
  String? senderFullName;
  String? senderEmail;
  String? receiverId;
  String? receiverUsername;
  String? receiverFullName;
  String? receiverEmail;
  String? adId;
  String? adTitle;
  String? type;
  String? status;
  String? message;
  DateTime? createdAt;
  DateTime? respondedAt;
  String? responseMessage;
  int? numberOfPeople;
  DateTime? requestedDate;
  DateTime? requestedStartTime;
  DateTime? requestedEndTime;

  Request({
    this.id,
    this.requestNumber,
    this.senderId,
    this.senderUsername,
    this.senderFullName,
    this.senderEmail,
    this.receiverId,
    this.receiverUsername,
    this.receiverFullName,
    this.receiverEmail,
    this.adId,
    this.adTitle,
    this.type,
    this.status,
    this.message,
    this.createdAt,
    this.respondedAt,
    this.responseMessage,
    this.numberOfPeople,
    this.requestedDate,
    this.requestedStartTime,
    this.requestedEndTime,
  });

  Request.fromJson(Map<String, dynamic> json) {
    id = _parseString(json['id']);
    requestNumber = _parseString(json['requestNumber']);
    senderId = _parseString(json['senderId']);
    senderUsername = _parseString(json['senderUsername']);
    senderFullName = _parseString(json['senderFullName']);
    senderEmail = _parseString(json['senderEmail']);
    receiverId = _parseString(json['receiverId']);
    receiverUsername = _parseString(json['receiverUsername']);
    receiverFullName = _parseString(json['receiverFullName']);
    receiverEmail = _parseString(json['receiverEmail']);
    adId = _parseString(json['adId']);
    adTitle = _parseString(json['adTitle']);
    type = _parseString(json['adType'] ?? json['type']);
    status = _parseString(json['status']);
    message = _parseString(json['message']);
    createdAt = _parseDateTime(json['createdAt']);
    respondedAt = _parseDateTime(json['respondedAt']);
    responseMessage = _parseString(json['responseMessage']);
    numberOfPeople = _parseInt(json['numberOfPeople']);
    requestedDate = _parseDateTime(json['requestedDate']);
    requestedStartTime = _parseDateTime(json['requestedStartTime']);
    requestedEndTime = _parseDateTime(json['requestedEndTime']);
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
    data['requestNumber'] = requestNumber;
    data['senderId'] = senderId;
    data['senderUsername'] = senderUsername;
    data['senderFullName'] = senderFullName;
    data['senderEmail'] = senderEmail;
    data['receiverId'] = receiverId;
    data['receiverUsername'] = receiverUsername;
    data['receiverFullName'] = receiverFullName;
    data['receiverEmail'] = receiverEmail;
    data['adId'] = adId;
    data['adTitle'] = adTitle;
    data['type'] = type;
    data['status'] = status;
    data['message'] = message;
    data['createdAt'] = createdAt?.toIso8601String();
    data['respondedAt'] = respondedAt?.toIso8601String();
    data['responseMessage'] = responseMessage;
    data['numberOfPeople'] = numberOfPeople;
    data['requestedDate'] = requestedDate?.toIso8601String();
    data['requestedStartTime'] = requestedStartTime?.toIso8601String();
    data['requestedEndTime'] = requestedEndTime?.toIso8601String();
    return data;
  }
}
