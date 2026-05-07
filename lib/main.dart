import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'core/constants/premium_theme.dart';
import 'views/web/landing_page_view.dart';
import 'views/web/agency_login_view.dart';
import 'views/web/admin_dashboard_view.dart';
import 'views/mobile/promoter_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CheckFastApp());
}

class CheckFastApp extends StatelessWidget {
  const CheckFastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckFast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.neonCyan,
        scaffoldBackgroundColor: AppColors.spaceBlack,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingPageView());
          case '/megapromo':
            return MaterialPageRoute(builder: (_) => const AgencyLoginView());
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminDashboardView());
          case '/promoter':
            return MaterialPageRoute(builder: (_) => const PromoterHomeView());
          default:
            return MaterialPageRoute(builder: (_) => const LandingPageView());
        }
      },
    );
  }
}
