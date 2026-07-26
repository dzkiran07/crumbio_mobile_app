import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage/user_session_service.dart';
import '../../../marketplace/presentation/pages/button_navigation.dart';
import '../../../onboarding/presentation/pages/onboarding_one.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const bakeryColor = Color(0xFFD9782D);

  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    final startedAt = DateTime.now();

    final token = await ref.read(userSessionServiceProvider).getToken();

    final elapsed = DateTime.now().difference(startedAt);
    const minSplashDuration = Duration(seconds: 2);
    final waitDuration = minSplashDuration - elapsed;
    if (waitDuration > Duration.zero) {
      await Future.delayed(waitDuration);
    }

    if (!mounted) return;

    final isLoggedIn = token != null && token.isNotEmpty;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const ButtonNavigation() : const OnboardingOne(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: bakeryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bakery_dining, size: 96, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Crumbio',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
