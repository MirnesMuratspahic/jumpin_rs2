class Review {
  String? id;
  int? rating;
  String? comment;
  DateTime? createdAt;
  String? reviewerId;
  String? reviewerEmail;
  String? reviewedUserId;
  String? reviewedUserEmail;
  String? adId;
  String? adTitle;

  Review({
    this.id,
    this.rating,
    this.comment,
    this.createdAt,
    this.reviewerId,
    this.reviewerEmail,
    this.reviewedUserId,
    this.reviewedUserEmail,
    this.adId,
    this.adTitle,
  });

  Review.fromJson(Map<String, dynamic> json) {
    id = _parseString(json['id']);
    rating = _parseInt(json['rating']);
    comment = _parseString(json['comment']);
    createdAt = _parseDateTime(json['createdAt']);
    reviewerId = _parseString(json['reviewerId']);
    reviewerEmail = _parseString(json['reviewerEmail']);
    reviewedUserId = _parseString(json['reviewedUserId']);
    reviewedUserEmail = _parseString(json['reviewedUserEmail']);
    adId = _parseString(json['adId']);
    adTitle = _parseString(json['adTitle']);
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
    data['rating'] = rating;
    data['comment'] = comment;
    data['createdAt'] = createdAt?.toIso8601String();
    data['reviewerId'] = reviewerId;
    data['reviewerEmail'] = reviewerEmail;
    data['reviewedUserId'] = reviewedUserId;
    data['reviewedUserEmail'] = reviewedUserEmail;
    data['adId'] = adId;
    data['adTitle'] = adTitle;
    return data;
  }
}
