import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_message.dart';
import '../utils/config.dart';

class SupportProvider {
  String get baseUrl => '${Config.apiBaseUrl}/Support';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<List<SupportMessage>> getMessages({int? userId}) async {
    try {
      var url = baseUrl;
      if (userId != null) {
        url += '?userId=$userId';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> messageList;
        if (data is Map && data.containsKey('resultList')) {
          messageList = data['resultList'];
        } else if (data is List) {
          messageList = data;
        } else {
          return [];
        }

        return messageList
            .map((json) => SupportMessage.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMessage({
    required int userId,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _headers,
        body: json.encode({
          'userId': userId,
          'subject': subject,
          'message': message,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
