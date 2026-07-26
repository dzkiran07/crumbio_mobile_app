import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/login_screen.dart';
import 'onboarding_three.dart';

class OnboardingTwo extends StatelessWidget {
  const OnboardingTwo({super.key});

  static const bakeryColor = Color(0xFFD9782D);

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF3B2A1E);
    final subtitleColor = isDarkMode ? Colors.white70 : const Color(0xFF6B5A4E);
    final heroCardColor = isDarkMode
        ? const Color(0xFF2E1F16)
        : const Color(0xFFFBEDE1);
    final heroBorderColor = isDarkMode ? Colors.white12 : Colors.white;
    final inactiveDotColor = isDarkMode ? Colors.white24 : Colors.black12;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _goToLogin(context),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: bakeryColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: heroCardColor,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: heroBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cake_outlined,
                          size: 140,
                          color: bakeryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Freshly Baked, Every Day',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Browse cakes, breads, and pastries made\nfresh by bakers near you.',
                      style: TextStyle(
                        fontSize: 16,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _IndicatorDot(isActive: false, inactiveColor: inactiveDotColor),
                        const SizedBox(width: 8),
                        _IndicatorDot(isActive: true, inactiveColor: inactiveDotColor),
                        const SizedBox(width: 8),
                        _IndicatorDot(isActive: false, inactiveColor: inactiveDotColor),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const OnboardingThree()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: bakeryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Next', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool isActive;
  final Color inactiveColor;

  const _IndicatorDot({required this.isActive, required this.inactiveColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isActive ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? OnboardingTwo.bakeryColor : inactiveColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
