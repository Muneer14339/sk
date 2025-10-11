import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';

class ApiClient {
  final String baseUrl;
  final NetworkInfo networkInfo;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final http.Client client;

  ApiClient({
    required this.client,
    required this.networkInfo,
    String? customBaseUrl,
  }) : baseUrl = customBaseUrl ?? AppConstants.baseUrl;

  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _headers.remove('Authorization');
  }

  // Helper method to handle response
  dynamic _returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return null;
        return json.decode(response.body);
      case 400:
        throw ValidationException(
          'Invalid request',
          errors: json
              .decode(response.body)['errors']
              ?.cast<String, List<String>>(),
        );
      case 401:
      case 403:
        throw UnauthorizedException('Unauthorized access');
      case 404:
        throw NotFoundException('Resource not found');
      case 500:
      default:
        throw ServerException(
          'Error occurred with code: ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }

  // GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParams,
      );

      final response = await client.get(
        uri,
        headers: {..._headers, ...?headers},
      );

      return _returnResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final response = await client.post(
        Uri.parse('$baseUrl$path'),
        body: body is Map || body is List ? json.encode(body) : body,
        headers: {..._headers, ...?headers},
      );

      return _returnResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final response = await client.put(
        Uri.parse('$baseUrl$path'),
        body: body is Map || body is List ? json.encode(body) : body,
        headers: {..._headers, ...?headers},
      );

      return _returnResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final request = http.Request('DELETE', Uri.parse('$baseUrl$path'))
        ..headers.addAll({..._headers, ...?headers});

      if (body != null) {
        request.body = body is Map || body is List ? json.encode(body) : body;
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      return _returnResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      rethrow;
    }
  }

  // File upload
  Future<dynamic> uploadFile(
    String path, {
    required String filePath,
    String? fileKey = 'file',
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        fileKey!,
        filePath,
        contentType: MediaType('application', 'octet-stream'),
      ));

      // Add fields if any
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add headers
      request.headers.addAll({..._headers, ...?headers});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _returnResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      rethrow;
    }
  }
}
