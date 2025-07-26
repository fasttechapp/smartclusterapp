import '../../../core/services/api_service.dart';
import 'dart:convert';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login gagal: ${response.statusCode}');
    }
  }
}
