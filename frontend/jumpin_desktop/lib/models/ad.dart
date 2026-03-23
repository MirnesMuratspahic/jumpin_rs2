class Ad {
  int? id;
  String? title;
  String? description;
  String? type;
  double? price;
  String? location;
  String? address;
  String? imageUrl;
  String? status;
  int? ownerId;
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
    id = json['id'];
    title = json['title'];
    description = json['description'];
    type = json['type'];
    price = json['price']?.toDouble();
    location = json['location'];
    address = json['address'];
    imageUrl = json['imageUrl'];
    status = json['status'];
    ownerId = json['ownerId'];
    ownerUsername = json['ownerUsername'];
    ownerFullName = json['ownerFullName'];
    category = json['category'];
    capacity = json['capacity'];
    startDate =
        json['startDate'] != null ? DateTime.parse(json['startDate']) : null;
    endDate = json['endDate'] != null ? DateTime.parse(json['endDate']) : null;
    createdAt =
        json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null;
    updatedAt =
        json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null;
    averageRating = json['averageRating']?.toDouble();
    totalReviews = json['totalReviews'];
    totalRequests = json['totalRequests'];
    isPromoted = json['isPromoted'];
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
