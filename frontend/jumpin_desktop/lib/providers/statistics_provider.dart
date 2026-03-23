import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jumpin_admin/providers/helper_providers/auth_provider.dart';
import 'package:jumpin_admin/utils/config.dart';

class StatisticsProvider {
  static String get _baseUrl => '${Config.apiBaseUrl}/Statistics';

  Map<String, String> createHeaders() {
    String username = AuthProvider.username ?? "";
    String password = AuthProvider.password ?? "";

    String basicAuth =
        "Basic ${base64Encode(utf8.encode('$username:$password'))}";

    return {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };
  }

  bool isValidResponse(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<Map<String, dynamic>> getOverview() async {
    var url = "$_baseUrl/overview";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load statistics overview');
    }
  }

  Future<Map<String, dynamic>> getAdStatistics() async {
    var url = "$_baseUrl/ads";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load ad statistics');
    }
  }

  Future<Map<String, dynamic>> getRequestStatistics() async {
    var url = "$_baseUrl/requests";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load request statistics');
    }
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    var url = "$_baseUrl/users";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user statistics');
    }
  }

  Future<Map<String, dynamic>> getReviewStatistics() async {
    var url = "$_baseUrl/reviews";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load review statistics');
    }
  }
}
