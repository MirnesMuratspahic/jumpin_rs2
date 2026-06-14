class Ad {
  String? id;
  String? title;
  String? description;
  String? type;
  double? price;
  String? location;
  String? address;
  String? imageUrl;
  String? status;
  String? ownerId;
  String? ownerUsername;
  String? ownerFullName;
  String? category;
  int? capacity;
  DateTime? startDate;
  DateTime? endDate;
  DateTime? createdAt;
  DateTime? updatedAt;
  double? averageRating;
  int? totalReviews;
  int? totalRequests;
  bool? isPromoted;

  Ad({
    this.id,
    this.title,
    this.description,
    this.type,
    this.price,
    this.location,
    this.address,
    this.imageUrl,
    this.status,
    this.ownerId,
    this.ownerUsername,
    this.ownerFullName,
    this.category,
    this.capacity,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.averageRating,
    this.totalReviews,
    this.totalRequests,
    this.isPromoted,
  });

  Ad.fromJson(Map<String, dynamic> json) {
    id = _parseString(json['id']);
    title = _parseString(json['title']);
    description = _parseString(json['description']);
    type = _parseString(json['type']);
    price = _parseDouble(json['price']);
    location = _parseString(json['location']);
    address = _parseString(json['address']);
    imageUrl = _parseString(json['imageUrl']);
    status = _parseString(json['status']);
    ownerId = _parseString(json['ownerId']);
    ownerUsername = _parseString(json['ownerUsername']);
    ownerFullName = _parseString(json['ownerFullName']);
    category = _parseString(json['category']);
    capacity = _parseInt(json['capacity']);
    startDate = _parseDateTime(json['startDate']);
    endDate = _parseDateTime(json['endDate']);
    createdAt = _parseDateTime(json['createdAt']);
    updatedAt = _parseDateTime(json['updatedAt']);
    averageRating = _parseDouble(json['averageRating']);
    totalReviews = _parseInt(json['totalReviews']);
    totalRequests = _parseInt(json['totalRequests']);
    isPromoted = json['isPromoted'] as bool?;
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

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
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
    data['title'] = title;
    data['description'] = description;
    data['type'] = type;
    data['price'] = price;
    data['location'] = location;
    data['address'] = address;
    data['imageUrl'] = imageUrl;
    data['status'] = status;
    data['ownerId'] = ownerId;
    data['ownerUsername'] = ownerUsername;
    data['ownerFullName'] = ownerFullName;
    data['category'] = category;
    data['capacity'] = capacity;
    data['startDate'] = startDate?.toIso8601String();
    data['endDate'] = endDate?.toIso8601String();
    data['createdAt'] = createdAt?.toIso8601String();
    data['updatedAt'] = updatedAt?.toIso8601String();
    data['averageRating'] = averageRating;
    data['totalReviews'] = totalReviews;
    data['totalRequests'] = totalRequests;
    data['isPromoted'] = isPromoted;
    return data;
  }
}
