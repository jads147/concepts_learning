import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// ViewModel für User-Details
///
/// Zeigt Details eines einzelnen Users
/// Demonstriert das gleiche Pattern wie UserListViewModel
class UserDetailViewModel extends ChangeNotifier {
  final UserRepository repository;

  User? _user;
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  UserDetailViewModel({required this.repository});

  // Getters
  User? get user => _user;
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  /// Lädt einen User nach ID
  Future<void> loadUser(int userId) async {
    _setState(ViewState.loading);
    _errorMessage = null;

    try {
      _user = await repository.getUserById(userId);
      _setState(ViewState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ViewState.error);
      _user = null;
    }
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
}

enum ViewState { idle, loading, error, success }
