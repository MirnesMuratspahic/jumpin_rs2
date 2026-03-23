import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/config.dart';

class AuthProvider extends ChangeNotifier {
  static String get baseUrl => Config.apiBaseUrl;
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null;

  String? _lastError;
  String? get lastError => _lastError;

  Future<bool> login(String username, String password) async {
    try {
      _lastError = null;
      var url = "$baseUrl/User/login";
      var uri = Uri.parse(url);

      Map<String, String> headers = {"Content-Type": "application/json"};
      var body = jsonEncode({"username": username, "password": password});

      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _currentUser = User.fromJson(data['user']);
        _token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        await prefs.setString('token', _token!);

        notifyListeners();
        return true;
      } else {
        try {
          var errorData = jsonDecode(response.body);

          if (errorData['errors'] != null &&
              errorData['errors']['UserError'] != null) {
            _lastError = errorData['errors']['UserError'][0];
          } else if (errorData['message'] != null) {
            _lastError = errorData['message'];
          } else {
            _lastError = 'Invalid username or password';
          }
        } catch (e) {
          _lastError = 'Invalid username or password';
        }
      }
      return false;
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      _lastError = 'Network error: $e';
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      _lastError = null;
      var url = "$baseUrl/User/register";
      var uri = Uri.parse(url);

      Map<String, String> headers = {"Content-Type": "application/json"};
      var body = jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "username": username,
        "email": email,
        "password": password,
        "passwordConfirmation": passwordConfirmation,
        "phone": phone,
        "role": 1,
      });

      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        return await login(username, password);
      } else {
        try {
          var errorData = jsonDecode(response.body);
          if (errorData['errors'] != null && errorData['errors']['UserError'] != null) {
            _lastError = errorData['errors']['UserError'][0];
          } else if (errorData['message'] != null) {
            _lastError = errorData['message'];
          } else {
            _lastError = 'Registration failed. Please try again.';
          }
        } catch (e) {
          _lastError = 'Registration failed. Please try again.';
        }
      }
      return false;
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      _lastError = 'Network error: $e';
      return false;
    }
  }

  Future<bool> updateProfile({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
  }) async {
    try {
      var url = "$baseUrl/User/$userId";
      var uri = Uri.parse(url);

      var body = jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "username": username,
        "email": email,
        "phone": phone,
      });

      var response = await http.put(uri, headers: authHeaders, body: body);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> activateVip() async {
    try {
      if (_currentUser == null) return false;
      var url = "$baseUrl/User/${_currentUser!.id}/activate-vip";
      var uri = Uri.parse(url);

      var response = await http.post(uri, headers: authHeaders);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createCheckoutSession() async {
    try {
      if (_currentUser == null) return null;
      var url = "$baseUrl/Payment/create-checkout-session/${_currentUser!.id}";
      var uri = Uri.parse(url);

      var response = await http.post(uri, headers: authHeaders);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('CHECKOUT ERROR: $e');
      return null;
    }
  }

  Future<void> refreshUser() async {
    try {
      if (_currentUser == null) return;
      var url = "$baseUrl/User/${_currentUser!.id}";
      var uri = Uri.parse(url);

      var response = await http.get(uri, headers: authHeaders);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));

        notifyListeners();
      }
    } catch (e) {
      debugPrint('REFRESH USER ERROR: $e');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');

    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user') || !prefs.containsKey('token')) {
      return false;
    }

    final userJson = prefs.getString('user');
    final token = prefs.getString('token');

    if (userJson != null && token != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
        _token = token;
        notifyListeners();
        return true;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  Map<String, String> get authHeaders {
    return {
      "Content-Type": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }
}
