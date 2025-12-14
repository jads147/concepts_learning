import '../models/user.dart';

/// Repository Pattern - Abstraktionsschicht zwischen Datenquellen und Business-Logik
///
/// KONZEPT: Repository Pattern
/// - Zentraler Zugriffspunkt für Daten
/// - Abstrahiert die Datenquelle (API, Datenbank, Cache, etc.)
/// - Kann mehrere Services kombinieren
/// - Ermöglicht einfaches Caching und Daten-Transformation
/// - Business-Logik für Datenzugriff
///
/// WARUM Repository UND ApiService?
/// - ApiService = Macht nur HTTP-Calls, gibt rohe Daten zurück
/// - Repository = Zusätzliche Logik (Caching, Daten kombinieren, etc.)
/// - Siehe user_repository_impl.dart für konkretes Beispiel mit Caching
///
/// VORTEILE:
/// - Datenquelle kann gewechselt werden ohne ViewModel zu ändern
/// - Caching-Logik an einem Ort (nicht in jedem ViewModel)
/// - Mehrere Datenquellen kombinierbar (API + lokale DB)
/// - Testbar durch Mocking
///
/// BEST PRACTICE: Interface und Implementation getrennt
/// - Dieses File = Nur das Interface (abstract class)
/// - user_repository_impl.dart = Die konkrete Implementierung
/// - Vorteile:
///   ✓ Klare Trennung von Vertrag und Implementierung
///   ✓ Mehrere Implementierungen möglich (API, Local DB, Mock)
///   ✓ Bessere Testbarkeit
///   ✓ Dependency Inversion Principle (SOLID)
abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUserById(int id);
  void clearCache();
}
