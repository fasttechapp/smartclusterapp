import 'dart:convert';
import 'dart:io';
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

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}',
    );
    final response = await http
        .delete(url, headers: {'Content-Type': 'application/json'})
        .timeout(ApiConstants.timeout);
    return response;
  }

  static Future<http.StreamedResponse> multipartRequest({
    required String endpoint,
    required String fieldName,
    required File file,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}',
    );

    final request = http.MultipartRequest('POST', url);

    // Tambah file ke form
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    // Tambah fields tambahan kalau ada
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Default header (optional)
    request.headers.addAll({
      'Accept': 'application/json',
      ...?headers, // override / custom header jika diperlukan
    });

    return await request.send().timeout(ApiConstants.timeout);
  }
}
