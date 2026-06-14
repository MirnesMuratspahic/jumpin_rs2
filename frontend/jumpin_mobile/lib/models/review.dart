class Review {
  final String? id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String reviewerId;
  final String? reviewerName;
  final String? reviewerProfileImage;
  final String reviewedUserId;
  final String? reviewedUserName;
  final String? adId;
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
      id: json['id']?.toString(),
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      reviewerId: (json['reviewerId'] ?? '').toString(),
      reviewerName: json['reviewerName'],
      reviewerProfileImage: json['reviewerProfileImage'],
      reviewedUserId: (json['reviewedUserId'] ?? '').toString(),
      reviewedUserName: json['reviewedUserName'],
      adId: json['adId']?.toString(),
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

  String? get fullReviewerProfileImageUrl {
    if (reviewerProfileImage == null) return null;
    if (reviewerProfileImage!.startsWith('http')) return reviewerProfileImage;
    // Convert relative path to full URL
    return 'http://192.168.0.4:5194${reviewerProfileImage!}';
  }
}
