import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// ViewModel für die User-Liste
///
/// KONZEPT: MVVM (Model-View-ViewModel)
/// - ViewModel = Brücke zwischen View und Model/Repository
/// - Enthält UI-Logik und Zustand
/// - Kommuniziert mit Repository für Daten
/// - Nutzt ChangeNotifier für State Management
/// - View reagiert auf Änderungen (notifyListeners)
///
/// KONZEPT: ChangeNotifier (Provider Pattern)
/// - Teil von Flutter's State Management
/// - notifyListeners() informiert alle Listener über Änderungen
/// - UI wird automatisch neu gebaut
///
/// VORTEILE:
/// - Trennung von UI und Business-Logik
/// - Testbar ohne UI
/// - Wiederverwendbar
enum ViewState { idle, loading, error, success }

class UserListViewModel extends ChangeNotifier {
  final UserRepository repository;

  // State
  List<User> _users = [];
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  /// Dependency Injection: Repository wird übergeben
  UserListViewModel({required this.repository});

  // Getters (öffentliche Read-Only Zugriffe)
  List<User> get users => _users;
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get hasData => _users.isNotEmpty;

  /// Lädt alle User
  Future<void> loadUsers() async {
    _setState(ViewState.loading);
    _errorMessage = null;

    try {
      _users = await repository.getUsers();
      _setState(ViewState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ViewState.error);
      _users = [];
    }
  }

  /// Aktualisiert die Liste (Pull-to-Refresh)
  Future<void> refreshUsers() async {
    // Cache leeren für frische Daten
    repository.clearCache();
    await loadUsers();
  }

  /// Sucht User nach Name (lokale Filterung)
  List<User> searchUsers(String query) {
    if (query.isEmpty) return _users;

    return _users.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Private Hilfsmethode zum State setzen
  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners(); // Wichtig! Informiert alle Listener
  }

  @override
  void dispose() {
    // Aufräumen wenn ViewModel nicht mehr benötigt wird
    super.dispose();
  }
}
