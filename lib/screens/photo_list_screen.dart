import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/photo_list_viewmodel.dart';

/// Photo-Liste mit Infinite Scroll (Lazy Data Loading)
///
/// ZWEI ARTEN VON "LAZY":
///
/// 1. LAZY RENDERING (ListView.builder):
///    - Flutter baut nur die sichtbaren Widgets
///    - Beim Scrollen werden Widgets dynamisch erstellt/zerstört
///    - Funktioniert automatisch mit ListView.builder
///    - Spart MEMORY & RENDERING-PERFORMANCE
///
/// 2. LAZY DATA LOADING (Dieser Screen):
///    - Daten werden nur bei Bedarf vom Server geladen
///    - Initial: 20 Photos laden
///    - Beim Scrollen nahe dem Ende: nächste 20 Photos laden
///    - Implementiert durch ScrollController + loadMorePhotos()
///    - Spart NETWORK-TRAFFIC & INITIAL-LOADING-TIME
///
/// Beide zusammen = optimale Performance für große Listen!
class PhotoListScreen extends StatefulWidget {
  const PhotoListScreen({super.key});

  @override
  State<PhotoListScreen> createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  // ScrollController um Scroll-Position zu tracken
  // Wird benötigt für LAZY DATA LOADING (nicht für LAZY RENDERING!)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Lade initial die ersten Photos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoListViewModel>().loadInitialPhotos();
    });

    // Listener für Infinite Scroll
    // LAZY DATA LOADING: Wenn User fast am Ende ist, lade mehr!
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Prüft ob User am Ende der Liste ist und lädt ggf. mehr Photos
  ///
  /// LAZY DATA LOADING TRIGGER:
  /// Wenn 80% der Liste durchgescrollt wurden, lade die nächste Page.
  void _onScroll() {
    // Berechne wie weit der User gescrollt hat
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // 80% der Liste

    // Wenn User bei 80% angekommen ist, lade mehr
    if (currentScroll >= threshold) {
      context.read<PhotoListViewModel>().loadMorePhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PhotoListViewModel>(
        builder: (context, viewModel, child) {
          // Loading State (Initial)
          if (viewModel.state == PhotoViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error State
          if (viewModel.state == PhotoViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage ?? 'Unbekannter Fehler',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.loadInitialPhotos,
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }

          // Success State mit Daten
          if (viewModel.photos.isEmpty) {
            return const Center(child: Text('Keine Photos gefunden'));
          }

          // LAZY RENDERING: ListView.builder baut nur sichtbare Items!
          // Auch wenn wir später 1000 Photos geladen haben, werden nur
          // ~10 Widget-Instanzen gleichzeitig im Speicher gehalten.
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView.builder(
              controller: _scrollController, // Für LAZY DATA LOADING
              itemCount: viewModel.photos.length +
                  (viewModel.hasMore ? 1 : 0), // +1 für Loading-Indicator
              itemBuilder: (context, index) {
                // Loading-Indicator am Ende der Liste
                // Wird angezeigt während LAZY DATA LOADING aktiv ist
                if (index >= viewModel.photos.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final photo = viewModel.photos[index];

                // LAZY RENDERING: Dieser ListTile wird nur gebaut,
                // wenn er auf dem Bildschirm sichtbar ist!
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: Image.network(
                      photo.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      // Lazy Image Loading: Bilder werden erst geladen,
                      // wenn sie sichtbar werden
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 50);
                      },
                    ),
                    title: Text(
                      photo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('ID: ${photo.id} • Album: ${photo.albumId}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Hier könnte ein Detail-Screen geöffnet werden
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Photo ${photo.id} angeklickt'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
