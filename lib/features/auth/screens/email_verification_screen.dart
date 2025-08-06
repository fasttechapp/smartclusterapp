import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/widgets/showokdialog.dart';
import 'package:smart_cluster_app/features/auth/screens/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late String email;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    email = widget.email;
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final response = await ApiService.post('/check-email-verified', {
        'email': email,
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final verified = data['verified'] ?? false;

        if (verified) {
          showSuccessDialog(
            context,
            "✅ Email sudah terverifikasi!\nSilakan login untuk melanjutkan.",
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          setState(() {
            _statusMessage =
                "Email belum diverifikasi. Silakan cek inbox Anda.";
          });
        }
      } else {
        setState(() {
          _statusMessage = "⚠️ Gagal memeriksa status verifikasi.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final response = await ApiService.post('/email/resend', {'email': email});

      if (!mounted) return;

      if (response.statusCode == 200) {
        showSuccessDialog(
          context,
          "📩 Link verifikasi telah dikirim ulang ke email Anda.",
        );
      } else {
        showErrorDialog(context, "Gagal mengirim ulang link verifikasi.");
      }
    } catch (e) {
      showErrorDialog(context, "Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _goToLogin();
        return false; // Supaya tidak pop default
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Verifikasi Email"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToLogin,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Verifikasi Alamat Email",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Kami telah mengirimkan link verifikasi ke:",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_statusMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified),
                  label: const Text("Cek Status Verifikasi"),
                  onPressed: _checkVerification,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Kirim Ulang Link Verifikasi"),
                  onPressed: _resendVerification,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Login"),
                  onPressed: _goToLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
