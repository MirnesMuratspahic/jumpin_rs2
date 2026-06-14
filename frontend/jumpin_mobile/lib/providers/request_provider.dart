import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/request.dart';
import '../utils/config.dart';
import '../utils/api_exception.dart';

class RequestProvider {
  static String get baseUrl => Config.apiBaseUrl;

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<List<Request>> getRequests(
      {String? senderId, String? receiverId}) async {
    try {
      var url = "$baseUrl/Request";
      final queryParams = <String>[];

      if (senderId != null) {
        queryParams.add('senderId=$senderId');
      }
      if (receiverId != null) {
        queryParams.add('receiverId=$receiverId');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      var uri = Uri.parse(url);
      var response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        List<dynamic> requestList;
        if (data is Map && data.containsKey('resultList')) {
          requestList = data['resultList'];
        } else if (data is Map && data.containsKey('result')) {
          requestList = data['result'];
        } else if (data is List) {
          requestList = data;
        } else {
          return [];
        }

        return requestList.map((json) => Request.fromJson(json)).toList();
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> sendRequest({
    required String senderId,
    required String adId,
    String? message,
  }) async {
    try {
      var url = "$baseUrl/Request";
      var uri = Uri.parse(url);

      var body = jsonEncode({
        "senderId": senderId,
        "adId": adId,
        "message": message,
      });

      var response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 200) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> acceptRequest(String id) async {
    try {
      var url = "$baseUrl/Request/$id/accept";
      var uri = Uri.parse(url);

      var response = await http.post(uri, headers: _headers);

      if (response.statusCode == 200) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> declineRequest(String id) async {
    try {
      var url = "$baseUrl/Request/$id/decline";
      var uri = Uri.parse(url);

      var response = await http.post(uri, headers: _headers);

      if (response.statusCode == 200) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }
}
