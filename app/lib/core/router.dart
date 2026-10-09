import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/advisory/screens/advisory_screen.dart';
import '../features/advisory/screens/yield_detail_screen.dart';
import '../features/advisory/screens/price_detail_screen.dart';
import '../features/alerts/screens/alerts_screen.dart';
import '../features/market/screens/market_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

final router = GoRouter(
  initialLocation: '/onboarding',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isOnboarding = state.matchedLocation == '/onboarding';
    final isLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isOnboarding && !isLogin) {
      return '/login';
    }
    if (isLoggedIn && (isOnboarding || isLogin)) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AdvisoryScreen(),
        ),
        GoRoute(
          path: '/advisory/yield/:district/:crop',
          builder: (context, state) => YieldDetailScreen(
            district: state.pathParameters['district']!,
            crop: state.pathParameters['crop']!,
          ),
        ),
        GoRoute(
          path: '/advisory/price/:mandi/:crop',
          builder: (context, state) => PriceDetailScreen(
            mandi: state.pathParameters['mandi']!,
            crop: state.pathParameters['crop']!,
            variety: state.uri.queryParameters['variety'],
          ),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const AlertsScreen(),
        ),
        GoRoute(
          path: '/market',
          builder: (context, state) => const MarketScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTabTap(context, index),
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/advisory')) return 0;
    if (location.startsWith('/alerts')) return 1;
    if (location.startsWith('/market')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/alerts'); break;
      case 2: context.go('/market'); break;
      case 3: context.go('/profile'); break;
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.agriculture_outlined), selectedIcon: Icon(Icons.agriculture), label: 'सलाह'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'अलर्ट'),
        NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'बाजार'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'प्रोफाइल'),
      ],
    );
  }
}

