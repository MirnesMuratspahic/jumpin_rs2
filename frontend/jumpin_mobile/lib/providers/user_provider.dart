import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/config.dart';
import '../utils/api_exception.dart';
import '../utils/app_logger.dart';

class UserProvider {
  String get baseUrl => '${Config.apiBaseUrl}/User';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<User?> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return User.fromJson(json);
      }
      if (response.statusCode == 404) return null;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<String?> uploadProfileImage(String filePath) async {
    try {
      var url = '${Config.apiBaseUrl}/User/upload-image';
      var uri = Uri.parse(url);

      var request = http.MultipartRequest('POST', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      logDebug('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['imageUrl'] as String?;
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> updateProfileImage(String userId, String imageUrl) async {
    try {
      var url = '$baseUrl/$userId/profile-image';
      var uri = Uri.parse(url);
      var body = jsonEncode({'profileImageUrl': imageUrl});
      var response = await http.put(uri, headers: _headers, body: body);
      logDebug('Update profile image response: ${response.statusCode}');
      if (response.statusCode == 200) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }
}
