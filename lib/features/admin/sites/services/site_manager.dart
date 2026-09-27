import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/site_model.dart';

/// Centralized Manager for Multi-Site Valet Network
/// Manages reactive state across all pages and syncs with Firestore
class SiteManager extends ChangeNotifier {
  static final SiteManager instance = SiteManager._internal();

  SiteManager._internal() {
    _initFirestoreSync();
  }

  final List<SiteModel> _sites = [
    SiteModel(
      id: 'site-1',
      name: 'Grand Hyatt & Convention',
      address: 'BKC Main Avenue, Mumbai',
      totalBays: 120,
      createdAt: DateTime.now(),
    ),
    SiteModel(
      id: 'site-2',
      name: 'Phoenix Palladium Mall',
      address: 'Lower Parel, Mumbai',
      totalBays: 85,
      createdAt: DateTime.now(),
    ),
  ];
  String _selectedSite = 'All Sites';
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSubscription;

  List<SiteModel> get sites => List.unmodifiable(_sites);
  List<String> get siteNames => _sites.map((s) => s.name).toList();
  String get selectedSite => _selectedSite;
  bool get hasSites => _sites.isNotEmpty;
  int get siteCount => _sites.length;

  int get totalActiveBays => _sites.fold<int>(0, (acc, s) => acc + s.totalBays);

  SiteModel? get currentSiteModel {
    if (_sites.isEmpty) return null;
    if (_selectedSite == 'All Sites' || _selectedSite.startsWith('All Sites')) return null;
    try {
      return _sites.firstWhere((s) => s.name == _selectedSite);
    } catch (_) {
      return null;
    }
  }

  void selectSite(String name) {
    if (_selectedSite != name) {
      _selectedSite = name;
      notifyListeners();
    }
  }

  set selectedSite(String name) {
    selectSite(name);
  }

  void addSite(SiteModel site) {
    final existingIndex = _sites.indexWhere((s) => s.id == site.id || s.name.toLowerCase() == site.name.toLowerCase());
    if (existingIndex != -1) {
      _sites[existingIndex] = site;
    } else {
      _sites.add(site);
    }

    // If no specific site was selected yet or this is the first site, select it
    if (_selectedSite == 'All Sites' || _selectedSite == 'No Site Configured' || _selectedSite == 'No Site Selected') {
      _selectedSite = site.name;
    }

    notifyListeners();
    _saveToFirestore(site);
  }

  void updateSite(SiteModel site) {
    final idx = _sites.indexWhere((s) => s.id == site.id);
    if (idx != -1) {
      _sites[idx] = site;
      notifyListeners();
      _saveToFirestore(site);
    }
  }

  void deleteSite(String id) {
    final removed = _sites.firstWhere(
      (s) => s.id == id,
      orElse: () => SiteModel(id: '', name: '', address: '', totalBays: 0, createdAt: DateTime.now()),
    );
    _sites.removeWhere((s) => s.id == id);
    if (_selectedSite == removed.name) {
      _selectedSite = _sites.isNotEmpty ? _sites.first.name : 'All Sites';
    }
    notifyListeners();
    _deleteFromFirestore(id);
  }

  void clearAllSites() {
    _sites.clear();
    _selectedSite = 'All Sites';
    notifyListeners();
  }

  Future<void> _saveToFirestore(SiteModel site) async {
    try {
      await FirebaseFirestore.instance.collection('sites').doc(site.id).set(site.toMap());
    } catch (e) {
      debugPrint('[SiteManager] Firestore sync notice: $e');
    }
  }

  Future<void> _deleteFromFirestore(String id) async {
    try {
      await FirebaseFirestore.instance.collection('sites').doc(id).delete();
    } catch (e) {
      debugPrint('[SiteManager] Firestore delete notice: $e');
    }
  }

  void _initFirestoreSync() {
    try {
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('sites')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final remoteSites = snapshot.docs.map((doc) {
              return SiteModel.fromMap(doc.data(), doc.id);
            }).toList();

            _sites.clear();
            _sites.addAll(remoteSites);

            // Ensure selected site is valid
            if (_selectedSite.isNotEmpty && !_selectedSite.startsWith('All Sites')) {
              final exists = _sites.any((s) => s.name == _selectedSite);
              if (!exists && _sites.isNotEmpty) {
                _selectedSite = _sites.first.name;
              }
            } else if (_sites.isNotEmpty && _selectedSite == 'All Sites') {
              // keep All Sites
            }
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('[SiteManager] Firestore stream inactive: $err');
        },
      );
    } catch (e) {
      debugPrint('[SiteManager] Firestore stream not initialized (offline or test environment): $e');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
