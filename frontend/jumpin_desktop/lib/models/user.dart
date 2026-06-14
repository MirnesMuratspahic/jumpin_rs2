class User {
  String? id;
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
  String? role;
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
    try {
      id = _parseString(json['id']);
      firstName = _parseString(json['firstName']);
      lastName = _parseString(json['lastName']);
      username = _parseString(json['username']);
      email = _parseString(json['email']);
      phone = _parseString(json['phone']);
      profileImageUrl = _parseString(json['profileImageUrl']);
      registrationDate = _parseDateTime(json['registrationDate']);
      lastLogin = _parseDateTime(json['lastLogin']);
      status = _parseString(json['status']);
      blockReason = _parseString(json['blockReason']);
      role = _parseString(json['role']);
      isVip = _parseBool(json['isVip']);
      vipActivatedAt = _parseDateTime(json['vipActivatedAt']);
      vipExpiresAt = _parseDateTime(json['vipExpiresAt']);
      averageRating = _parseDouble(json['averageRating']);
      totalReviews = _parseInt(json['totalReviews']);
      totalAds = _parseInt(json['totalAds']);
    } catch (e) {
      throw Exception('Error parsing User from JSON: $e\nJSON: $json');
    }
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

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
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

  bool get isBlocked => status?.toUpperCase() == 'BLOCKED' || status == '1';

  String get roleName {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'CUSTOMER':
        return 'User';
      default:
        return 'User';
    }
  }
}
