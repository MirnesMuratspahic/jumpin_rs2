class Request {
  int? id;
  String? requestNumber;
  int? senderId;
  String? senderUsername;
  String? senderFullName;
  int? receiverId;
  String? receiverUsername;
  String? receiverFullName;
  int? adId;
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
    this.receiverId,
    this.receiverUsername,
    this.receiverFullName,
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
    id = json['id'];
    requestNumber = json['requestNumber'];
    senderId = json['senderId'];
    senderUsername = json['senderUsername'];
    senderFullName = json['senderFullName'];
    receiverId = json['receiverId'];
    receiverUsername = json['receiverUsername'];
    receiverFullName = json['receiverFullName'];
    adId = json['adId'];
    adTitle = json['adTitle'];
    type = json['type'];
    status = json['status'];
    message = json['message'];
    createdAt =
        json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null;
    respondedAt = json['respondedAt'] != null
        ? DateTime.parse(json['respondedAt'])
        : null;
    responseMessage = json['responseMessage'];
    numberOfPeople = json['numberOfPeople'];
    requestedDate = json['requestedDate'] != null
        ? DateTime.parse(json['requestedDate'])
        : null;
    requestedStartTime = json['requestedStartTime'] != null
        ? DateTime.parse(json['requestedStartTime'])
        : null;
    requestedEndTime = json['requestedEndTime'] != null
        ? DateTime.parse(json['requestedEndTime'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['requestNumber'] = requestNumber;
    data['senderId'] = senderId;
    data['senderUsername'] = senderUsername;
    data['senderFullName'] = senderFullName;
    data['receiverId'] = receiverId;
    data['receiverUsername'] = receiverUsername;
    data['receiverFullName'] = receiverFullName;
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
