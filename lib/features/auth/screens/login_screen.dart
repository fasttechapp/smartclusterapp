import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/core/utils/input_formatters.dart';
import 'package:smart_cluster_app/core/utils/usersesion.dart';
import 'package:smart_cluster_app/features/auth/screens/mainmenu_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/register_screen.dart';
import 'package:smart_cluster_app/widgets/loading_dialog.dart';
import 'package:smart_cluster_app/widgets/showokdialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? deviceToken;

  @override
  void initState() {
    super.initState();
    _initFCMToken();
  }

  Future<void> _initFCMToken() async {
    deviceToken = await FirebaseMessaging.instance.getToken();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    showLoadingDialog(context, message: "Login sedang diproses...");

    try {
      final response = await ApiService.post('/login', {
        'email': email,
        'password': password,
        'device_token': deviceToken ?? '',
      }).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      Navigator.of(context).pop(); // tutup loading

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        showErrorDialog(
          context,
          "Format response tidak valid: ${response.body}",
        );
        return;
      }

      if (response.statusCode == 200) {
        final rememberToken = data['data']?['remember_token'];
        final emailFromApi = data['data']?['email'];
        final nameFromApi = data['data']?['name'];
        await UserSession().setSession(
          name: nameFromApi,
          email: emailFromApi,
          rememberToken: rememberToken,
        );

        if (!mounted) return;
        showSuccessDialog(context, data['message'] ?? 'Login berhasil!');

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
          (route) => false, // hapus semua route sebelumnya
        );
      } else {
        final error = data['message'] ?? 'Login gagal';
        showErrorDialog(context, "Gagal: $error");
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // pastikan dialog ditutup jika error
        showErrorDialog(context, "Terjadi kesalahan: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/logo.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  inputFormatters: getLowerCaseFormatter(),
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email wajib diisi';
                    }

                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    return emailRegex.hasMatch(value)
                        ? null
                        : 'Format email tidak valid';
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Password wajib diisi'
                      : null,
                ),

                const SizedBox(height: 16),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors
                            .white, // ← ini tempat yang benar untuk atur warna
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrasiScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
