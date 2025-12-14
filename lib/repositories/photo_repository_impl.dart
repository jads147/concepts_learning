import '../models/photo.dart';
import '../services/api_service.dart';
import 'photo_repository.dart';

/// Konkrete Implementierung des PhotoRepository
///
/// LAZY DATA LOADING STRATEGIE:
/// - Lädt Photos in kleinen Portionen (Pages) statt alles auf einmal
/// - Cached geladene Photos im Speicher
/// - Trackt ob noch mehr Photos verfügbar sind
class PhotoRepositoryImpl implements PhotoRepository {
  final ApiService _apiService;

  // Cache für bereits geladene Photos
  // WICHTIG: Im Gegensatz zu UserRepository, wo wir ALLE User cachen,
  // bauen wir hier den Cache inkrementell auf!
  final List<Photo> _cachedPhotos = [];

  // JSONPlaceholder hat genau 5.000 Photos
  static const int _totalPhotosAvailable = 5000;

  PhotoRepositoryImpl(this._apiService);

  @override
  Future<List<Photo>> getPhotos({int page = 0, int pageSize = 20}) async {
    // Berechne Start-Index für diese Page
    final start = page * pageSize;

    // Wenn wir diese Page schon im Cache haben, gib sie zurück
    // (Optimierung: verhindert unnötige API-Calls)
    if (_cachedPhotos.length >= start + pageSize) {
      return _cachedPhotos.sublist(
        start,
        (start + pageSize).clamp(0, _cachedPhotos.length),
      );
    }

    // Wenn wir schon alle Photos haben, gib das Ende zurück
    if (_cachedPhotos.length >= _totalPhotosAvailable) {
      return [];
    }

    // LAZY DATA LOADING: Lade nur die nächste Page vom Server!
    // Statt fetchPhotos(start: 0, limit: 5000) machen wir
    // fetchPhotos(start: 20, limit: 20), dann (40, 20), usw.
    final newPhotos = await _apiService.fetchPhotos(
      start: _cachedPhotos.length,
      limit: pageSize,
    );

    // Füge neue Photos zum Cache hinzu
    _cachedPhotos.addAll(newPhotos);

    return newPhotos;
  }

  @override
  bool get hasMore {
    // Es gibt mehr Photos, wenn wir noch nicht alle 5.000 geladen haben
    return _cachedPhotos.length < _totalPhotosAvailable;
  }

  @override
  int get totalLoaded => _cachedPhotos.length;

  @override
  void clearCache() {
    _cachedPhotos.clear();
  }
}
