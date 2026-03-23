class Review {
  int? id;
  int? rating;
  String? comment;
  DateTime? createdAt;
  int? reviewerId;
  String? reviewerUsername;
  String? reviewerFullName;
  int? reviewedUserId;
  String? reviewedUserUsername;
  String? reviewedUserFullName;
  int? adId;
  String? adTitle;

  Review({
    this.id,
    this.rating,
    this.comment,
    this.createdAt,
    this.reviewerId,
    this.reviewerUsername,
    this.reviewerFullName,
    this.reviewedUserId,
    this.reviewedUserUsername,
    this.reviewedUserFullName,
    this.adId,
    this.adTitle,
  });

  Review.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    rating = json['rating'];
    comment = json['comment'];
    createdAt =
        json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null;
    reviewerId = json['reviewerId'];
    reviewerUsername = json['reviewerUsername'];
    reviewerFullName = json['reviewerFullName'];
    reviewedUserId = json['reviewedUserId'];
    reviewedUserUsername = json['reviewedUserUsername'];
    reviewedUserFullName = json['reviewedUserFullName'];
    adId = json['adId'];
    adTitle = json['adTitle'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['rating'] = rating;
    data['comment'] = comment;
    data['createdAt'] = createdAt?.toIso8601String();
    data['reviewerId'] = reviewerId;
    data['reviewerUsername'] = reviewerUsername;
    data['reviewerFullName'] = reviewerFullName;
    data['reviewedUserId'] = reviewedUserId;
    data['reviewedUserUsername'] = reviewedUserUsername;
    data['reviewedUserFullName'] = reviewedUserFullName;
    data['adId'] = adId;
    data['adTitle'] = adTitle;
    return data;
  }
}
