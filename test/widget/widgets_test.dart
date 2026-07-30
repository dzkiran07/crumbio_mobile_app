import 'package:crumbio_mobile_app/core/services/security/biometric_auth_service.dart';
import 'package:crumbio_mobile_app/core/services/storage/user_session_service.dart';
import 'package:crumbio_mobile_app/features/auth/presentation/pages/login_screen.dart';
import 'package:crumbio_mobile_app/features/auth/presentation/pages/register_screen.dart';
import 'package:crumbio_mobile_app/features/auth/presentation/state/auth_state.dart';
import 'package:crumbio_mobile_app/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:crumbio_mobile_app/features/marketplace/presentation/pages/button_navigation.dart';
import 'package:crumbio_mobile_app/features/marketplace/presentation/pages/cart_screen.dart';
import 'package:crumbio_mobile_app/features/marketplace/presentation/pages/checkout_screen.dart';
import 'package:crumbio_mobile_app/features/marketplace/presentation/pages/order_screen.dart';
import 'package:crumbio_mobile_app/features/marketplace/presentation/state/cart_provider.dart';
import 'package:crumbio_mobile_app/features/marketplace/presentation/state/product_provider.dart';
import 'package:crumbio_mobile_app/features/marketplace/domain/usecases/product_usecase.dart';
import 'package:crumbio_mobile_app/features/onboarding/presentation/pages/onboarding_one.dart';
import 'package:crumbio_mobile_app/features/onboarding/presentation/pages/onboarding_two.dart';
import 'package:crumbio_mobile_app/features/orders/domain/usecases/order_usecase.dart';
import 'package:crumbio_mobile_app/features/orders/presentation/state/order_provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_fakes.dart';
import '../helpers/test_widget_helpers.dart';

List<Override> _authOverrides({
  FakeAuthRepository? repository,
  FakeUserSessionService? userSessionService,
}) {
  final userSession = userSessionService ?? FakeUserSessionService();
  final authViewModel = buildTestAuthViewModel(
    repository: repository ?? FakeAuthRepository(),
    userSessionService: userSession,
  );

  return [
    userSessionServiceProvider.overrideWithValue(userSession),
    biometricAuthServiceProvider.overrideWithValue(
      FakeBiometricAuthService(canUseBiometricLoginResult: false),
    ),
    authViewModelProvider.overrideWith((ref) => authViewModel),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingOne widget tests', () {
    testWidgets('1. renders welcome title and Next button', (tester) async {
      await pumpTestApp(tester, const OnboardingOne());

      expect(find.text('Welcome to Crumbio'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
    });

    testWidgets('2. tapping Skip navigates to LoginScreen', (tester) async {
      await pumpTestApp(tester, const OnboardingOne(), overrides: _authOverrides());

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OnboardingOne), findsNothing);
    });

    testWidgets('3. tapping Next navigates to OnboardingTwo', (tester) async {
      await pumpTestApp(tester, const OnboardingOne());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingTwo), findsOneWidget);
    });
  });

  group('LoginScreen widget tests', () {
    testWidgets('4. renders form fields and the Login button', (tester) async {
      await pumpTestApp(tester, const LoginScreen(), overrides: _authOverrides());

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('5. validates empty email and password', (tester) async {
      await pumpTestApp(tester, const LoginScreen(), overrides: _authOverrides());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('6. toggles password visibility', (tester) async {
      await pumpTestApp(tester, const LoginScreen(), overrides: _authOverrides());

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('7. hides the fingerprint button when biometric login is disabled', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const LoginScreen(),
        overrides: _authOverrides(
          userSessionService: FakeUserSessionService(biometricEnabled: false),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
    });

    testWidgets('8. navigates to RegisterScreen when Register is tapped', (tester) async {
      await pumpTestApp(tester, const LoginScreen(), overrides: _authOverrides());

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('RegisterScreen widget tests', () {
    testWidgets('9. renders all registration fields and the Register button', (tester) async {
      await pumpTestApp(tester, const RegisterScreen(), overrides: _authOverrides());

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    });

    testWidgets('10. validates empty required fields', (tester) async {
      await pumpTestApp(tester, const RegisterScreen(), overrides: _authOverrides());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone is required'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('11. successful registration reaches the authenticated state', (tester) async {
      final repository = FakeAuthRepository(
        onRegister:
            ({
              required fullName,
              required email,
              required phone,
              required password,
              required role,
              bakeryName,
            }) async => Right(sampleAuthEntity(fullName: fullName, email: email)),
      );
      final authViewModel = buildTestAuthViewModel(
        repository: repository,
        userSessionService: FakeUserSessionService(),
      );

      await pumpTestApp(
        tester,
        const RegisterScreen(),
        overrides: [
          userSessionServiceProvider.overrideWithValue(FakeUserSessionService()),
          biometricAuthServiceProvider.overrideWithValue(FakeBiometricAuthService()),
          authViewModelProvider.overrideWith((ref) => authViewModel),
          // On success this screen navigates into ButtonNavigation, which
          // renders HomeScreen underneath — stub its real productProvider
          // out so no live network call is left running once the test ends.
          productProvider.overrideWith(
            (ref) => ProductNotifier(
              GetProductsUseCase(
                FakeProductRepository(
                  onGetProducts: ({category, search}) async => [
                    sampleProductEntity(image: ''),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Jane Baker');
      await tester.enterText(find.byType(TextFormField).at(1), 'jane@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '9800000002');
      await tester.enterText(find.byType(TextFormField).at(3), 'secret123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(authViewModel.state.status, AuthStatus.authenticated);
      expect(authViewModel.state.authEntity?.fullName, 'Jane Baker');
      expect(authViewModel.state.errorMessage, isNull);
      expect(find.byType(ButtonNavigation), findsOneWidget);
    });
  });

  group('CartScreen widget tests', () {
    testWidgets('12. shows the empty state and handles the start-shopping callback', (
      tester,
    ) async {
      var tapped = false;

      await pumpTestApp(
        tester,
        CartScreen(onStartShopping: () => tapped = true),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Shopping'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('13. lists cart items with the correct subtotal', (tester) async {
      final cartNotifier = CartNotifier();
      cartNotifier.addItem(
        const CartProduct(
          id: 'p1',
          name: 'Cinnamon Roll',
          price: 150,
          image: '',
          size: 'Regular',
          quantity: 2,
        ),
      );

      await pumpTestApp(
        tester,
        const CartScreen(),
        overrides: [cartProvider.overrideWith((ref) => cartNotifier)],
      );

      expect(find.text('Cinnamon Roll'), findsOneWidget);
      expect(find.text('Rs 300'), findsOneWidget);
    });

    testWidgets('14. dismissing an item removes it and shows an undo snackbar', (tester) async {
      final cartNotifier = CartNotifier();
      cartNotifier.addItem(
        const CartProduct(
          id: 'p1',
          name: 'Garlic Breadsticks',
          price: 200,
          image: '',
          size: 'Regular',
          quantity: 1,
        ),
      );

      await pumpTestApp(
        tester,
        const CartScreen(),
        overrides: [cartProvider.overrideWith((ref) => cartNotifier)],
      );

      await tester.drag(find.text('Garlic Breadsticks'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Garlic Breadsticks removed from cart'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);

      // The snackbar schedules a Future.delayed(3s) self-close timer; let it
      // fire so the test doesn't end with a pending Timer.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('15. incrementing quantity updates the item total', (tester) async {
      final cartNotifier = CartNotifier();
      cartNotifier.addItem(
        const CartProduct(
          id: 'p1',
          name: 'Butter Cookie',
          price: 100,
          image: '',
          size: 'Regular',
          quantity: 1,
        ),
      );

      await pumpTestApp(
        tester,
        const CartScreen(),
        overrides: [cartProvider.overrideWith((ref) => cartNotifier)],
      );

      expect(find.text('Total: Rs 100'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Total: Rs 200'), findsOneWidget);
    });
  });

  group('CheckoutScreen widget tests', () {
    List<Override> checkoutOverrides() {
      final cartNotifier = CartNotifier();
      cartNotifier.addItem(
        const CartProduct(
          id: 'p1',
          name: 'Red Velvet Cupcake',
          price: 120,
          image: '',
          size: 'Regular',
          quantity: 1,
        ),
      );
      return [
        cartProvider.overrideWith((ref) => cartNotifier),
        createOrderUsecaseProvider.overrideWithValue(
          CreateOrderUseCase(FakeOrderRepository()),
        ),
        myOrdersProvider.overrideWith(
          (ref) => MyOrdersNotifier(GetMyOrdersUseCase(FakeOrderRepository())),
        ),
      ];
    }

    testWidgets('16. selecting Delivery reveals the delivery address field', (tester) async {
      await pumpTestApp(tester, const CheckoutScreen(), overrides: checkoutOverrides());

      expect(find.text('Delivery Address *'), findsNothing);
      await tester.tap(find.text('Delivery'));
      await tester.pump();

      expect(find.text('Delivery Address *'), findsOneWidget);
    });

    testWidgets('17. selecting Khalti marks that payment chip selected', (tester) async {
      await pumpTestApp(tester, const CheckoutScreen(), overrides: checkoutOverrides());

      await tester.tap(find.text('Khalti'));
      await tester.pump();

      final khaltiChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('Khalti'), matching: find.byType(ChoiceChip)),
      );
      expect(khaltiChip.selected, isTrue);
    });

    testWidgets('18. shows the correct subtotal, delivery fee and total', (tester) async {
      await pumpTestApp(tester, const CheckoutScreen(), overrides: checkoutOverrides());

      expect(find.text('Rs 120'), findsWidgets);
      expect(find.text('Rs 0'), findsOneWidget);

      await tester.tap(find.text('Delivery'));
      await tester.pump();

      expect(find.text('Rs 60'), findsOneWidget);
      expect(find.text('Rs 180'), findsOneWidget);
    });
  });

  group('OrderScreen widget tests', () {
    testWidgets('19. shows the not-logged-in empty state with a Login button', (tester) async {
      await pumpTestApp(tester, const OrderScreen(), overrides: _authOverrides());

      expect(find.text("You're not logged in"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('20. shows an order card with the correct status badge for a logged-in user', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository();
      final userSessionService = FakeUserSessionService();
      final authViewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );
      await authViewModel.login(email: 'user@example.com', password: 'secret123');

      await pumpTestApp(
        tester,
        const OrderScreen(),
        overrides: [
          userSessionServiceProvider.overrideWithValue(userSessionService),
          biometricAuthServiceProvider.overrideWithValue(FakeBiometricAuthService()),
          authViewModelProvider.overrideWith((ref) => authViewModel),
          myOrdersProvider.overrideWith(
            (ref) => MyOrdersNotifier(
              GetMyOrdersUseCase(
                FakeOrderRepository(
                  onGetMyOrders: () async => [sampleOrderEntity(status: 'baking')],
                ),
              ),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // 'Baking' appears twice: once as the status filter chip label, once
      // as the order card's status badge.
      expect(find.text('Baking'), findsNWidgets(2));
    });
  });
}
