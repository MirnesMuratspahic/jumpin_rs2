class Review {
  final int? id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final int reviewerId;
  final String? reviewerName;
  final String? reviewerProfileImage;
  final int reviewedUserId;
  final String? reviewedUserName;
  final int? adId;
  final String? adTitle;

  Review({
    this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    required this.reviewerId,
    this.reviewerName,
    this.reviewerProfileImage,
    required this.reviewedUserId,
    this.reviewedUserName,
    this.adId,
    this.adTitle,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      reviewerId: json['reviewerId'] ?? 0,
      reviewerName: json['reviewerName'],
      reviewerProfileImage: json['reviewerProfileImage'],
      reviewedUserId: json['reviewedUserId'] ?? 0,
      reviewedUserName: json['reviewedUserName'],
      adId: json['adId'],
      adTitle: json['adTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerProfileImage': reviewerProfileImage,
      'reviewedUserId': reviewedUserId,
      'reviewedUserName': reviewedUserName,
      'adId': adId,
      'adTitle': adTitle,
    };
  }
}
