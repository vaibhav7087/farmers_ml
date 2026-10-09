import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Kisaan-ML',
      subtitle: 'AI-powered crop advisory for Indian farmers',
      illustration: Icons.agriculture,
      color: AppTheme.primaryGreen,
    ),
    OnboardingPage(
      title: 'Crop yield forecasting',
      subtitle: 'Yield predictions using satellite, weather and soil data',
      illustration: Icons.grass,
      color: AppTheme.primaryLightGreen,
    ),
    OnboardingPage(
      title: 'Market price forecasting',
      subtitle: 'Plan when to sell with policy-aware price forecasts',
      illustration: Icons.trending_up,
      color: AppTheme.accentOrange,
    ),
    OnboardingPage(
      title: 'Real-time alerts',
      subtitle: 'Outbreak detection + price spikes + weather warnings',
      illustration: Icons.notifications_active,
      color: AppTheme.accentRed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppTheme.primaryGreen : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _currentPage == _pages.length - 1
                        ? ElevatedButton(
                            onPressed: () => _completeOnboarding(context),
                            child: const Text('Get started'),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => _completeOnboarding(context),
                                child: const Text('Skip'),
                              ),
                              ElevatedButton(
                                onPressed: () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.illustration, size: 60, color: page.color),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Farmer',
      phone: '',
      district: 'Yavatmal',
      state: 'Maharashtra',
      crops: ['Cotton', 'Soybean'],
      language: 'en',
    );
    await auth.completeOnboarding(user);
    if (context.mounted) context.go('/');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final IconData illustration;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.color,
  });
}

