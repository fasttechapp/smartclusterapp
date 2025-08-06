import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_cluster_app/core/utils/logger.dart';
import 'package:smart_cluster_app/core/utils/usersesion.dart';
import 'package:smart_cluster_app/features/auth/screens/email_verification_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/mainmenu_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/register_screen.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // WAJIB!
  setupLogging();
  // await UserSession().loadFromPreferences();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cluster App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegistrasiScreen());
          case '/emailVerification':
            final email = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email ?? ''),
            );
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          default:
            return null; // atau bisa arahkan ke halaman 404/custom
        }
      },
      home: UserSession().isLoggedIn
          ? const MainMenuScreen() // ganti sesuai halaman utama kamu
          : const LoginScreen(),
    );
  }
}
