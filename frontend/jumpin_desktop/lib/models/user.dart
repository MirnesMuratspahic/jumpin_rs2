class User {
  int? id;
  String? firstName;
  String? lastName;
  String? username;
  String? email;
  String? phone;
  String? profileImageUrl;
  DateTime? registrationDate;
  DateTime? lastLogin;
  String? status;
  String? blockReason;
  int? role;
  bool? isVip;
  DateTime? vipActivatedAt;
  DateTime? vipExpiresAt;
  double? averageRating;
  int? totalReviews;
  int? totalAds;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phone,
    this.profileImageUrl,
    this.registrationDate,
    this.lastLogin,
    this.status,
    this.blockReason,
    this.role,
    this.isVip,
    this.vipActivatedAt,
    this.vipExpiresAt,
    this.averageRating,
    this.totalReviews,
    this.totalAds,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    username = json['username'];
    email = json['email'];
    phone = json['phone'];
    profileImageUrl = json['profileImageUrl'];
    registrationDate = json['registrationDate'] != null
        ? DateTime.parse(json['registrationDate'])
        : null;
    lastLogin =
        json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null;
    status = json['status'];
    blockReason = json['blockReason'];
    role = json['role'];
    isVip = json['isVip'];
    vipActivatedAt = json['vipActivatedAt'] != null
        ? DateTime.parse(json['vipActivatedAt'])
        : null;
    vipExpiresAt = json['vipExpiresAt'] != null
        ? DateTime.parse(json['vipExpiresAt'])
        : null;
    averageRating = json['averageRating']?.toDouble();
    totalReviews = json['totalReviews'];
    totalAds = json['totalAds'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['username'] = username;
    data['email'] = email;
    data['phone'] = phone;
    data['profileImageUrl'] = profileImageUrl;
    data['registrationDate'] = registrationDate?.toIso8601String();
    data['lastLogin'] = lastLogin?.toIso8601String();
    data['status'] = status;
    data['blockReason'] = blockReason;
    data['role'] = role;
    data['isVip'] = isVip;
    data['vipActivatedAt'] = vipActivatedAt?.toIso8601String();
    data['vipExpiresAt'] = vipExpiresAt?.toIso8601String();
    data['averageRating'] = averageRating;
    data['totalReviews'] = totalReviews;
    data['totalAds'] = totalAds;
    return data;
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  bool get isBlocked => status == 'Blocked' || status == '1';

  String get roleName {
    switch (role) {
      case 0:
        return 'Admin';
      case 1:
        return 'User';
      default:
        return 'User';
    }
  }
}
