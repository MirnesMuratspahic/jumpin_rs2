class User {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final DateTime? registrationDate;
  final DateTime? lastLogin;
  final String? status;
  final String? blockReason;
  final String? role;
  final bool isVip;
  final DateTime? vipActivatedAt;
  final DateTime? vipExpiresAt;
  final bool vipCancelAtPeriodEnd;
  final double? averageRating;
  final int? totalReviews;
  final int? totalAds;

  User({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.profileImageUrl,
    this.registrationDate,
    this.lastLogin,
    this.status,
    this.blockReason,
    this.role,
    this.isVip = false,
    this.vipActivatedAt,
    this.vipExpiresAt,
    this.vipCancelAtPeriodEnd = false,
    this.averageRating,
    this.totalReviews,
    this.totalAds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'] ?? json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      status: json['status'],
      blockReason: json['blockReason'],
      role: json['role']?.toString(),
      isVip: json['isVip'] ?? false,
      vipActivatedAt: json['vipActivatedAt'] != null
          ? DateTime.parse(json['vipActivatedAt'])
          : null,
      vipExpiresAt: json['vipExpiresAt'] != null
          ? DateTime.parse(json['vipExpiresAt'])
          : null,
      vipCancelAtPeriodEnd: json['vipCancelAtPeriodEnd'] ?? false,
      averageRating: json['averageRating']?.toDouble(),
      totalReviews: json['totalReviews'],
      totalAds: json['totalAds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'registrationDate': registrationDate?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'status': status,
      'blockReason': blockReason,
      'role': role,
      'isVip': isVip,
      'vipActivatedAt': vipActivatedAt?.toIso8601String(),
      'vipExpiresAt': vipExpiresAt?.toIso8601String(),
      'vipCancelAtPeriodEnd': vipCancelAtPeriodEnd,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalAds': totalAds,
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return email ?? 'User';
  }

  String? get fullProfileImageUrl {
    if (profileImageUrl == null) return null;
    if (profileImageUrl!.startsWith('http')) return profileImageUrl;
    // Convert relative path to full URL
    return 'http://192.168.0.4:5194${profileImageUrl!}';
  }
}
