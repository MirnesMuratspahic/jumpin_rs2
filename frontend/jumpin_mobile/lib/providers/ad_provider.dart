import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ad.dart';
import '../utils/config.dart';

class AdProvider {
  static String get baseUrl => Config.apiBaseUrl;

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<List<Ad>> getAds({String? adType, String? searchQuery, int? userId, bool? isActive}) async {
    try {
      var url = "$baseUrl/Ad";
      final queryParams = <String>[];

      if (adType != null && adType.isNotEmpty) {
        queryParams.add('adType=$adType');
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams.add('search=$searchQuery');
      }
      if (userId != null) {
        queryParams.add('userId=$userId');
      }
      if (isActive != null) {
        queryParams.add('isActive=$isActive');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      var uri = Uri.parse(url);
      var response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        List<dynamic> adList;
        if (data is Map && data.containsKey('resultList')) {
          adList = data['resultList'];
        } else if (data is Map && data.containsKey('result')) {
          adList = data['result'];
        } else if (data is List) {
          adList = data;
        } else {
          return [];
        }

        return adList.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Ad?> getAdById(int id) async {
    try {
      var url = "$baseUrl/Ad/$id";
      var uri = Uri.parse(url);
      var response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return Ad.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Ad?> createAd({
    required String title,
    required String description,
    required String adType,
    required double price,
    required int userId,
    String? dateAvailable,
    String? timeAvailable,
    String? locationFrom,
    String? locationTo,
    String? location,
    double? latitude,
    double? longitude,
    double? latitudeEnd,
    double? longitudeEnd,
    String? routeCoordinates,
    String? carBrand,
    String? carModel,
    int? carYear,
    int? carSeats,
    String? fuelType,
    double? apartmentArea,
    int? apartmentRooms,
    String? apartmentAddress,
    String? imageUrl,
  }) async {
    try {
      var url = "$baseUrl/Ad";
      var uri = Uri.parse(url);

      var body = jsonEncode({
        "title": title,
        "description": description,
        "adType": adType,
        "price": price,
        "userId": userId,
        "dateAvailable": dateAvailable,
        "timeAvailable": timeAvailable,
        "locationFrom": locationFrom,
        "locationTo": locationTo,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "latitudeEnd": latitudeEnd,
        "longitudeEnd": longitudeEnd,
        "routeCoordinates": routeCoordinates,
        "carBrand": carBrand,
        "carModel": carModel,
        "carYear": carYear,
        "carSeats": carSeats,
        "fuelType": fuelType,
        "apartmentArea": apartmentArea,
        "apartmentRooms": apartmentRooms,
        "apartmentAddress": apartmentAddress,
        "imageUrl": imageUrl,
        "isActive": true,
      });

      var response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return Ad.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateAd({
    required int id,
    required String title,
    required String description,
    required String adType,
    required double price,
    String? dateAvailable,
    String? timeAvailable,
    String? locationFrom,
    String? locationTo,
    String? location,
    double? latitude,
    double? longitude,
    double? latitudeEnd,
    double? longitudeEnd,
    String? routeCoordinates,
    String? carBrand,
    String? carModel,
    int? carYear,
    int? carSeats,
    String? fuelType,
    double? apartmentArea,
    int? apartmentRooms,
    String? apartmentAddress,
    String? imageUrl,
  }) async {
    try {
      var url = "$baseUrl/Ad/$id";
      var uri = Uri.parse(url);

      var body = jsonEncode({
        "title": title,
        "description": description,
        "adType": adType,
        "price": price,
        "dateAvailable": dateAvailable,
        "timeAvailable": timeAvailable,
        "locationFrom": locationFrom,
        "locationTo": locationTo,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "latitudeEnd": latitudeEnd,
        "longitudeEnd": longitudeEnd,
        "routeCoordinates": routeCoordinates,
        "carBrand": carBrand,
        "carModel": carModel,
        "carYear": carYear,
        "carSeats": carSeats,
        "fuelType": fuelType,
        "apartmentArea": apartmentArea,
        "apartmentRooms": apartmentRooms,
        "apartmentAddress": apartmentAddress,
        "imageUrl": imageUrl,
      });

      var response = await http.put(uri, headers: _headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      var url = "$baseUrl/Ad/upload-image";
      var uri = Uri.parse(url);

      var request = http.MultipartRequest('POST', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['imageUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteAd(int id) async {
    try {
      var url = "$baseUrl/Ad/$id";
      var uri = Uri.parse(url);
      var response = await http.delete(uri, headers: _headers);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createAdImage({
    required int adId,
    required String imageUrl,
    bool isMainImage = false,
    int displayOrder = 0,
  }) async {
    try {
      var url = "$baseUrl/AdImage";
      var uri = Uri.parse(url);
      var body = jsonEncode({
        "adId": adId,
        "imageUrl": imageUrl,
        "isMainImage": isMainImage,
        "displayOrder": displayOrder,
      });
      var response = await http.post(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAdImage(int id) async {
    try {
      var url = "$baseUrl/AdImage/$id";
      var uri = Uri.parse(url);
      var response = await http.delete(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
