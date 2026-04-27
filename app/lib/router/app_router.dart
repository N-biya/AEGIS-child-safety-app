import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/map_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/calibration_screen.dart';
import '../screens/analytics_screen.dart';
import '../widgets/bottom_nav.dart';
import '../utils/app_colors.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _fade(const SplashScreen());
      case '/login':
        return _fade(const LoginScreen());
      case '/signup':
        return _fade(const SignupScreen());
      case '/home':
        return _fade(const HomeShell());
      case '/calibration':
        return _fade(const CalibrationScreen());
      case '/analytics':
        return _slide(const AnalyticsScreen(showBackButton: true));
      default:
        return _fade(const SplashScreen());
    }
  }

  static PageRoute _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  static PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _switchTab(int i) => setState(() => _index = i);

  List<Widget> get _screens => [
        DashboardScreen(onViewMap: () => _switchTab(1)),
        const MapScreen(),
        const AlertsScreen(),
        SettingsScreen(onViewMap: () => _switchTab(1)),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.bg(context),
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: AegisBottomNav(
        currentIndex: _index,
        onTap: _switchTab,
      ),
    );
  }
}
