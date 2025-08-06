import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/core/utils/input_formatters.dart';
import 'package:smart_cluster_app/core/utils/logger.dart';
import 'package:smart_cluster_app/widgets/loading_dialog.dart';
import 'package:smart_cluster_app/widgets/showokdialog.dart';
import 'package:smart_cluster_app/widgets/standard_button.dart';

class RegistrasiScreen extends StatefulWidget {
  const RegistrasiScreen({super.key});

  @override
  State<RegistrasiScreen> createState() => _RegistrasiScreenState();
}

class _RegistrasiScreenState extends State<RegistrasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final body = {"name": name, "email": email, "password": password};

    bool isDialogOpen = false;

    showLoadingDialog(context, message: "Mengirim data registrasi...");
    isDialogOpen = true;

    try {
      final response = await ApiService.post(
        '/register',
        body,
      ).timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (isDialogOpen) {
        Navigator.of(context).pop(); // tutup dialog loading
        isDialogOpen = false;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        showSuccessDialog(
          context,
          "Registrasi berhasil! Silakan cek email untuk verifikasi.",
        );
        _formKey.currentState!.reset();
        log.info('Navigasi ke route: "/emailVerification"');
        Navigator.pushNamed(context, '/emailVerification', arguments: email);
      } else {
        final data = jsonDecode(response.body);
        final errorMessage =
            data['errors']?['email']?[0] ??
            data['message'] ??
            "Terjadi kesalahan saat registrasi.";
        showErrorDialog(context, "Registrasi gagal: $errorMessage");
      }
    } catch (e) {
      if (!mounted) return;
      if (isDialogOpen) {
        Navigator.of(context).pop(); // tutup dialog loading
        isDialogOpen = false;
      }
      showErrorDialog(context, "Error: $e");
    }
  }

  final _inputDecoration = InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.teal.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrasi Pengguna"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                inputFormatters: getUpperCaseFormatter(),
                controller: _nameController,
                decoration: _inputDecoration.copyWith(
                  labelText: "Nama Lengkap",
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    value == null || value.isEmpty ? "Wajib isi nama" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                inputFormatters: getLowerCaseFormatter(),
                controller: _emailController,
                decoration: _inputDecoration.copyWith(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Wajib isi email";
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  return emailRegex.hasMatch(value)
                      ? null
                      : "Format email tidak valid";
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration.copyWith(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? "Minimal 6 karakter"
                    : null,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StandardButton(
            label: 'Registrasi',
            icon: Icons.save,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}
