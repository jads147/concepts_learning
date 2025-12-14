import '../models/photo.dart';

/// Repository Interface für Photo-Daten
///
/// KONZEPT: Repository Pattern
/// - Abstrahiert die Datenquelle (API, Datenbank, Cache)
/// - Business-Logik für Datenzugriff
/// - Kann mehrere Services kombinieren (z.B. API + lokaler Cache)
abstract class PhotoRepository {
  /// Lädt eine Seite von Photos
  ///
  /// [page] - Die Seitennummer (0-basiert)
  /// [pageSize] - Anzahl Photos pro Seite
  ///
  /// LAZY DATA LOADING:
  /// Diese Methode lädt NICHT alle 5.000 Photos auf einmal,
  /// sondern nur eine kleine Portion (z.B. 20 Stück).
  Future<List<Photo>> getPhotos({int page = 0, int pageSize = 20});

  /// Prüft ob es weitere Photos gibt
  bool get hasMore;

  /// Aktuelle Gesamtanzahl geladener Photos
  int get totalLoaded;

  /// Leert den Cache (z.B. für Pull-to-Refresh)
  void clearCache();
}
