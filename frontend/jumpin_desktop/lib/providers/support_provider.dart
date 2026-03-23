import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jumpin_admin/models/support_message.dart';
import 'package:jumpin_admin/providers/base_provider.dart';
import 'package:jumpin_admin/utils/config.dart';

class SupportProvider extends BaseProvider<SupportMessage> {
  static String get baseUrl => Config.apiBaseUrl;

  SupportProvider() : super("Support");

  @override
  SupportMessage fromJson(data) {
    return SupportMessage.fromJson(data);
  }

  Future<SupportMessage> respondToMessage(int id, String response) async {
    var url = "$baseUrl/Support/$id/respond";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode({"adminResponse": response});
    var resp = await http.post(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(resp)) {
      var data = jsonDecode(resp.body);
      return fromJson(data);
    } else {
      try {
        var errorData = jsonDecode(resp.body);
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
