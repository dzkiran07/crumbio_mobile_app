import 'package:crumbio_mobile_app/core/error/failures.dart';
import 'package:crumbio_mobile_app/core/services/security/biometric_auth_service.dart';
import 'package:crumbio_mobile_app/core/services/storage/user_session_service.dart';
import 'package:crumbio_mobile_app/features/auth/domain/entities/auth_entity.dart';
import 'package:crumbio_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/get_current_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/domain/usecases/upload_profile_image_usecase.dart';
import 'package:crumbio_mobile_app/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:crumbio_mobile_app/features/marketplace/domain/entities/product_entity.dart';
import 'package:crumbio_mobile_app/features/marketplace/domain/entities/product_variant.dart';
import 'package:crumbio_mobile_app/features/marketplace/domain/repositories/product_repository.dart';
import 'package:crumbio_mobile_app/features/orders/domain/entities/order_entity.dart';
import 'package:crumbio_mobile_app/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:local_auth/local_auth.dart';

/// A configurable fake of [IAuthRepository] — every method can be overridden
/// per-test via the `onX` callbacks; otherwise it returns a canned success.
class FakeAuthRepository implements IAuthRepository {
  FakeAuthRepository({
    this.onRegister,
    this.onLogin,
    this.onGetCurrentUser,
    this.onUpdateProfile,
    this.onUploadProfileImage,
    this.onChangePassword,
    this.onDeleteAccount,
    this.onLogout,
  });

  Future<Either<Failure, AuthEntity>> Function({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? bakeryName,
  })?
  onRegister;

  Future<Either<Failure, AuthEntity>> Function({
    required String email,
    required String password,
  })?
  onLogin;

  Future<Either<Failure, AuthEntity>> Function()? onGetCurrentUser;

  Future<Either<Failure, AuthEntity>> Function({
    String? fullName,
    String? phone,
    String? address,
  })?
  onUpdateProfile;

  Future<Either<Failure, AuthEntity>> Function(String filePath)? onUploadProfileImage;

  Future<Either<Failure, bool>> Function({
    required String currentPassword,
    required String newPassword,
  })?
  onChangePassword;

  Future<Either<Failure, bool>> Function({required String currentPassword})? onDeleteAccount;

  Future<Either<Failure, bool>> Function()? onLogout;

  @override
  Future<Either<Failure, AuthEntity>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? bakeryName,
  }) {
    if (onRegister != null) {
      return onRegister!(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
        bakeryName: bakeryName,
      );
    }
    return Future.value(
      Right(sampleAuthEntity(fullName: fullName, email: email, phone: phone)),
    );
  }

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) {
    if (onLogin != null) return onLogin!(email: email, password: password);
    return Future.value(Right(sampleAuthEntity(email: email)));
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() {
    if (onGetCurrentUser != null) return onGetCurrentUser!();
    return Future.value(Right(sampleAuthEntity()));
  }

  @override
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) {
    if (onUpdateProfile != null) {
      return onUpdateProfile!(fullName: fullName, phone: phone, address: address);
    }
    return Future.value(
      Right(sampleAuthEntity(fullName: fullName ?? 'Test User', phone: phone ?? '9800000000')),
    );
  }

  @override
  Future<Either<Failure, AuthEntity>> uploadProfileImage(String filePath) {
    if (onUploadProfileImage != null) return onUploadProfileImage!(filePath);
    return Future.value(Right(sampleAuthEntity(profileImage: filePath)));
  }

  @override
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    if (onChangePassword != null) {
      return onChangePassword!(currentPassword: currentPassword, newPassword: newPassword);
    }
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, bool>> deleteAccount({required String currentPassword}) {
    if (onDeleteAccount != null) return onDeleteAccount!(currentPassword: currentPassword);
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, bool>> logout() {
    if (onLogout != null) return onLogout!();
    return Future.value(const Right(true));
  }
}

class FakeProductRepository implements ProductRepository {
  FakeProductRepository({this.onGetProducts});

  Future<List<ProductEntity>> Function({String? category, String? search})? onGetProducts;

  @override
  Future<List<ProductEntity>> getProducts({String? category, String? search}) {
    if (onGetProducts != null) return onGetProducts!(category: category, search: search);
    return Future.value([sampleProductEntity()]);
  }
}

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({this.onCreateOrder, this.onGetMyOrders});

  Future<OrderEntity> Function(CreateOrderParams params)? onCreateOrder;
  Future<List<OrderEntity>> Function()? onGetMyOrders;

  @override
  Future<OrderEntity> createOrder(CreateOrderParams params) {
    if (onCreateOrder != null) return onCreateOrder!(params);
    return Future.value(sampleOrderEntity());
  }

  @override
  Future<List<OrderEntity>> getMyOrders() {
    if (onGetMyOrders != null) return onGetMyOrders!();
    return Future.value([sampleOrderEntity()]);
  }
}

/// Overrides every secure-storage-backed method with an in-memory
/// implementation so widget/unit tests never touch platform channels.
class FakeUserSessionService extends UserSessionService {
  String? currentUserId = 'user-1';
  String? token;
  bool biometricEnabled;
  bool biometricCredentialsAvailable;
  BiometricCredentials? storedCredentials;

  int syncBiometricStateAfterLoginCalls = 0;
  int saveBiometricCredentialsCalls = 0;

  FakeUserSessionService({
    this.biometricEnabled = false,
    this.biometricCredentialsAvailable = false,
    this.storedCredentials,
  });

  @override
  Future<void> saveToken(String token) async => this.token = token;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveCurrentUserId(String userId) async => currentUserId = userId;

  @override
  Future<String?> getCurrentUserId() async => currentUserId;

  @override
  Future<void> clearSession() async {
    token = null;
    currentUserId = null;
  }

  @override
  Future<bool> isBiometricLoginEnabled() async => biometricEnabled;

  @override
  Future<bool> isBiometricLoginEnabledForCurrentUser() async => biometricEnabled;

  @override
  Future<void> setBiometricLoginEnabled(bool enabled) async => biometricEnabled = enabled;

  @override
  Future<bool> hasBiometricCredentials() async => biometricCredentialsAvailable;

  @override
  Future<bool> hasBiometricCredentialsForCurrentUser() async => biometricCredentialsAvailable;

  @override
  Future<void> syncBiometricStateAfterLogin({required String loggedInUserId}) async {
    syncBiometricStateAfterLoginCalls += 1;
  }

  @override
  Future<void> saveBiometricCredentials({required String email, required String password}) async {
    saveBiometricCredentialsCalls += 1;
    storedCredentials = BiometricCredentials(email: email, password: password);
  }

  @override
  Future<BiometricCredentials?> getBiometricCredentials() async => storedCredentials;

  @override
  Future<void> clearBiometricLoginSetup() async {
    biometricEnabled = false;
    biometricCredentialsAvailable = false;
    storedCredentials = null;
  }
}

class FakeBiometricAuthService extends BiometricAuthService {
  FakeBiometricAuthService({
    this.canUseBiometricLoginResult = false,
    this.authenticateResult = true,
  }) : super(localAuthentication: LocalAuthentication());

  bool canUseBiometricLoginResult;
  bool authenticateResult;

  @override
  Future<bool> canUseBiometricLogin() async => canUseBiometricLoginResult;

  @override
  Future<bool> authenticate({required String reason}) async => authenticateResult;
}

AuthViewModel buildTestAuthViewModel({
  required IAuthRepository repository,
  required FakeUserSessionService userSessionService,
}) {
  return AuthViewModel(
    loginUsecase: LoginUsecase(authRepository: repository),
    registerUsecase: RegisterUsecase(authRepository: repository),
    logoutUsecase: LogoutUsecase(authRepository: repository),
    getCurrentUserUsecase: GetCurrentUserUsecase(authRepository: repository),
    updateProfileUsecase: UpdateProfileUsecase(authRepository: repository),
    uploadProfileImageUsecase: UploadProfileImageUsecase(authRepository: repository),
    changePasswordUsecase: ChangePasswordUsecase(authRepository: repository),
    deleteAccountUsecase: DeleteAccountUsecase(authRepository: repository),
    userSessionService: userSessionService,
  );
}

AuthEntity sampleAuthEntity({
  String id = 'auth-1',
  String fullName = 'Test User',
  String email = 'test@example.com',
  String phone = '9800000001',
  UserRole role = UserRole.buyer,
  String? bakeryName,
  String? address,
  String? profileImage,
  bool isActive = true,
}) {
  return AuthEntity(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    role: role,
    bakeryName: bakeryName,
    address: address,
    profileImage: profileImage,
    isActive: isActive,
  );
}

ProductEntity sampleProductEntity({
  String id = 'product-1',
  String name = 'Sourdough Bread',
  double basePrice = 350,
  String image = 'sourdough_bread.png',
  String category = 'Bread',
  String description = 'Freshly baked sourdough bread.',
  String bakerName = 'Test Bakery',
  String availability = 'available',
  List<ProductVariant>? variants,
}) {
  return ProductEntity(
    id: id,
    name: name,
    basePrice: basePrice,
    image: image,
    category: category,
    description: description,
    bakerName: bakerName,
    availability: availability,
    variants: variants ?? [ProductVariant(size: 'Regular', price: basePrice, stock: 10)],
  );
}

OrderEntity sampleOrderEntity({
  String id = 'order-1',
  List<OrderItemEntity>? items,
  double totalAmount = 350,
  String status = 'pending',
  String fulfillmentType = 'pickup',
  String? deliveryAddress,
  String? pickupNote,
  String paymentMethod = 'cash_on_delivery',
  String paymentStatus = 'unpaid',
  DateTime? createdAt,
}) {
  return OrderEntity(
    id: id,
    items:
        items ??
        [
          OrderItemEntity(
            productId: 'product-1',
            productName: 'Sourdough Bread',
            size: 'Regular',
            unitPrice: 350,
            quantity: 1,
          ),
        ],
    totalAmount: totalAmount,
    status: status,
    fulfillmentType: fulfillmentType,
    deliveryAddress: deliveryAddress,
    pickupNote: pickupNote,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}
