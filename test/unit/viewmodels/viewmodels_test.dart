import 'package:crumbio_mobile_app/core/error/failures.dart';
import 'package:crumbio_mobile_app/features/auth/domain/entities/auth_entity.dart';
import 'package:crumbio_mobile_app/features/auth/presentation/state/auth_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fakes.dart';

void main() {
  group('AuthViewModel unit tests', () {
    late FakeUserSessionService userSessionService;
    late FakeAuthRepository authRepository;

    setUp(() {
      userSessionService = FakeUserSessionService();
      authRepository = FakeAuthRepository();
    });

    test('1. login success sets authenticated state and syncs biometrics', () async {
      final expectedUser = sampleAuthEntity(id: 'auth-123', email: 'user@example.com');
      authRepository.onLogin = ({required email, required password}) async => Right(expectedUser);
      final viewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );

      final success = await viewModel.login(email: 'user@example.com', password: 'pass1234');

      expect(success, isTrue);
      expect(viewModel.state.status, AuthStatus.authenticated);
      expect(viewModel.state.authEntity, expectedUser);
      expect(userSessionService.syncBiometricStateAfterLoginCalls, 1);
      expect(userSessionService.saveBiometricCredentialsCalls, 1);
    });

    test('2. login failure sets error state with the failure message', () async {
      authRepository.onLogin = ({required email, required password}) async {
        return const Left(ApiFailure(message: 'Invalid email or password'));
      };
      final viewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );

      final success = await viewModel.login(email: 'user@example.com', password: 'wrong-pass');

      expect(success, isFalse);
      expect(viewModel.state.status, AuthStatus.error);
      expect(viewModel.state.errorMessage, 'Invalid email or password');
    });

    test('3. register success sets authenticated state with the new user', () async {
      final expectedUser = sampleAuthEntity(fullName: 'Jane Baker', email: 'jane@example.com');
      authRepository.onRegister =
          ({
            required fullName,
            required email,
            required phone,
            required password,
            required role,
            bakeryName,
          }) async => Right(expectedUser);
      final viewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );

      final success = await viewModel.register(
        fullName: 'Jane Baker',
        email: 'jane@example.com',
        phone: '9800000002',
        password: 'secret123',
        role: UserRole.buyer,
      );

      expect(success, isTrue);
      expect(viewModel.state.status, AuthStatus.authenticated);
      expect(viewModel.state.authEntity, expectedUser);
    });

    test('4. register failure sets error state and does not authenticate', () async {
      authRepository.onRegister =
          ({
            required fullName,
            required email,
            required phone,
            required password,
            required role,
            bakeryName,
          }) async => const Left(ApiFailure(message: 'Email already exists'));
      final viewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );

      final success = await viewModel.register(
        fullName: 'Jane Baker',
        email: 'jane@example.com',
        phone: '9800000002',
        password: 'secret123',
        role: UserRole.buyer,
      );

      expect(success, isFalse);
      expect(viewModel.state.status, AuthStatus.error);
      expect(viewModel.state.errorMessage, 'Email already exists');
    });

    test('5. deleteAccount success resets state to unauthenticated', () async {
      authRepository.onDeleteAccount = ({required currentPassword}) async => const Right(true);
      final viewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );

      final success = await viewModel.deleteAccount(currentPassword: 'secret123');

      expect(success, isTrue);
      expect(viewModel.state.status, AuthStatus.unauthenticated);
      expect(viewModel.state.authEntity, isNull);
    });

    test('6. logout always resets state to unauthenticated', () async {
      final viewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );

      await viewModel.logout();

      expect(viewModel.state.status, AuthStatus.unauthenticated);
    });
  });
}
