import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jumpin_admin/models/request.dart';
import 'package:jumpin_admin/providers/base_provider.dart';
import 'package:jumpin_admin/utils/config.dart';

class RequestProvider extends BaseProvider<Request> {
  static String get baseUrl => Config.apiBaseUrl;

  RequestProvider() : super("Request");

  @override
  Request fromJson(data) {
    return Request.fromJson(data);
  }

  Future<Request> acceptRequest(String id) async {
    var url = "$baseUrl/Request/$id/accept";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.post(uri, headers: headers);

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

  Future<Request> declineRequest(String id) async {
    var url = "$baseUrl/Request/$id/decline";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.post(uri, headers: headers);

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
}
