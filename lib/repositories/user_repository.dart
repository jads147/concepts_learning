import '../models/user.dart';
import '../services/api_service.dart';

/// Repository Pattern - Abstraktionsschicht zwischen Datenquellen und Business-Logik
///
/// KONZEPT: Repository Pattern
/// - Zentraler Zugriffspunkt für Daten
/// - Abstrahiert die Datenquelle (API, Datenbank, Cache, etc.)
/// - Kann mehrere Services kombinieren
/// - Ermöglicht einfaches Caching und Daten-Transformation
/// - Business-Logik für Datenzugriff
///
/// VORTEILE:
/// - Datenquelle kann gewechselt werden ohne ViewModel zu ändern
/// - Caching-Logik an einem Ort
/// - Testbar durch Mocking
abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUserById(int id);
  void clearCache();
}

/// Konkrete Implementierung mit Caching
class UserRepositoryImpl implements UserRepository {
  final ApiService apiService;

  // Einfacher In-Memory Cache
  List<User>? _cachedUsers;
  final Map<int, User> _cachedUserById = {};

  /// Dependency Injection: ApiService wird übergeben
  UserRepositoryImpl({required this.apiService});

  @override
  Future<List<User>> getUsers() async {
    // Cache-Strategie: Wenn Daten im Cache sind, diese zurückgeben
    if (_cachedUsers != null) {
      return _cachedUsers!;
    }

    // Ansonsten: Daten von API holen und cachen
    try {
      _cachedUsers = await apiService.fetchUsers();
      return _cachedUsers!;
    } catch (e) {
      // Bei Fehler: Cache löschen und Exception weiterwerfen
      _cachedUsers = null;
      rethrow;
    }
  }

  @override
  Future<User> getUserById(int id) async {
    // Zuerst im Cache nachsehen
    if (_cachedUserById.containsKey(id)) {
      return _cachedUserById[id]!;
    }

    // Alternativ: In der gecachten User-Liste suchen
    if (_cachedUsers != null) {
      try {
        final user = _cachedUsers!.firstWhere((u) => u.id == id);
        _cachedUserById[id] = user;
        return user;
      } catch (e) {
        // User nicht in Cache-Liste, weiter zur API
      }
    }

    // Von API holen und cachen
    try {
      final user = await apiService.fetchUserById(id);
      _cachedUserById[id] = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void clearCache() {
    _cachedUsers = null;
    _cachedUserById.clear();
  }
}
