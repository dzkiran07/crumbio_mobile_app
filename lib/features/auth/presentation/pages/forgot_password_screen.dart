import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/auth_view_model.dart';

enum _Step { email, otp, reset }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const bakeryColor = Color(0xFFD9782D);

  _Step _step = _Step.email;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : null),
      );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email first.', isError: true);
      return;
    }
    final success = await ref.read(authViewModelProvider.notifier).sendForgotPasswordOtp(email);
    if (!mounted) return;
    if (success) {
      _showSnack('OTP sent to your email.');
      setState(() => _step = _Step.otp);
    } else {
      _showSnack(
        ref.read(authViewModelProvider).errorMessage ?? 'Could not send OTP.',
        isError: true,
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnack('Enter the 6-digit OTP.', isError: true);
      return;
    }
    final success = await ref.read(authViewModelProvider.notifier).verifyForgotPasswordOtp(
          email: _emailController.text.trim(),
          otp: otp,
        );
    if (!mounted) return;
    if (success) {
      setState(() => _step = _Step.reset);
    } else {
      _showSnack(
        ref.read(authViewModelProvider).errorMessage ?? 'Invalid OTP.',
        isError: true,
      );
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    if (newPassword.length < 6) {
      _showSnack('Password must be at least 6 characters.', isError: true);
      return;
    }
    final success = await ref.read(authViewModelProvider.notifier).resetForgotPassword(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
          newPassword: newPassword,
        );
    if (!mounted) return;
    if (success) {
      _showSnack('Password reset. Please log in.');
      Navigator.of(context).pop();
    } else {
      _showSnack(
        ref.read(authViewModelProvider).errorMessage ?? 'Could not reset password.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == _Step.email) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: bakeryColor, foregroundColor: Colors.white),
                  child: const Text('Send OTP'),
                ),
              ] else if (_step == _Step.otp) ...[
                Text('Enter the OTP sent to ${_emailController.text}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '6-digit OTP', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: bakeryColor, foregroundColor: Colors.white),
                  child: const Text('Verify OTP'),
                ),
              ] else ...[
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(backgroundColor: bakeryColor, foregroundColor: Colors.white),
                  child: const Text('Reset password'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
