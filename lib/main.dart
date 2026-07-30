import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_endpoint.dart';
import 'core/services/hive/hive_service.dart';
import 'features/auth/presentation/view_model/auth_view_model.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService().init();
  await ApiEndpoints.initialize();
  runApp(const ProviderScope(child: CrumbioApp()));
}

class CrumbioApp extends StatelessWidget {
  const CrumbioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crumbio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD9782D)),
      ),
      home: const _AppRoot(),
    );
  }
}


class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authViewModelProvider.notifier).loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
