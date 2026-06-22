import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/config.dart';
import '../utils/app_logger.dart';

class AuthProvider extends ChangeNotifier {
  static String get baseUrl => Config.apiBaseUrl;
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null;

  String? _lastError;
  String? get lastError => _lastError;

  Future<bool> login(String email, String password) async {
    try {
      _lastError = null;
      var url = "$baseUrl/User/login";
      var uri = Uri.parse(url);

      Map<String, String> headers = {"Content-Type": "application/json"};
      var body = jsonEncode({"email": email, "password": password});

      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _currentUser = User.fromJson(data['user']);
        _token = data['token'];

        logDebug('Login successful');

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
      logError('Login failed', e);
      _lastError = 'Could not reach the server. Please try again.';
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
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
        "email": email,
        "password": password,
        "passwordConfirmation": passwordConfirmation,
        "phone": phone,
      });

      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        return await login(email, password);
      } else {
        try {
          var errorData = jsonDecode(response.body);
          if (errorData['errors'] != null &&
              errorData['errors']['UserError'] != null) {
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
      logError('Register failed', e);
      _lastError = 'Could not reach the server. Please try again.';
      return false;
    }
  }

  Future<bool> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      var url = "$baseUrl/User/$userId";
      var uri = Uri.parse(url);

      var body = jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
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

  // Requests an SMS verification code for the current user's phone number.
  Future<bool> sendPhoneCode() async {
    try {
      if (_currentUser == null) return false;
      final uri = Uri.parse("$baseUrl/User/${_currentUser!.id}/send-phone-code");
      final response = await http.post(uri, headers: authHeaders);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Confirms the code. Returns null on success, or an error message to show.
  Future<String?> verifyPhone(String code) async {
    try {
      if (_currentUser == null) return "You are not logged in.";
      final uri = Uri.parse("$baseUrl/User/${_currentUser!.id}/verify-phone");
      final response = await http.post(uri,
          headers: authHeaders, body: jsonEncode({"code": code}));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));
        notifyListeners();
        return null;
      }
      try {
        return jsonDecode(response.body)['message']?.toString() ??
            "Verification failed.";
      } catch (_) {
        return "Verification failed.";
      }
    } catch (e) {
      return "Could not verify the code. Please try again.";
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
      logError('Create checkout session failed', e);
      return null;
    }
  }

  /// Starts an in-app subscription: returns the PaymentIntent client secret +
  /// publishable key for the Stripe PaymentSheet.
  Future<Map<String, dynamic>?> createSubscription() async {
    try {
      if (_currentUser == null) return null;
      final response = await http.post(
        Uri.parse("$baseUrl/Payment/create-subscription/${_currentUser!.id}"),
        headers: authHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      logError('Create subscription failed', e);
      return null;
    }
  }

  /// Confirms the subscription server-side after the PaymentSheet succeeds.
  Future<bool> confirmSubscription() async {
    try {
      if (_currentUser == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/Payment/confirm-subscription/${_currentUser!.id}"),
        headers: authHeaders,
      );
      if (response.statusCode == 200) {
        await refreshUser();
        return true;
      }
      return false;
    } catch (e) {
      logError('Confirm subscription failed', e);
      return false;
    }
  }

  /// Cancels at period end: VIP stays until it expires, then does not renew.
  Future<bool> cancelSubscription() async {
    try {
      if (_currentUser == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/Payment/cancel-subscription/${_currentUser!.id}"),
        headers: authHeaders,
      );
      if (response.statusCode == 200) {
        await refreshUser();
        return true;
      }
      return false;
    } catch (e) {
      logError('Cancel subscription failed', e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      if (_currentUser == null) return null;
      final response = await http.get(
        Uri.parse("$baseUrl/Payment/status/${_currentUser!.id}"),
        headers: authHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
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

        logDebug('Refreshed current user');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));

        notifyListeners();
      }
    } catch (e) {
      logError('Refresh user failed', e);
    }
  }

  /// Requests a password-reset code be emailed. Always reports success (the
  /// backend never reveals whether the email exists).
  Future<void> requestPasswordReset(String email) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/User/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
    } catch (e) {
      logError('Request password reset failed', e);
    }
  }

  /// Resets the password using the emailed code. Returns null on success or an
  /// error message.
  Future<String?> resetPassword(
      String email, String code, String newPassword, String confirmNewPassword) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/User/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "code": code,
          "newPassword": newPassword,
          "confirmNewPassword": confirmNewPassword,
        }),
      );

      if (response.statusCode == 200) return null;

      try {
        final data = jsonDecode(response.body);
        if (data['errors']?['UserError'] != null) {
          return data['errors']['UserError'][0];
        }
        return data['message'] ?? 'Could not reset password.';
      } catch (_) {
        return 'Could not reset password.';
      }
    } catch (e) {
      logError('Reset password failed', e);
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<void> logout() async {
    // Invalidate the token server-side (best-effort), then clear local state.
    try {
      if (_token != null && _currentUser != null) {
        await http.post(Uri.parse("$baseUrl/User/logout"), headers: authHeaders);
      }
    } catch (e) {
      logError('Server logout failed', e);
    }

    _currentUser = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');

    notifyListeners();
  }

  /// Changes the current user's password. Returns null on success, or an error
  /// message. On success it re-authenticates to get a fresh token (the old one
  /// is invalidated server-side when the password changes).
  Future<String?> changePassword(
      String currentPassword, String newPassword, String confirmNewPassword) async {
    try {
      if (_currentUser == null) return 'You are not logged in.';
      final email = _currentUser!.email ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/User/${_currentUser!.id}/change-password"),
        headers: authHeaders,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      );

      if (response.statusCode == 200) {
        // The current token is now revoked; refresh it transparently.
        await login(email, newPassword);
        return null;
      }

      try {
        final data = jsonDecode(response.body);
        if (data['errors']?['UserError'] != null) {
          return data['errors']['UserError'][0];
        }
        return data['message'] ?? 'Could not change password.';
      } catch (_) {
        return 'Could not change password.';
      }
    } catch (e) {
      logError('Change password failed', e);
      return 'Could not reach the server. Please try again.';
    }
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
