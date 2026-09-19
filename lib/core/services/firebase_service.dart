import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// Centralized service managing Firebase initialization and collection constants.
/// Gracefully handles local offline/test environments where native channels or credentials
/// are absent.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initializes Firebase Core with [DefaultFirebaseOptions.currentPlatform].
  /// Returns `true` if connected successfully, or `false` when running in offline fallback mode.
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('[FirebaseService] Firebase initialized successfully.');
      return true;
    } catch (e) {
      debugPrint(
        '[FirebaseService] Running in resilient offline mode: $e',
      );
      _isInitialized = false;
      return false;
    }
  }

  // Firestore collection paths
  static const String ticketsCollection = 'tickets';
  static const String sitesCollection = 'sites';
  static const String staffCollection = 'staff';
  static const String paymentsCollection = 'payments';
}
