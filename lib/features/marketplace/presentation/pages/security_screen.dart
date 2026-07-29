import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/security/biometric_auth_service.dart';
import '../../../../core/services/storage/user_session_service.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/view_model/auth_view_model.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  static const bakeryColor = Color(0xFFD9782D);

  bool _isDeletingAccount = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricSupported = false;
  bool _isCheckingBiometricStatus = true;
  bool _isUpdatingBiometricStatus = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final userSessionService = ref.read(userSessionServiceProvider);
    final biometricAuthService = ref.read(biometricAuthServiceProvider);

    final isEnabled = await userSessionService.isBiometricLoginEnabledForCurrentUser();
    final isSupported = await biometricAuthService.canUseBiometricLogin();
    final hasCredentials = await userSessionService.hasBiometricCredentialsForCurrentUser();

    if (isEnabled && !hasCredentials) {
      await userSessionService.setBiometricLoginEnabled(false);
    }

    if (!mounted) return;
    setState(() {
      _isBiometricEnabled = isEnabled && hasCredentials;
      _isBiometricSupported = isSupported;
      _isCheckingBiometricStatus = false;
    });
  }

  Future<void> _toggleBiometric(bool shouldEnable) async {
    if (_isUpdatingBiometricStatus || _isCheckingBiometricStatus) return;

    final userSessionService = ref.read(userSessionServiceProvider);
    final biometricAuthService = ref.read(biometricAuthServiceProvider);

    setState(() => _isUpdatingBiometricStatus = true);

    try {
      if (!shouldEnable) {
        await userSessionService.setBiometricLoginEnabled(false);
        if (!mounted) return;
        setState(() => _isBiometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login has been disabled.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!_isBiometricSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint is not available on this device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final hasCredentials = await userSessionService.hasBiometricCredentialsForCurrentUser();
      if (!hasCredentials) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please login once with email and password before enabling fingerprint login.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final isVerified = await biometricAuthService.authenticate(
        reason: 'Confirm your fingerprint to enable biometric login',
      );

      if (!isVerified) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fingerprint verification was not completed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await userSessionService.setBiometricLoginEnabled(true);
      if (!mounted) return;
      setState(() => _isBiometricEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login has been enabled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingBiometricStatus = false);
    }
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _showDeleteAccountFlow() async {
    if (_isDeletingAccount) return;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB3261E)),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This action is permanent. To protect your account, we need one more confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldContinue != true || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountConfirmDialog(),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecurityActionCard(
                icon: Icons.lock_reset_rounded,
                title: 'Change Password',
                subtitle: 'Create a stronger password to keep your account secure.',
                accent: bakeryColor,
                onTap: _showChangePasswordSheet,
              ),
              const SizedBox(height: 14),
              _SecurityActionCard(
                icon: Icons.fingerprint_rounded,
                title: 'Enable Biometric Authentication',
                subtitle: _isCheckingBiometricStatus
                    ? 'Checking fingerprint availability...'
                    : (!_isBiometricSupported
                          ? 'Fingerprint is not available on this device.'
                          : (_isBiometricEnabled
                                ? 'Login screen will show Tap to Login with Fingerprint.'
                                : 'Use fingerprint on the login screen for faster sign in.')),
                accent: const Color(0xFF1565C0),
                showArrow: false,
                trailing: _isCheckingBiometricStatus
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: _isBiometricEnabled,
                        onChanged: (!_isBiometricSupported || _isUpdatingBiometricStatus)
                            ? null
                            : _toggleBiometric,
                      ),
                onTap: (_isCheckingBiometricStatus ||
                        !_isBiometricSupported ||
                        _isUpdatingBiometricStatus)
                    ? () {}
                    : () => _toggleBiometric(!_isBiometricEnabled),
              ),
              const SizedBox(height: 14),
              _SecurityActionCard(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: _isDeletingAccount
                    ? 'Deleting your account...'
                    : 'Permanently remove your account and all associated data.',
                accent: const Color(0xFFB3261E),
                danger: true,
                onTap: _isDeletingAccount ? () {} : _showDeleteAccountFlow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool danger;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showArrow;

  const _SecurityActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.danger = false,
    this.trailing,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: danger
                  ? (isDarkMode ? const Color(0xFF6B3532) : const Color(0xFFF6D3D2))
                  : (isDarkMode ? Colors.white10 : Colors.transparent),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: danger ? const Color(0xFFB93A31) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : const Color(0xFF667085),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else if (showArrow)
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  static const bakeryColor = Color(0xFFD9782D);

  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final success = await ref.read(authViewModelProvider.notifier).changePassword(
          currentPassword: _currentController.text.trim(),
          newPassword: _newController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
    } else {
      final errorMessage = ref.read(authViewModelProvider).errorMessage;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage ?? 'Could not change password.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E2D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use a strong password with letters, numbers, and symbols.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (value == _currentController.text) {
                      return 'New password cannot match current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _newController.text) {
                      return 'New and confirm password must match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bakeryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Update Password'),
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

class _DeleteAccountConfirmDialog extends ConsumerStatefulWidget {
  const _DeleteAccountConfirmDialog();

  @override
  ConsumerState<_DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState extends ConsumerState<_DeleteAccountConfirmDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitDelete() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      setState(() => _errorText = 'Please enter your current password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final success = await ref
        .read(authViewModelProvider.notifier)
        .deleteAccount(currentPassword: password);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      final errorMessage = ref.read(authViewModelProvider).errorMessage;
      setState(() {
        _isSubmitting = false;
        _errorText = errorMessage ?? 'Could not delete account.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Final Confirmation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your current password to permanently delete your account.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Current Password',
              errorText: _errorText,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
          onPressed: _isSubmitting ? null : _submitDelete,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
