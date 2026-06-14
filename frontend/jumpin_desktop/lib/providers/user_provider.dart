import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jumpin_admin/models/user.dart';
import 'package:jumpin_admin/providers/base_provider.dart';
import 'package:jumpin_admin/providers/helper_providers/auth_provider.dart';
import 'package:jumpin_admin/utils/config.dart';
import 'dart:developer' as developer;

class UserProvider extends BaseProvider<User> {
  static String get baseUrl => Config.apiBaseUrl;

  UserProvider() : super("User");

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }

  Future<User> login(String username, String password) async {
    var url = "$baseUrl/User/login";
    var uri = Uri.parse(url);

    Map<String, String> headers = {"Content-Type": "application/json"};

    var body = jsonEncode({"email": username, "password": password});

    try {
      var response = await http.post(uri, headers: headers, body: body).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout after 10 seconds'),
      );

      developer.log('Login response: ${response.statusCode}');

      if (isValidResponse(response)) {
        var responseData = jsonDecode(response.body);
        var data = responseData['user'] ?? responseData;

        if (data['role'] != 'ADMIN') {
          throw Exception('Access denied. Admin privileges required.');
        }

        AuthProvider.username = username;
        AuthProvider.password = password;
        AuthProvider.userId = data['id'];
        AuthProvider.isAdmin = true;

        var user = fromJson(data);
        return user;
      } else {
        try {
          var errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Invalid credentials');
        } catch (e) {
          if (e is Exception && e.toString().contains('Exception:')) {
            rethrow;
          }
          throw Exception('An error occurred during login');
        }
      }
    } catch (e) {
      developer.log('Login error', error: e);
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<User> blockUser(String id, String reason) async {
    var url = "$baseUrl/User/$id/block";
    var uri = Uri.parse(url);

    var headers = createHeaders();
    var jsonRequest = jsonEncode({"reason": reason});

    try {
      var response = await http.post(uri, headers: headers, body: jsonRequest).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout after 10 seconds'),
      );

      developer.log('Block response status: ${response.statusCode}');

      if (isValidResponse(response)) {
        if (response.body.isEmpty) {
          // Backend returned empty body on success - reload user data
          throw Exception('Block successful but response is empty');
        }
        var data = jsonDecode(response.body);
        return fromJson(data);
      } else {
        if (response.body.isEmpty) {
          throw Exception('Block failed: ${response.statusCode} - No response body');
        }
        try {
          var errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Block failed (${response.statusCode})');
        } catch (e) {
          if (e is Exception && e.toString().contains('Exception:')) {
            rethrow;
          }
          throw Exception('Block failed (${response.statusCode})');
        }
      }
    } catch (e) {
      developer.log('Block error: $e');
      throw Exception('Block failed: ${e.toString()}');
    }
  }

  Future<User> unblockUser(String id) async {
    var url = "$baseUrl/User/$id/unblock";
    developer.log('Unblock user URL: $url');
    var uri = Uri.parse(url);
    var headers = createHeaders();

    try {
      var response = await http.post(uri, headers: headers).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout after 10 seconds'),
      );

      developer.log('Unblock response status: ${response.statusCode}');

      if (isValidResponse(response)) {
        if (response.body.isEmpty) {
          // Backend returned empty body on success - reload user data
          throw Exception('Unblock successful but response is empty');
        }
        var data = jsonDecode(response.body);
        return fromJson(data);
      } else {
        if (response.body.isEmpty) {
          throw Exception('Unblock failed: ${response.statusCode} - No response body');
        }
        try {
          var errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Unblock failed (${response.statusCode})');
        } catch (e) {
          if (e is Exception && e.toString().contains('Exception:')) {
            rethrow;
          }
          throw Exception('Unblock failed (${response.statusCode})');
        }
      }
    } catch (e) {
      developer.log('Unblock error: $e');
      throw Exception('Unblock failed: ${e.toString()}');
    }
  }

  void logout() {
    AuthProvider.username = null;
    AuthProvider.password = null;
    AuthProvider.userId = null;
    AuthProvider.isAdmin = false;
  }
}
