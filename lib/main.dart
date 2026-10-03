import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_service.dart';
import 'features/drivers/services/driver_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  DriverService.instance.ensureFirestoreStream();
  runApp(
    const ProviderScope(
      child: ParkikoApp(),
    ),
  );
}
