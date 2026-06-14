import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ad.dart';
import '../utils/config.dart';
import '../utils/api_exception.dart';

class RecommendationProvider {
  static String get baseUrl => Config.apiBaseUrl;

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<List<Ad>> getRecommendations(String userId, {int count = 10}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/Recommendation/GetRecommendations/$userId?count=$count',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }
}
