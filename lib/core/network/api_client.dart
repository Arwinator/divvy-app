import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../storage/secure_storage.dart';
import '../config/environment.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  final String baseUrl;
  final SecureStorage secureStorage;

  ApiClient({required this.baseUrl, required this.secureStorage});

  Future<Map<String, String>> _getHeaders() async {
    final token = await secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint, {Duration? timeout}) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(timeout ?? EnvironmentConfig.apiTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timeout. Please check your connection.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(timeout ?? EnvironmentConfig.apiTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timeout. Please check your connection.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(timeout ?? EnvironmentConfig.apiTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timeout. Please check your connection.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String endpoint, {Duration? timeout}) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(timeout ?? EnvironmentConfig.apiTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkException('Request timeout. Please check your connection.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Success responses (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    // Parse error response
    dynamic errorData;
    try {
      errorData = json.decode(response.body);
    } catch (_) {
      errorData = {'message': response.body};
    }

    // Handle specific error codes
    switch (statusCode) {
      case 401:
        throw ApiException(
          errorData['message'] ?? 'Unauthenticated',
          statusCode: statusCode,
          data: errorData,
        );
      case 403:
        throw ApiException(
          errorData['message'] ?? 'Forbidden',
          statusCode: statusCode,
          data: errorData,
        );
      case 404:
        throw ApiException(
          errorData['message'] ?? 'Not found',
          statusCode: statusCode,
          data: errorData,
        );
      case 422:
        throw ApiException(
          errorData['message'] ?? 'Validation error',
          statusCode: statusCode,
          data: errorData,
        );
      case 429:
        throw ApiException(
          errorData['message'] ?? 'Too many requests',
          statusCode: statusCode,
          data: errorData,
        );
      case 500:
      case 502:
      case 503:
        throw ApiException(
          'Server error. Please try again later.',
          statusCode: statusCode,
          data: errorData,
        );
      default:
        throw ApiException(
          errorData['message'] ?? 'An error occurred',
          statusCode: statusCode,
          data: errorData,
        );
    }
  }
}
