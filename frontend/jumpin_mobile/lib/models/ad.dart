import 'ad_image.dart';

class Ad {
  final int id;
  final String title;
  final String? description;
  final String adType;
  final double? price;
  final String? dateAvailable;
  final String? timeAvailable;
  final String? locationFrom;
  final String? locationTo;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double? latitudeEnd;
  final double? longitudeEnd;
  final String? routeCoordinates;
  final String? carBrand;
  final String? carModel;
  final int? carYear;
  final int? carSeats;
  final String? fuelType;
  final double? apartmentArea;
  final int? apartmentRooms;
  final String? apartmentAddress;
  final String? imageUrl;
  final List<AdImage>? images;
  final bool isActive;
  final DateTime? createdAt;
  final int userId;
  final String? userName;
  final String? userProfileImage;
  final double? userRating;
  final bool isVipOwner;

  Ad({
    required this.id,
    required this.title,
    this.description,
    required this.adType,
    this.price,
    this.dateAvailable,
    this.timeAvailable,
    this.locationFrom,
    this.locationTo,
    this.location,
    this.latitude,
    this.longitude,
    this.latitudeEnd,
    this.longitudeEnd,
    this.routeCoordinates,
    this.carBrand,
    this.carModel,
    this.carYear,
    this.carSeats,
    this.fuelType,
    this.apartmentArea,
    this.apartmentRooms,
    this.apartmentAddress,
    this.imageUrl,
    this.images,
    this.isActive = true,
    this.createdAt,
    required this.userId,
    this.userName,
    this.userProfileImage,
    this.userRating,
    this.isVipOwner = false,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      adType: json['adType'] ?? 'Route',
      price: json['price']?.toDouble(),
      dateAvailable: json['dateAvailable'],
      timeAvailable: json['timeAvailable'],
      locationFrom: json['locationFrom'],
      locationTo: json['locationTo'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      latitudeEnd: json['latitudeEnd']?.toDouble(),
      longitudeEnd: json['longitudeEnd']?.toDouble(),
      routeCoordinates: json['routeCoordinates'],
      carBrand: json['carBrand'],
      carModel: json['carModel'],
      carYear: json['carYear'],
      carSeats: json['carSeats'],
      fuelType: json['fuelType'],
      apartmentArea: json['apartmentArea']?.toDouble(),
      apartmentRooms: json['apartmentRooms'],
      apartmentAddress: json['apartmentAddress'],
      imageUrl: json['imageUrl'],
      images: json['images'] != null
          ? (json['images'] as List).map((i) => AdImage.fromJson(i)).toList()
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      userId: json['userId'] ?? 0,
      userName: json['userName'],
      userProfileImage: json['userProfileImage'],
      userRating: json['userRating']?.toDouble(),
      isVipOwner: json['isVipOwner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'adType': adType,
      'price': price,
      'dateAvailable': dateAvailable,
      'timeAvailable': timeAvailable,
      'locationFrom': locationFrom,
      'locationTo': locationTo,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'latitudeEnd': latitudeEnd,
      'longitudeEnd': longitudeEnd,
      'routeCoordinates': routeCoordinates,
      'carBrand': carBrand,
      'carModel': carModel,
      'carYear': carYear,
      'carSeats': carSeats,
      'fuelType': fuelType,
      'apartmentArea': apartmentArea,
      'apartmentRooms': apartmentRooms,
      'apartmentAddress': apartmentAddress,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'userRating': userRating,
      'isVipOwner': isVipOwner,
    };
  }

  String get adTypeDisplay {
    switch (adType.toLowerCase()) {
      case 'route':
        return 'Route';
      case 'carrental':
      case 'car':
        return 'Car Rental';
      case 'apartmentrental':
      case 'apartment':
        return 'Apartment';
      default:
        return adType;
    }
  }

  String get locationDisplay {
    if (adType.toLowerCase() == 'route') {
      return '${locationFrom ?? ''} -> ${locationTo ?? ''}';
    }
    return location ?? apartmentAddress ?? '';
  }
}
