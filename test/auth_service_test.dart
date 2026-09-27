import 'package:flutter_test/flutter_test.dart';
import 'package:parkiko/features/auth/models/user_profile.dart';
import 'package:parkiko/features/auth/services/user_id_resolver.dart';

void main() {
  group('UserIdResolver Tests', () {
    test('Normalizes User IDs cleanly', () {
      expect(UserIdResolver.normalizeIdentifier('  admin1  '), 'admin1');
      expect(UserIdResolver.normalizeIdentifier('ADMIN1'), 'admin1');
      expect(UserIdResolver.normalizeIdentifier(' PK-8041 '), 'pk-8041');
    });

    test('Preserves email addresses as-is', () async {
      final email = await UserIdResolver.resolveToEmail('admin@parkiko.com');
      expect(email, 'admin@parkiko.com');
    });

    test('Maps raw User ID to tenant domain email', () async {
      final email = await UserIdResolver.resolveToEmail('admin1');
      expect(email, 'admin1@auth.parkiko.internal');
    });

    test('Prepares password >= 6 characters as-is', () {
      final prepared = UserIdResolver.preparePasswordForAuth('admin1', 'supersecret123');
      expect(prepared, 'supersecret123');
    });

    test('Cryptographically derives passwords < 6 characters to satisfy Firebase Auth', () {
      final pin1234 = UserIdResolver.preparePasswordForAuth('admin1', '1234');
      expect(pin1234.length, greaterThanOrEqualTo(6));
      expect(pin1234.length, 64); // SHA-256 hex digest
      // Deterministic: same input gives exact same derived secret
      expect(UserIdResolver.preparePasswordForAuth('admin1', '1234'), pin1234);
      // Different PIN gives different derived secret
      expect(UserIdResolver.preparePasswordForAuth('admin1', '0000'), isNot(pin1234));
      // Different User ID gives different derived secret (salted)
      expect(UserIdResolver.preparePasswordForAuth('admin2', '1234'), isNot(pin1234));
    });
  });

  group('UserProfile Authorization Verification Tests', () {
    test('Admin user with ACTIVE status is authorized', () {
      final profile = UserProfile(
        uid: 'test-admin-uid',
        userId: 'admin1',
        name: 'Parkiko Admin',
        role: 'ADMIN',
        status: 'ACTIVE',
      );

      expect(profile.isAdmin, isTrue);
      expect(profile.isActive, isTrue);
    });

    test('Non-admin role (e.g. VALET) is NOT authorized as admin', () {
      final valetProfile = UserProfile(
        uid: 'valet-uid',
        userId: 'valet104',
        name: 'Arjun S.',
        role: 'VALET',
        status: 'ACTIVE',
      );

      expect(valetProfile.isAdmin, isFalse);
      expect(valetProfile.isActive, isTrue);
    });

    test('Admin user with INACTIVE or SUSPENDED status is NOT authorized', () {
      final suspendedProfile = UserProfile(
        uid: 'admin-suspended-uid',
        userId: 'admin2',
        name: 'Suspended Admin',
        role: 'ADMIN',
        status: 'SUSPENDED',
      );

      expect(suspendedProfile.isAdmin, isTrue);
      expect(suspendedProfile.isActive, isFalse);
    });

    test('Serializes to and from Map correctly', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'uid-12345',
        userId: 'admin1',
        name: 'Parkiko Admin',
        role: 'ADMIN',
        status: 'ACTIVE',
        organizationId: 'org-001',
        locationIds: ['loc-t2', 'loc-deck-a'],
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['uid'], 'uid-12345');
      expect(map['userId'], 'admin1');
      expect(map['role'], 'ADMIN');
      expect(map['status'], 'ACTIVE');

      final reconstructed = UserProfile.fromMap(map, 'uid-12345');
      expect(reconstructed.uid, profile.uid);
      expect(reconstructed.userId, profile.userId);
      expect(reconstructed.isAdmin, isTrue);
      expect(reconstructed.isActive, isTrue);
      expect(reconstructed.locationIds, ['loc-t2', 'loc-deck-a']);
    });
  });
}
