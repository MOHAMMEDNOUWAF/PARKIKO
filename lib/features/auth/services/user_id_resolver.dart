import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';

/// Secure service responsible for mapping a Parkiko User ID (e.g. `admin1`)
/// to its corresponding Firebase Authentication email identity and preparing
/// credentials for Firebase Authentication without exposing admin credentials.
class UserIdResolver {
  static const String defaultTenantDomain = 'auth.parkiko.internal';

  /// Normalizes an input identifier by trimming whitespace and lowercasing.
  static String normalizeIdentifier(String identifier) {
    return identifier.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  /// Resolves an arbitrary Parkiko User ID to a valid Firebase Authentication email.
  ///
  /// Flow:
  /// 1. If identifier is already a valid email, return as-is.
  /// 2. If connected to Firestore, inspect `user_mappings/{normalizedId}` for custom email.
  /// 3. Fallback to standard enterprise tenant format `${normalizedId}@auth.parkiko.internal`.
  static Future<String> resolveToEmail(String identifier) async {
    final normalized = normalizeIdentifier(identifier);
    if (normalized.contains('@')) {
      return normalized;
    }

    if (FirebaseService.isInitialized) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_mappings')
            .doc(normalized)
            .get();
        if (doc.exists) {
          final data = doc.data();
          final mappedEmail = data?['email'] as String?;
          if (mappedEmail != null && mappedEmail.isNotEmpty) {
            return mappedEmail.trim().toLowerCase();
          }
        }
      } catch (_) {
        // Fall back to tenant domain mapping if lookup fails or offline
      }
    }

    return '$normalized@$defaultTenantDomain';
  }

  /// Prepares a credential password for Firebase Authentication.
  ///
  /// Firebase Authentication strictly requires passwords to be at least 6 characters.
  /// For short operator PINs or passwords under 6 characters (such as 4-digit PINs),
  /// this deterministically derives a compliant secret string using SHA-256 HMAC
  /// with an organizational salt before passing to Firebase Authentication.
  ///
  /// The raw password is NEVER stored in Firestore, local cache, or client source code.
  static String preparePasswordForAuth(String identifier, String rawPassword) {
    if (rawPassword.length >= 6) {
      return rawPassword;
    }

    // Cryptographic key derivation for PINs under 6 characters
    final normalizedId = normalizeIdentifier(identifier);
    final salt = 'parkiko-sec-tenant-$normalizedId-v1';
    final hmacSha256 = Hmac(sha256, utf8.encode(salt));
    final digest = hmacSha256.convert(utf8.encode(rawPassword));
    // Generates a 64-character hex string satisfying Firebase Auth requirements
    return digest.toString();
  }
}
