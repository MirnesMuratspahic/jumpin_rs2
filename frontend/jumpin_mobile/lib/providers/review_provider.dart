import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../utils/config.dart';
import '../utils/api_exception.dart';
import '../utils/app_logger.dart';

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

  Future<List<Review>> getReviews(
      {String? reviewerId, String? reviewedUserId}) async {
    try {
      // If we're fetching reviews for a specific user, use the dedicated endpoint
      if (reviewedUserId != null && reviewerId == null) {
        return _getReviewsByUser(reviewedUserId);
      }

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
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<List<Review>> _getReviewsByUser(String userId) async {
    try {
      final url = '$baseUrl/user/$userId';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> reviewList;
        if (data is List) {
          reviewList = data;
        } else {
          return [];
        }

        return reviewList.map((json) => Review.fromJson(json)).toList();
      }
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> createReview({
    required String reviewerId,
    required String reviewedUserId,
    required int rating,
    String? comment,
    String? adId,
  }) async {
    try {
      final url = '$baseUrl/create-for-user/$reviewedUserId';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({
          'reviewerId': reviewerId,
          'rating': rating,
          'comment': comment,
          'adId': adId,
        }),
      );

      logDebug('Review creation response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  Future<bool> deleteReview(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/$id'), headers: _headers);
      if (response.statusCode == 200) return true;
      throw ApiException.fromResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }
}
