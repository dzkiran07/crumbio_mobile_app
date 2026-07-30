import 'package:crumbio_mobile_app/features/auth/domain/entities/auth_entity.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/get_current_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/upload_profile_image_usecase.dart';
import 'package:crumbio_mobile_app/features/marketplace/domain/usecases/product_usecase.dart';
import 'package:crumbio_mobile_app/features/orders/domain/repositories/order_repository.dart';
import 'package:crumbio_mobile_app/features/orders/domain/usecases/order_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fakes.dart';

void main() {
  group('Usecase unit tests', () {
    test('1. LoginUsecase delegates to repository login', () async {
      String? receivedEmail;
      String? receivedPassword;
      final expected = sampleAuthEntity(email: 'user@example.com');

      final repository = FakeAuthRepository(
        onLogin: ({required email, required password}) async {
          receivedEmail = email;
          receivedPassword = password;
          return Right(expected);
        },
      );
      final usecase = LoginUsecase(authRepository: repository);

      final result = await usecase(
        const LoginUsecaseParams(email: 'user@example.com', password: 'secret123'),
      );

      expect(result, Right(expected));
      expect(receivedEmail, 'user@example.com');
      expect(receivedPassword, 'secret123');
    });

    test('2. RegisterUsecase delegates all fields to repository register', () async {
      String? capturedFullName;
      UserRole? capturedRole;

      final repository = FakeAuthRepository(
        onRegister:
            ({
              required fullName,
              required email,
              required phone,
              required password,
              required role,
              bakeryName,
            }) async {
              capturedFullName = fullName;
              capturedRole = role;
              return Right(sampleAuthEntity(fullName: fullName, email: email));
            },
      );
      final usecase = RegisterUsecase(authRepository: repository);

      final result = await usecase(
        const RegisterUsecaseParams(
          fullName: 'Jane Baker',
          email: 'jane@example.com',
          phone: '9800000002',
          password: 'pass1234',
          role: UserRole.buyer,
        ),
      );

      expect(result.isRight(), isTrue);
      expect(capturedFullName, 'Jane Baker');
      expect(capturedRole, UserRole.buyer);
    });

    test('3. GetCurrentUserUsecase delegates to repository getCurrentUser', () async {
      final expected = sampleAuthEntity(id: 'auth-9');
      final repository = FakeAuthRepository(onGetCurrentUser: () async => Right(expected));
      final usecase = GetCurrentUserUsecase(authRepository: repository);

      final result = await usecase();

      expect(result, Right(expected));
    });

    test('4. UpdateProfileUsecase forwards fullName/phone/address', () async {
      String? capturedPhone;
      final repository = FakeAuthRepository(
        onUpdateProfile: ({fullName, phone, address}) async {
          capturedPhone = phone;
          return Right(sampleAuthEntity(phone: phone ?? ''));
        },
      );
      final usecase = UpdateProfileUsecase(authRepository: repository);

      await usecase(phone: '9811111111');

      expect(capturedPhone, '9811111111');
    });

    test('5. UploadProfileImageUsecase forwards the file path', () async {
      String? capturedPath;
      final repository = FakeAuthRepository(
        onUploadProfileImage: (filePath) async {
          capturedPath = filePath;
          return Right(sampleAuthEntity(profileImage: filePath));
        },
      );
      final usecase = UploadProfileImageUsecase(authRepository: repository);

      await usecase('/tmp/avatar.jpg');

      expect(capturedPath, '/tmp/avatar.jpg');
    });

    test('6. ChangePasswordUsecase delegates with exact arguments', () async {
      String? capturedCurrentPassword;
      String? capturedNewPassword;
      final repository = FakeAuthRepository(
        onChangePassword: ({required currentPassword, required newPassword}) async {
          capturedCurrentPassword = currentPassword;
          capturedNewPassword = newPassword;
          return const Right(true);
        },
      );
      final usecase = ChangePasswordUsecase(authRepository: repository);

      final result = await usecase(currentPassword: 'old12345', newPassword: 'new12345');

      expect(result, const Right(true));
      expect(capturedCurrentPassword, 'old12345');
      expect(capturedNewPassword, 'new12345');
    });

    test('7. DeleteAccountUsecase delegates the current password', () async {
      String? capturedPassword;
      final repository = FakeAuthRepository(
        onDeleteAccount: ({required currentPassword}) async {
          capturedPassword = currentPassword;
          return const Right(true);
        },
      );
      final usecase = DeleteAccountUsecase(authRepository: repository);

      final result = await usecase(currentPassword: 'secret123');

      expect(result, const Right(true));
      expect(capturedPassword, 'secret123');
    });

    test('8. LogoutUsecase delegates to repository logout', () async {
      var called = false;
      final repository = FakeAuthRepository(
        onLogout: () async {
          called = true;
          return const Right(true);
        },
      );
      final usecase = LogoutUsecase(authRepository: repository);

      final result = await usecase();

      expect(result, const Right(true));
      expect(called, isTrue);
    });

    test('9. GetProductsUseCase forwards category/search filters', () async {
      String? capturedCategory;
      String? capturedSearch;
      final repository = FakeProductRepository(
        onGetProducts: ({category, search}) async {
          capturedCategory = category;
          capturedSearch = search;
          return [sampleProductEntity(name: 'Cinnamon Roll')];
        },
      );
      final usecase = GetProductsUseCase(repository);

      final result = await usecase(category: 'Pastry', search: 'cinnamon');

      expect(result, hasLength(1));
      expect(result.first.name, 'Cinnamon Roll');
      expect(capturedCategory, 'Pastry');
      expect(capturedSearch, 'cinnamon');
    });

    test('10. CreateOrderUseCase delegates order params to repository', () async {
      CreateOrderParams? capturedParams;
      final repository = FakeOrderRepository(
        onCreateOrder: (params) async {
          capturedParams = params;
          return sampleOrderEntity(id: 'order-42');
        },
      );
      final usecase = CreateOrderUseCase(repository);
      final params = CreateOrderParams(
        items: [
          CreateOrderItemParams(productId: 'product-1', size: 'Regular', quantity: 2),
        ],
        fulfillmentType: 'delivery',
        deliveryAddress: 'Kathmandu',
        paymentMethod: 'cash_on_delivery',
      );

      final result = await usecase(params);

      expect(result.id, 'order-42');
      expect(capturedParams, same(params));
    });

  });
}
