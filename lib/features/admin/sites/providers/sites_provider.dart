import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/site_model.dart';
import '../services/site_manager.dart';

/// Riverpod ChangeNotifierProvider for SiteManager
final siteManagerProvider = ChangeNotifierProvider<SiteManager>((ref) {
  return SiteManager.instance;
});

/// Reactive list of all active sites
final sitesProvider = Provider<List<SiteModel>>((ref) {
  final manager = ref.watch(siteManagerProvider);
  return manager.sites;
});

/// Reactive currently selected active site name
final activeSiteNameProvider = Provider<String>((ref) {
  final manager = ref.watch(siteManagerProvider);
  return manager.selectedSite;
});
