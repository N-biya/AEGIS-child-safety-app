import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/map_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/calibration_screen.dart';
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
      case '/onboarding':
        return _fade(const OnboardingScreen());
      case '/home':
        return _fade(const HomeShell());
      case '/calibration':
        return _fade(const CalibrationScreen());
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
}

// ── 5-tab HomeShell with PageView swiping ────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          // ── PageView — swipe to switch tabs ──────────────────────────
          PageView(
            controller: _pageCtrl,
            // Use BouncingScrollPhysics so page swipes feel natural but
            // don't compete with inner horizontal scrollables.
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _index = i),
            children: [
              _KA(child: DashboardScreen(
                onViewMap:    () => _switchTab(1),
                onSwitchTab:  _switchTab,
              )),
              const _KA(child: MapScreen()),
              const _KA(child: AlertsScreen()),
              const _KA(child: AnalyticsScreen()),
              _KA(child: SettingsScreen(onViewMap: () => _switchTab(1))),
            ],
          ),

          // ── Floating frosted nav pill ─────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 16,
            right: 16,
            child: AegisBottomNav(
              currentIndex: _index,
              onTap: _switchTab,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps a PageView child alive across page swipes using
/// [AutomaticKeepAliveClientMixin] so each tab retains its scroll position
/// and loaded state.
class _KA extends StatefulWidget {
  final Widget child;
  const _KA({required this.child});

  @override
  State<_KA> createState() => _KAState();
}

class _KAState extends State<_KA> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// Shared bottom padding constant for screen content (nav pill height)
const double kNavBarHeight = 90.0;
