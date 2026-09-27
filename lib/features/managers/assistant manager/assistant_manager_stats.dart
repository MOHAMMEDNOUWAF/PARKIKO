import 'package:flutter/foundation.dart';

/// Singleton that holds live operational counts from the Assistant Manager screen.
/// Both the AssistantManagerScreen (writer) and LiveOperationsScreen (reader) use this.
class AssistantManagerStats extends ChangeNotifier {
  AssistantManagerStats._();
  static final instance = AssistantManagerStats._();

  int _parked = 0;
  int _retrieved = 0;
  int _completed = 0;

  int get parked => _parked;
  int get retrieved => _retrieved;
  int get completed => _completed;

  /// Called by AssistantManagerScreen whenever its lists change.
  void update({required int parked, required int retrieved, required int completed}) {
    if (_parked == parked && _retrieved == retrieved && _completed == completed) return;
    _parked = parked;
    _retrieved = retrieved;
    _completed = completed;
    notifyListeners();
  }
}
