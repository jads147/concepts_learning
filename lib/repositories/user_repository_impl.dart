import '../models/user.dart';
import '../services/api_service.dart';
import 'user_repository.dart';

/// Konkrete Implementierung des UserRepository mit Caching
///
/// BEST PRACTICE: Implementierung getrennt vom Interface
/// - Implementiert das UserRepository Interface
/// - Enthält die konkrete Caching-Logik
/// - Kann leicht durch andere Implementierungen ersetzt werden
///   (z.B. UserRepositoryLocal für lokale Datenbank)
///
/// BEISPIEL: Unterschied zwischen ApiService und Repository
///
/// ApiService (einfach - nur HTTP-Call):
/// ```dart
/// Future<List<User>> fetchUsers() async {
///   final response = await client.get(Uri.parse('$baseUrl/users'));
///   return jsonList.map((json) => User.fromJson(json)).toList();
/// }
/// ```
///
/// Repository (mit Caching-Logik):
/// ```dart
/// Future<List<User>> getUsers() async {
///   if (_cachedUsers != null) return _cachedUsers!; // ← Caching!
///   _cachedUsers = await apiService.fetchUsers();
///   return _cachedUsers!;
/// }
/// ```
///
/// Der ApiService kennt nur HTTP, das Repository fügt Business-Logik hinzu.
class UserRepositoryImpl implements UserRepository {
  final ApiService apiService;

  // Einfacher In-Memory Cache
  List<User>? _cachedUsers;
  final Map<int, User> _cachedUserById = {};

  /// Dependency Injection: ApiService wird übergeben
  ///
  /// WARUM Dependency Injection für Tests?
  ///
  /// MIT Dependency Injection (gut für Tests):
  /// ```dart
  /// class UserRepository {
  ///   final ApiService apiService;
  ///   UserRepository({required this.apiService}); // Von außen übergeben
  /// }
  /// // Im Test können wir jetzt ein Mock übergeben:
  /// final mockApi = MockApiService();
  /// final repo = UserRepository(apiService: mockApi); // ✓ Einfach zu mocken!
  /// ```
  ///
  /// OHNE Dependency Injection (schlecht für Tests):
  /// ```dart
  /// class UserRepository {
  ///   final ApiService apiService = ApiService(); // Direkt erstellt
  /// }
  /// // Im Test nutzt es IMMER den echten ApiService → schwer zu testen! ✗
  /// ```
  UserRepositoryImpl({required this.apiService});

  @override
  Future<List<User>> getUsers() async {
    // Cache-Strategie: Wenn Daten im Cache sind, diese zurückgeben
    if (_cachedUsers != null) {
      // ═══════════════════════════════════════════════════════════════════════
      // Null-Assertion Operator (!)
      // ═══════════════════════════════════════════════════════════════════════
      //
      // Was macht das ! ?
      // • _cachedUsers ist vom Typ `List<User>?` (kann null sein - siehe Zeile 47)
      // • In Zeile 54 prüfen wir: if (_cachedUsers != null)
      // • Wir wissen: Hier ist _cachedUsers garantiert NICHT null
      // • Dart weiß es nicht automatisch → ohne ! gibt es einen Fehler
      // • Das ! sagt: "Vertrau mir, ich weiß das ist nicht null!"
      //
      // Beispiel:
      // `List<User>?` _cachedUsers;  // Kann null sein
      //
      // // OHNE !
      // return _cachedUsers;  // ✗ Fehler: Kann null sein, erwartet aber `List<User>`
      //
      // // MIT !
      // return _cachedUsers!; // ✓ OK: Ich garantiere, es ist nicht null
      //
      // ⚠️ VORSICHT: Wenn du ! benutzt und es IST doch null → App crasht!
      // `List<User>?` users = null;
      // print(users!.length); // ☠️ CRASH! "Null check operator used on null"
      //
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
