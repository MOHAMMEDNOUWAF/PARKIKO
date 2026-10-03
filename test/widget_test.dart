import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkiko/app.dart';
import 'package:parkiko/features/auth/models/user_profile.dart';
import 'package:parkiko/features/auth/providers/auth_provider.dart';
import 'package:parkiko/features/auth/services/firebase_auth_service.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(super.authService, [UserProfile? initialProfile]) {
    if (initialProfile != null) {
      state = AsyncData(initialProfile);
    } else {
      state = const AsyncData(null);
    }
  }

  @override
  Future<void> checkInitialSession() async {}

  @override
  Future<AuthResult> signIn({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final clean = identifier.trim().toLowerCase();
    if ((clean == 'admin1' || clean == '8041' || clean == 'pk-8041') &&
        password.trim() == '1234') {
      final profile = UserProfile(
        uid: 'test-admin-uid',
        userId: 'admin1',
        name: 'Parkiko Admin',
        role: 'ADMIN',
        status: 'ACTIVE',
      );
      state = AsyncData(profile);
      return AuthResult.success(profile);
    } else {
      return AuthResult.failure('Invalid User ID or password.');
    }
  }

  @override
  Future<void> signOut() async {
    state = const AsyncData(null);
  }
}

void main() {
  testWidgets('Parkiko LoginScreen initial render and input validation test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => MockAuthNotifier(ref.watch(firebaseAuthServiceProvider), null),
          ),
        ],
        child: const ParkikoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify that LoginScreen renders initial elements
    expect(find.text('Welcome to Parkiko'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // 2. Tap sign in with empty fields - triggers error SnackBar
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your Parkiko User ID.'), findsOneWidget);

    // 3. Enter incorrect credentials - triggers failure SnackBar
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '9999');
    await tester.enterText(textFields.at(1), '0000');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid User ID or password.'), findsOneWidget);

    // 4. Enter valid test admin credentials - successfully logs in and opens Admin dashboard
    await tester.enterText(textFields.at(0), '8041');
    await tester.enterText(textFields.at(1), '1234');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Parkiko'), findsWidgets);
    expect(find.text('Performance Overview'), findsOneWidget);
    expect(find.text('Good Morning, Admin'), findsOneWidget);
  });

  testWidgets('Parkiko Admin session navigation, tabs, and sign-out test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testAdminProfile = UserProfile(
      uid: 'test-admin-uid-100',
      userId: 'admin1',
      name: 'Parkiko Admin',
      role: 'ADMIN',
      status: 'ACTIVE',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => MockAuthNotifier(ref.watch(firebaseAuthServiceProvider), testAdminProfile),
          ),
        ],
        child: const ParkikoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify authenticated directly into Home
    expect(find.text('Parkiko'), findsWidgets);
    expect(find.text('Good Morning, Admin'), findsOneWidget);

    // Navigate to Operations
    await tester.tap(find.text('Operations'));
    await tester.pumpAndSettle();
    expect(find.text('Live Operations'), findsOneWidget);

    // Navigate to Staff
    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    expect(find.text('Staff Management'), findsOneWidget);

    // Navigate to Payments
    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();
    expect(find.text('TOTAL COLLECTIONS'), findsOneWidget);

    // Navigate to More & Sign Out
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More Options'), findsOneWidget);

    expect(find.text('Add Multi-Site'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Navigate back to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Good Morning, Admin'), findsOneWidget);

    // Tap top-right Admin Profile Avatar - should navigate directly to More without popup
    await tester.tap(find.byKey(const Key('admin_profile_avatar_button')));
    await tester.pumpAndSettle();

    // Verify it opened More Options directly
    expect(find.text('More Options'), findsOneWidget);
    // Verify obsolete popup sheet elements do NOT appear
    expect(find.text('Profile Settings'), findsNothing);
    expect(find.text('Switch Terminal Deck'), findsNothing);
  });
}
