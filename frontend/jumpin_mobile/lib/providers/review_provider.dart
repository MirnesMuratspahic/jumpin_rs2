import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../utils/config.dart';

class ReviewProvider {
  String get baseUrl => '${Config.apiBaseUrl}/Review';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<List<Review>> getReviews({int? reviewerId, int? reviewedUserId}) async {
    try {
      var url = baseUrl;
      final queryParams = <String>[];

      if (reviewerId != null) {
        queryParams.add('reviewerId=$reviewerId');
      }
      if (reviewedUserId != null) {
        queryParams.add('reviewedUserId=$reviewedUserId');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> reviewList;
        if (data is Map && data.containsKey('resultList')) {
          reviewList = data['resultList'];
        } else if (data is List) {
          reviewList = data;
        } else {
          return [];
        }

        return reviewList.map((json) => Review.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> createReview({
    required int reviewerId,
    required int reviewedUserId,
    required int rating,
    String? comment,
    int? adId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _headers,
        body: json.encode({
          'reviewerId': reviewerId,
          'reviewedUserId': reviewedUserId,
          'rating': rating,
          'comment': comment,
          'adId': adId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReview(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
