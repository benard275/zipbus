import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/agent.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/parcel_form_screen.dart';
import 'screens/parcel_list_screen.dart';
import 'screens/tracking_details_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'services/sms_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const ZipBusApp());
}

class ZipBusApp extends StatelessWidget {
  const ZipBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZipBus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1976D2),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Agent) {
            return HomeScreen(agent: args);
          } else {
            return const SplashScreen(); // fallback or error screen
          }
        },
        '/parcel_form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Agent) {
            return ParcelFormScreen(agent: args);
          } else {
            return const SplashScreen();
          }
        },
        '/parcel_list': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Agent) {
            return ParcelListScreen(agent: args);
          } else {
            return const SplashScreen();
          }
        },
        '/tracking': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return TrackingDetailsScreen(
            trackingNumber: args is String ? args : '',
          );
        },
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Agent) {
            return ProfileScreen(agent: args);
          } else {
            return const SplashScreen();
          }
        },
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}