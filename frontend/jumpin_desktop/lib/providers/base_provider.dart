import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jumpin_admin/main.dart';
import 'package:jumpin_admin/models/search_result.dart';
import 'package:jumpin_admin/providers/helper_providers/auth_provider.dart';
import 'package:jumpin_admin/screens/home_screen.dart';
import 'package:jumpin_admin/utils/config.dart';
import 'dart:developer' as developer;

abstract class BaseProvider<T> with ChangeNotifier {
  static String get _baseUrl => Config.apiBaseUrl;
  final String _endpoint;

  BaseProvider(this._endpoint);

  Future<SearchResult<T>> get({Map<String, dynamic>? filter}) async {
    var url = "$_baseUrl/$_endpoint";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      if (data is List) {
        var result = <T>[];
        for (var item in data) {
          result.add(fromJson(item));
        }
        return SearchResult<T>(result: result, count: result.length);
      }
      return SearchResult<T>.fromJson(data, fromJson);
    } else {
      try {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'An error occurred');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception('An error occurred');
      }
    }
  }

  Future<T> getById(String id, {Map<String, dynamic>? filter}) async {
    var url = "$_baseUrl/$_endpoint/$id";

    if (filter != null) {
      var queryString = getQueryString(filter);
      url = "$url?$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      try {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'An error occurred');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception('An error occurred');
      }
    }
  }

  Future<T> insert(dynamic request) async {
    var url = "$_baseUrl/$_endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      try {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'An error occurred');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception('An error occurred');
      }
    }
  }

  Future<T> update(String id, [dynamic request]) async {
    var url = "$_baseUrl/$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.put(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      try {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'An error occurred');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception('An error occurred');
      }
    }
  }

  Future<T> delete(String id) async {
    var url = "$_baseUrl/$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.delete(uri, headers: headers);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      try {
        var errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'An error occurred');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:')) {
          rethrow;
        }
        throw Exception('An error occurred');
      }
    }
  }

  bool isValidResponse(http.Response response) {
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      // Credentials/session invalid → clear and return to the login screen.
      AuthProvider.username = null;
      AuthProvider.password = null;
      AuthProvider.userId = null;
      AuthProvider.isAdmin = false;
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      throw Exception("Your session has expired. Please log in again.");
    } else {
      return false;
    }
  }

  Map<String, String> createHeaders() {
    String username = AuthProvider.username ?? "";
    String password = AuthProvider.password ?? "";

    String basicAuth =
        "Basic ${base64Encode(utf8.encode('$username:$password'))}";

    var headers = {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };

    return headers;
  }

  String getQueryString(
    Map params, {
    String prefix = '&',
    bool inRecursion = false,
  }) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${(value).toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query += getQueryString(
            {k: v},
            prefix: '$prefix$key',
            inRecursion: true,
          );
        });
      }
    });
    return query;
  }

  T fromJson(data) {
    throw Exception("Method not implemented");
  }
}
