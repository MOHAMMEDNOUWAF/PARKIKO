import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/firebase_auth_service.dart';

/// State of the active authenticated user profile.
final currentUserProfileProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final FirebaseAuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncLoading()) {
    checkInitialSession();
  }

  /// Checks if an active authenticated Firebase session exists on app boot.
  Future<void> checkInitialSession() async {
    try {
      final profile = await _authService.getCurrentUserProfile().timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
      if (profile != null && profile.isAuthorized && profile.isActive) {
        state = AsyncData(profile);
      } else {
        if (profile != null && (!profile.isAuthorized || !profile.isActive)) {
          await _authService.signOut();
        }
        state = const AsyncData(null);
      }
    } catch (_) {
      state = const AsyncData(null);
    }
  }

  /// Signs in using the Parkiko User ID and password.
  Future<AuthResult> signIn({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final result = await _authService.signInWithIdentifier(
      identifier: identifier,
      password: password,
      rememberMe: rememberMe,
    );

    if (result.isSuccess && result.profile != null) {
      state = AsyncData(result.profile);
    }
    return result;
  }

  /// Terminates the Firebase Authentication session.
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncData(null);
  }

  /// Bypasses authentication for debug and automated test environments (Admin).
  void devBypassLogin() {
    state = const AsyncData(
      UserProfile(
        uid: 'dev-admin-id',
        userId: 'PK-ADMIN',
        name: 'Terminal Admin',
        role: 'ADMIN',
        status: 'ACTIVE',
        organizationId: 'Grand Hyatt & Convention',
        locationIds: ['Grand Hyatt & Convention'],
      ),
    );
  }

  /// Bypasses manager authentication for debug and automated test environments.
  void devBypassManagerLogin() {
    state = const AsyncData(
      UserProfile(
        uid: 'dev-mgr-101',
        userId: 'MGR-101',
        name: 'Vikram Malhotra',
        role: 'MANAGER',
        status: 'ACTIVE',
        organizationId: 'Grand Hyatt & Convention',
        locationIds: ['Grand Hyatt & Convention'],
      ),
    );
  }

  /// Bypasses assistant manager authentication for debug and automated test environments.
  void devBypassAssistantManagerLogin() {
    state = const AsyncData(
      UserProfile(
        uid: 'dev-asst-101',
        userId: 'ASST-101',
        name: 'Farhan Akhtar',
        role: 'ASST_MGR',
        status: 'ACTIVE',
        organizationId: 'Grand Hyatt • Deck B1',
        locationIds: ['Grand Hyatt • Deck B1'],
      ),
    );
  }

  /// Bypasses driver authentication for debug and automated test environments.
  void devBypassDriverLogin() {
    state = const AsyncData(
      UserProfile(
        uid: 'dev-driver-108',
        userId: 'ST-108',
        name: 'Rahul V.',
        role: 'DRIVER',
        status: 'ACTIVE',
        organizationId: 'Terminal 2',
        locationIds: ['Terminal 2'],
      ),
    );
  }
}
