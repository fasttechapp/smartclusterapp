import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static Future<http.Response> get(String endpoint) async {
    // pastikan endpoint diawali dengan slash
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}',
    );
    final response = await http.get(url).timeout(ApiConstants.timeout);
    return response;
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}',
    );
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConstants.timeout);
    return response;
  }
}
