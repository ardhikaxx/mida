import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 80,
              child: Image.asset('assets/images/logo-kemkes-new.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              'MIDA',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mobile ICD Database Application',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 28, child: Image.asset('assets/images/logo-kemenkes.png', fit: BoxFit.contain)),
                const SizedBox(width: 20),
                SizedBox(height: 28, child: Image.asset('assets/images/bangga-melayani-bangsa-seeklogo.png', fit: BoxFit.contain)),
                const SizedBox(width: 20),
                SizedBox(height: 28, child: Image.asset('assets/images/logo-berakhlak.png', fit: BoxFit.contain)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
