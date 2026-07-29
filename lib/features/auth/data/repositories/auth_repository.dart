import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    remoteDatasource: ref.read(authRemoteDatasourceProvider),
    localDatasource: ref.read(authLocalDatasourceProvider),
  );
});

class AuthRepository implements IAuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;

  AuthRepository({
    required AuthRemoteDatasource remoteDatasource,
    required AuthLocalDatasource localDatasource,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource;

  @override
  Future<Either<Failure, AuthEntity>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? bakeryName,
  }) async {
    try {
      final result = await _remoteDatasource.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role.name,
        bakeryName: bakeryName,
      );
      await _localDatasource.cacheSession(user: result.user, token: result.token);
      return Right(result.user.toEntity());
    } on Exception catch (e) {
      return Left(ApiFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDatasource.login(email: email, password: password);
      await _localDatasource.cacheSession(user: result.user, token: result.token);
      return Right(result.user.toEntity());
    } on Exception catch (e) {
      return Left(ApiFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    final cached = _localDatasource.getCachedUser();
    if (cached != null) return Right(cached.toEntity());

    try {
      final user = await _remoteDatasource.getCurrentUser();
      return Right(user.toEntity());
    } on Exception catch (e) {
      return Left(ApiFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    try {
      final user = await _remoteDatasource.updateProfile(
        fullName: fullName,
        phone: phone,
        address: address,
      );
      await _localDatasource.cacheUser(user);
      return Right(user.toEntity());
    } on Exception catch (e) {
      return Left(ApiFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> uploadProfileImage(String filePath) async {
    try {
      final user = await _remoteDatasource.uploadProfileImage(filePath);
      await _localDatasource.cacheUser(user);
      return Right(user.toEntity());
    } on Exception catch (e) {
      return Left(ApiFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDatasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(true);
    } on Exception catch (e) {
      return Left(ApiFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAccount({required String currentPassword}) async {
    try {
      await _remoteDatasource.deleteAccount(currentPassword: currentPassword);
      await _localDatasource.clearBiometricDataForCurrentUser();
      await _localDatasource.clearSession();
      return const Right(true);
    } on Exception catch (e) {
      return Left(ApiFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await _localDatasource.clearSession();
      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

}
