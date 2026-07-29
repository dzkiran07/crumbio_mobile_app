import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/security/biometric_auth_service.dart';
import '../../../../core/services/storage/user_session_service.dart';
import '../../../marketplace/presentation/pages/button_navigation.dart';
import '../state/auth_state.dart';
import '../view_model/auth_view_model.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const bakeryColor = Color(0xFFD9782D);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _canUseFingerprintLogin = false;
  bool _isCheckingFingerprint = true;
  bool _isFingerprintLoginInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricLoginAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authViewModelProvider.notifier)
          .login(email: _emailController.text.trim(), password: _passwordController.text);
    }
  }

  Future<void> _loadBiometricLoginAvailability() async {
    final userSessionService = ref.read(userSessionServiceProvider);
    final biometricAuthService = ref.read(biometricAuthServiceProvider);

    final isEnabled = await userSessionService.isBiometricLoginEnabled();
    bool canUseFingerprintLogin = false;

    if (isEnabled) {
      final isSupported = await biometricAuthService.canUseBiometricLogin();
      final hasCredentials = await userSessionService.hasBiometricCredentials();

      if (!hasCredentials) {
        await userSessionService.setBiometricLoginEnabled(false);
      }

      canUseFingerprintLogin = isSupported && hasCredentials;
    }

    if (!mounted) return;
    setState(() {
      _canUseFingerprintLogin = canUseFingerprintLogin;
      _isCheckingFingerprint = false;
    });
  }

  Future<void> _handleFingerprintLogin() async {
    if (_isFingerprintLoginInProgress || _isCheckingFingerprint) return;
    if (ref.read(authViewModelProvider).status == AuthStatus.loading) return;

    setState(() => _isFingerprintLoginInProgress = true);

    final userSessionService = ref.read(userSessionServiceProvider);
    final biometricAuthService = ref.read(biometricAuthServiceProvider);

    try {
      final isAuthenticated = await biometricAuthService.authenticate(
        reason: 'Scan your fingerprint to login',
      );
      if (!isAuthenticated) return;

      final credentials = await userSessionService.getBiometricCredentials();
      if (credentials == null) {
        await userSessionService.clearBiometricLoginSetup();
        if (!mounted) return;
        setState(() => _canUseFingerprintLogin = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved fingerprint login is unavailable. Please login manually and enable it again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      _emailController.text = credentials.email;

      await ref
          .read(authViewModelProvider.notifier)
          .login(email: credentials.email, password: credentials.password);

      final latestAuthState = ref.read(authViewModelProvider);
      if (latestAuthState.status == AuthStatus.error) {
        final message = (latestAuthState.errorMessage ?? '').toLowerCase();
        if (message.contains('invalid email or password')) {
          await userSessionService.clearBiometricLoginSetup();
          if (!mounted) return;
          setState(() => _canUseFingerprintLogin = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Saved fingerprint login expired. Please login manually and enable it again.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isFingerprintLoginInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ButtonNavigation()),
          (route) => false,
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const Icon(Icons.bakery_dining, size: 64, color: bakeryColor),
                const SizedBox(height: 10),
                const Text(
                  'Crumbio',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: bakeryColor),
                ),
                const SizedBox(height: 4),
                const Text('Welcome back to Crumbio', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: bakeryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      if (_canUseFingerprintLogin) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: (authState.isLoading || _isFingerprintLoginInProgress)
                                ? null
                                : _handleFingerprintLogin,
                            icon: _isFingerprintLoginInProgress
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.fingerprint_rounded),
                            label: const Text(
                              'Tap to Login with Fingerprint',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(foregroundColor: bakeryColor),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
