import 'package:flutter/foundation.dart';
import '../models/photo.dart';
import '../repositories/photo_repository.dart';

/// Mögliche Zustände für Photo-Liste
enum PhotoViewState { idle, loading, loadingMore, success, error }

/// ViewModel für Photo-Liste mit LAZY DATA LOADING
///
/// UNTERSCHIED ZU UserListViewModel:
/// UserListViewModel lädt ALLE 10 User auf einmal (loadUsers()).
/// PhotoListViewModel lädt Photos SCHRITTWEISE:
/// - Initial: 20 Photos
/// - Beim Scrollen: Jeweils 20 weitere Photos nachladen
///
/// Dies ist echtes LAZY DATA LOADING! Die Daten werden nur geladen,
/// wenn sie benötigt werden (user scrollt runter).
class PhotoListViewModel extends ChangeNotifier {
  final PhotoRepository _photoRepository;

  // Liste der aktuell geladenen Photos
  // WICHTIG: Diese Liste wächst mit der Zeit!
  // Start: 20 Photos → nach Scroll: 40 → nach Scroll: 60 → usw.
  List<Photo> _photos = [];
  PhotoViewState _state = PhotoViewState.idle;
  String? _errorMessage;
  int _currentPage = 0;
  static const int _pageSize = 20;

  PhotoListViewModel(this._photoRepository);

  // Getters
  List<Photo> get photos => _photos;
  PhotoViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _photoRepository.hasMore;
  int get totalLoaded => _photoRepository.totalLoaded;

  /// Lädt die erste Seite von Photos (Initial Load)
  Future<void> loadInitialPhotos() async {
    _state = PhotoViewState.loading;
    _currentPage = 0;
    _photos.clear();
    notifyListeners();

    try {
      // Lade nur die ersten 20 Photos!
      // NICHT alle 5.000 auf einmal wie bei Users.
      _photos = await _photoRepository.getPhotos(
        page: _currentPage,
        pageSize: _pageSize,
      );
      _state = PhotoViewState.success;
      _currentPage++;
    } catch (e) {
      _state = PhotoViewState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Lädt die nächste Seite von Photos (Infinite Scroll)
  ///
  /// Diese Methode wird aufgerufen, wenn der User fast am Ende
  /// der Liste angekommen ist.
  ///
  /// LAZY DATA LOADING IN AKTION:
  /// Jeder Aufruf lädt nur 20 weitere Photos vom Server,
  /// nicht alle verbleibenden!
  Future<void> loadMorePhotos() async {
    // Verhindere mehrfaches gleichzeitiges Laden
    if (_state == PhotoViewState.loadingMore || !hasMore) {
      return;
    }

    _state = PhotoViewState.loadingMore;
    notifyListeners();

    try {
      // Lade die nächste Page (z.B. Photos 20-39, dann 40-59, usw.)
      final newPhotos = await _photoRepository.getPhotos(
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Füge neue Photos zur existierenden Liste hinzu
      _photos.addAll(newPhotos);
      _currentPage++;
      _state = PhotoViewState.success;
    } catch (e) {
      _state = PhotoViewState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Refresh-Funktion (Pull-to-Refresh)
  Future<void> refresh() async {
    _photoRepository.clearCache();
    await loadInitialPhotos();
  }
}
