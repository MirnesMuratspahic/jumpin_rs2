import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/city.dart';
import '../utils/config.dart';
import '../utils/api_exception.dart';

class CityProvider {
  static String get baseUrl => Config.apiBaseUrl;

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<List<City>> getCities() async {
    try {
      var url = "$baseUrl/City?PageSize=100";
      var uri = Uri.parse(url);
      var response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        List<dynamic> cityList;
        if (data is Map && data.containsKey('resultList')) {
          cityList = data['resultList'];
        } else if (data is List) {
          cityList = data;
        } else {
          return [];
        }

        var cities = cityList.map((json) => City.fromJson(json)).toList();
        cities.sort((a, b) => a.name.compareTo(b.name));
        return cities;
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }
}
