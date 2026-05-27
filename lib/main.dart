import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'core/constants/premium_theme.dart';
import 'views/web/landing_page_view.dart';
import 'views/web/agency_login_view.dart';
import 'views/web/admin_dashboard_view.dart';
import 'views/web/rede_login_view.dart';
import 'views/web/rede_dashboard_view.dart';
import 'views/mobile/promoter_home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  final userCpf = prefs.getString('user_cpf');
  runApp(CheckFastApp(isLoggedIn: userCpf != null && userCpf.isNotEmpty));
}

class CheckFastApp extends StatelessWidget {
  final bool isLoggedIn;
  const CheckFastApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckFast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
      ),
      initialRoute: isLoggedIn ? '/promoter' : '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingPageView());
          case '/megapromo':
            return MaterialPageRoute(builder: (_) => const AgencyLoginView());
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminDashboardView());
          case '/rede':
            return MaterialPageRoute(builder: (_) => const RedeLoginView());
          case '/rede_dashboard':
            return MaterialPageRoute(builder: (_) => const RedeDashboardView());
          // Rotas legadas de compatibilidade
          case '/gerente':
            return MaterialPageRoute(builder: (_) => const RedeLoginView());
          case '/gerente_dashboard':
            return MaterialPageRoute(builder: (_) => const RedeDashboardView());
          case '/promoter':
            return MaterialPageRoute(builder: (_) => const PromoterHomeView());
          default:
            return MaterialPageRoute(builder: (_) => const LandingPageView());
        }
      },
    );
  }
}
