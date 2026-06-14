import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jumpin_admin/providers/helper_providers/auth_provider.dart';
import 'package:jumpin_admin/utils/config.dart';

class StatisticsProvider {
  static String get _baseUrl => '${Config.apiBaseUrl}/Statistics';

  Map<String, String> createHeaders() {
    String username = AuthProvider.username ?? "";
    String password = AuthProvider.password ?? "";

    String basicAuth =
        "Basic ${base64Encode(utf8.encode('$username:$password'))}";

    return {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };
  }

  bool isValidResponse(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// The backend exposes a single endpoint returning all admin statistics.
  /// Every getter below reuses it so each screen map holds the full set of keys.
  Future<Map<String, dynamic>> getStatistics() async {
    var uri = Uri.parse(_baseUrl);
    var headers = createHeaders();
    var response = await http.get(uri, headers: headers);

    if (isValidResponse(response)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  Future<Map<String, dynamic>> getOverview() => getStatistics();
  Future<Map<String, dynamic>> getAdStatistics() => getStatistics();
  Future<Map<String, dynamic>> getRequestStatistics() => getStatistics();
  Future<Map<String, dynamic>> getUserStatistics() => getStatistics();
  Future<Map<String, dynamic>> getReviewStatistics() => getStatistics();
}
