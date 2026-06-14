import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../utils/config.dart';
import '../utils/api_exception.dart';

class NotificationProvider {
  String get baseUrl => '${Config.apiBaseUrl}/Notification';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl?PageSize=50'), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list;
        if (data is Map && data.containsKey('resultList')) {
          list = data['resultList'];
        } else if (data is List) {
          list = data;
        } else {
          return [];
        }
        return list.map((j) => NotificationItem.fromJson(j)).toList();
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/unread-count'), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['count'] ?? 0) as int;
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> markRead(String id) async {
    try {
      final response =
          await http.put(Uri.parse('$baseUrl/$id/read'), headers: _headers);
      if (response.statusCode == 200) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> markAllRead() async {
    try {
      final response =
          await http.put(Uri.parse('$baseUrl/read-all'), headers: _headers);
      if (response.statusCode == 200) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }
}
