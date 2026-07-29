import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/api/api_endpoint.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../auth/presentation/view_model/auth_view_model.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const bakeryColor = Color(0xFFD9782D);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const double _shakeThreshold = 22.0;
  static const Duration _shakeCooldown = Duration(milliseconds: 1200);

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isLogoutDialogOpen = false;

  final ImagePicker _imagePicker = ImagePicker();
  File? _localProfileImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _startShakeListener();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startShakeListener() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final combinedAcceleration = event.x.abs() + event.y.abs() + event.z.abs();
      if (combinedAcceleration < _shakeThreshold) return;

      final now = DateTime.now();
      if (now.difference(_lastShakeAt) < _shakeCooldown) return;

      _lastShakeAt = now;
      _handleShake();
    });
  }

  Future<void> _handleShake() async {
    if (_isLogoutDialogOpen) return;
    if (ref.read(authViewModelProvider).status != AuthStatus.authenticated) return;

    _isLogoutDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log out?'),
        content: const Text('We noticed you shook your phone. Do you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    _isLogoutDialogOpen = false;

    if (confirmed != true || !mounted) return;

    await ref.read(authViewModelProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This feature requires permission to access your camera or gallery. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePickedImage(XFile image) async {
    setState(() {
      _localProfileImage = File(image.path);
      _isUploadingImage = true;
    });

    final success = await ref
        .read(authViewModelProvider.notifier)
        .uploadProfileImage(image.path);

    if (!mounted) return;
    setState(() {
      _isUploadingImage = false;
      if (success) _localProfileImage = null;
    });

    if (!success) {
      final errorMessage = ref.read(authViewModelProvider).errorMessage;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Could not upload profile picture.')),
        );
    }
  }

  Future<void> _pickFromCamera() async {
    if (!await _requestPermission(Permission.camera)) return;
    final photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) await _savePickedImage(photo);
  }

  Future<void> _pickFromGallery() async {
    if (!await _requestPermission(Permission.photos)) return;
    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) await _savePickedImage(image);
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authViewModelProvider.notifier).logout();
    }
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'U' : trimmed[0].toUpperCase();
  }

  Widget _buildAvatar(String fullName, String? profileImage) {
    if (_localProfileImage != null) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: ProfileScreen.bakeryColor.withValues(alpha: 0.15),
        backgroundImage: FileImage(_localProfileImage!),
      );
    }

    if (profileImage != null && profileImage.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: ProfileScreen.bakeryColor.withValues(alpha: 0.15),
        child: ClipOval(
          child: Image.network(
            ApiEndpoints.resolveMediaUrl(profileImage),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
              _initial(fullName),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: ProfileScreen.bakeryColor,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 48,
      backgroundColor: ProfileScreen.bakeryColor.withValues(alpha: 0.15),
      child: Text(
        _initial(fullName),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: ProfileScreen.bakeryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.authEntity;

    if (authState.status != AuthStatus.authenticated || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("You're not logged in."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileScreen.bakeryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  _buildAvatar(user.fullName, user.profileImage),
                  if (_isUploadingImage)
                    const Positioned.fill(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.black38,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingImage ? null : _showMediaPicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: ProfileScreen.bakeryColor, width: 2),
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: ProfileScreen.bakeryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.fullName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(user.email, style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 32),
            _ProfileInfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone),
            if (user.address != null && user.address!.isNotEmpty)
              _ProfileInfoTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: user.address!,
              ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined, color: ProfileScreen.bakeryColor),
              title: const Text('Privacy & Security'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: ProfileScreen.bakeryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
