import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_list_viewmodel.dart';
import '../models/user.dart';
import 'user_detail_screen.dart';

/// User List Screen - Die View-Schicht
///
/// KONZEPT: View in MVVM
/// - Zeigt UI basierend auf ViewModel-State
/// - Reagiert auf State-Änderungen
/// - Delegiert Aktionen an ViewModel
/// - Keine Business-Logik
///
/// KONZEPT: Provider/Consumer
/// - Consumer reagiert auf notifyListeners() vom ViewModel
/// - Baut nur den Widget-Teil neu, der sich ändert
/// - context.read() für einmalige Zugriffe (z.B. Methoden aufrufen)
class UserListScreen extends StatefulWidget {
  // ═══════════════════════════════════════════════════════════════════════
  // Was macht 'const'?
  // ═══════════════════════════════════════════════════════════════════════
  //
  // const = Compile-Zeit-Konstante (wird beim Kompilieren erstellt)
  //
  // Vorteile:
  // ✓ Performance: Widget wird nur EINMAL im Speicher erstellt
  // ✓ Wiederverwendung: Flutter nutzt dieselbe Instanz mehrfach
  // ✓ Effizientes Rebuilding: const Widgets werden NICHT neu gebaut
  //
  // Beispiel:
  // const Text('Hello')  → wird einmal erstellt, immer wiederverwendet
  // Text('Hello')        → wird bei jedem Build neu erstellt
  //
  // const vs final:
  // • const: Wert muss zur KOMPILIERZEIT bekannt sein
  //   const x = 42;                    ✓ OK
  //   const y = DateTime.now();        x Fehler (erst zur Laufzeit bekannt)
  //
  // • final: Wert kann zur LAUFZEIT berechnet werden
  //   final z = DateTime.now();        ✓ OK
  //   z = DateTime.now();              x Fehler (kann nicht neu zugewiesen werden)
  //
  // Faustregel:
  // • Nutze const wo immer möglich (bessere Performance)
  // • Nutze final wenn der Wert erst zur Laufzeit bekannt ist
  //
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // ═══════════════════════════════════════════════════════════════════════
    // Warum addPostFrameCallback statt direktem context.read()?
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Problem: In initState() ist der BuildContext noch nicht vollständig
    // initialisiert. Der Widget-Baum wird erst gebaut, NACHDEM initState()
    // durchgelaufen ist.
    //
    // Lösung: addPostFrameCallback wartet, bis der erste Frame komplett
    // gerendert wurde. Dann ist garantiert:
    // ✓ Der Widget-Baum ist aufgebaut
    // ✓ Der BuildContext ist vollständig initialisiert
    // ✓ Provider sind verfügbar

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserListViewModel>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Suchfeld
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════════
          // Consumer vs context.read vs context.watch
          // ═══════════════════════════════════════════════════════════════════
          //
          //    Consumer<T>:
          //    - Baut sich NEU, wenn notifyListeners() aufgerufen wird
          //    - Nutze für UI-Teile, die auf State-Änderungen reagieren
          //    - Hier: User-Liste muss sich neu bauen bei jedem Load/Error
          //
          //    context.read<T>():
          //    - Einmaliger Zugriff OHNE automatischen Rebuild
          //    - Nutze für Event-Handler (Buttons, onTap, etc.)
          //    - Beispiel Zeile 35: loadUsers() beim Start
          //    - Beispiel Zeile 102: Retry-Button → nur Methode aufrufen
          //
          //    context.watch<T>():
          //    - Wie Consumer, aber inline (keine builder-Funktion)
          //    - Baut Widget NEU bei jeder Änderung
          //    - Beispiel: final users = context.watch<UserListViewModel>().users;
          //    - Vorsicht: Baut das GANZE Widget neu (nicht nur Teile)
          //
          // Faustregel:
          // • Consumer → Wenn nur TEIL des Widgets neu gebaut werden soll
          // • context.watch → Wenn das GANZE Widget neu gebaut werden soll
          // • context.read → Wenn du nur eine METHODE aufrufen willst
          //
          // User-Liste
          Expanded(
            child: Consumer<UserListViewModel>(
              builder: (context, viewModel, child) {
                // Loading State
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error State
                if (viewModel.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${viewModel.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => viewModel.loadUsers(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Success State - aber keine Daten
                if (!viewModel.hasData) {
                  return const Center(child: Text('No users found'));
                }

                // Success State mit Daten
                // Ternärer Operator: bedingung ? wert_wenn_true : wert_wenn_false
                // Wenn Suchfeld leer: alle User, sonst: gefilterte User
                final users = _searchQuery.isEmpty
                    ? viewModel.users
                    : viewModel.searchUsers(_searchQuery);

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users match your search'),
                  );
                }

                // ═══════════════════════════════════════════════════════════════════════
                // RefreshIndicator - Pull-to-Refresh
                // ═══════════════════════════════════════════════════════════════════════
                //
                // Was ist das?
                // • Ein Widget, das "Pull-to-Refresh" ermöglicht
                // • Benutzer zieht die Liste nach unten → onRefresh wird aufgerufen
                //
                // Wie funktioniert es?
                // 1. Benutzer wischt von oben nach unten
                // 2. RefreshIndicator zeigt einen Lade-Kreis
                // 3. onRefresh wird aufgerufen (muss ein Future zurückgeben!)
                // 4. Wartet bis Future fertig ist
                // 5. Versteckt den Lade-Kreis
                //
                // onRefresh erwartet ein Future:
                // ✓ onRefresh: () => viewModel.refreshUsers()  (gibt Future zurück)
                // ✗ onRefresh: () { viewModel.refreshUsers(); } (gibt void zurück)
                //
                return RefreshIndicator(
                  onRefresh: () => viewModel.refreshUsers(),
                  // ═══════════════════════════════════════════════════════════════════════
                  // ListView.builder - LAZY RENDERING (nicht Lazy Data Loading!)
                  // ═══════════════════════════════════════════════════════════════════════
                  //
                  // WICHTIG: Unterscheide zwischen zwei Arten von "Lazy":
                  //
                  // 1. LAZY RENDERING (ListView.builder):
                  //    - Widgets werden nur gebaut, wenn sie SICHTBAR sind
                  //    - VORAUSSETZUNG: Daten sind BEREITS im Speicher (viewModel.users)
                  //    - Spart: MEMORY (Widget-Instanzen) & RENDERING-PERFORMANCE
                  //    - Bei 10 User: Alle Daten da, aber nur ~5 Widgets gleichzeitig
                  //
                  // 2. LAZY DATA LOADING (siehe PhotoListScreen):
                  //    - DATEN werden nur bei Bedarf vom Server geladen
                  //    - Initial: Nur erste 20 Items laden
                  //    - Beim Scrollen: Nächste 20 Items nachladen (Infinite Scroll)
                  //    - Spart: NETWORK-TRAFFIC & INITIAL-LOADING-TIME
                  //    - Bei 5000 Photos: Nicht alle laden, sondern schrittweise!
                  //
                  // DIESE LISTE (Users):
                  // ✓ Nutzt LAZY RENDERING (ListView.builder)
                  // ✗ Nutzt KEIN Lazy Data Loading (lädt alle 10 User sofort)
                  //
                  // Warum kein Lazy Data Loading?
                  // → Nur 10 User! So wenig Daten brauchen kein Pagination
                  //
                  // Zum Vergleich siehe: PhotoListScreen (5000 Photos mit beiden!)
                  //
                  // ListView.builder Details:
                  // • itemCount: Anzahl Items in den BEREITS GELADENEN Daten
                  // • itemBuilder: Wird NUR für sichtbare Items aufgerufen
                  // • Scrollt User weg → Widget wird aus Speicher entfernt
                  // • Scrollt User zurück → itemBuilder wird erneut aufgerufen
                  //
                  // Performance (nur Lazy Rendering):
                  // • 10 Items:    ListView ≈ ListView.builder
                  // • 100 Items:   ListView.builder ist besser
                  // • 1000+ Items: ListView.builder ist essentiell
                  //
                  // Performance (mit Lazy Data Loading):
                  // • Siehe PhotoListScreen für echte Optimierung großer Datensätze!
                  //
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserListItem(user: user);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Was bedeutet der Unterstrich '_' vor dem Klassennamen?
// ═══════════════════════════════════════════════════════════════════════
//
// Der Unterstrich macht die Klasse LIBRARY-PRIVATE (file-private)
//
// Sichtbarkeit:
// • _UserListItem → Nur in DIESER Datei (user_list_screen.dart) sichtbar
// • UserListItem  → In ALLEN Dateien sichtbar (public)
//
// Gleiches Prinzip gilt für:
// • _Variable     → private Variable
// • _methode()    → private Methode
// • _ClassName    → private Klasse
//
// Warum hier private?
// ✓ _UserListItem ist nur ein internes Detail von UserListScreen
// ✓ Andere Dateien brauchen es nicht
// ✓ Kapselung: Implementierungsdetails verstecken
//
// Beispiel:
// // In user_detail_screen.dart:
// _UserListItem(user: user);  Fehler! Nicht sichtbar
//
// Faustregel:
// • Wenn Klasse/Variable nur in DIESER Datei gebraucht wird → private (_)
// • Wenn andere Dateien darauf zugreifen sollen → public (kein _)
//
/// Separates Widget für User-ListItem
/// Demonstriert Widget-Komposition
class _UserListItem extends StatelessWidget {
  final User user;

  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // ═══════════════════════════════════════════════════════════════════════
          // Navigation in Flutter - Navigator.push()
          // ═══════════════════════════════════════════════════════════════════════
          //
          // Was macht Navigator.push()?
          // • Legt eine neue Seite auf den "Navigation Stack"
          // • Wie ein Stapel Karten: neue Seite kommt oben drauf
          // • Zurück-Button entfernt oberste Seite vom Stapel
          //
          // Navigation Stack Beispiel:
          // Start:          [HomeScreen]
          // push(ListScreen): [HomeScreen, ListScreen]
          // push(DetailScreen): [HomeScreen, ListScreen, DetailScreen]
          // pop():          [HomeScreen, ListScreen]
          // pop():          [HomeScreen]
          //
          // Was ist MaterialPageRoute?
          // • Definiert WIE die neue Seite angezeigt wird
          // • "Material" = Material Design Animationen
          // • builder: Funktion die das neue Widget erstellt
          // • Alternative: CupertinoPageRoute (iOS-Style)
          //
          // Der builder Parameter:
          // • Wird aufgerufen wenn die Route gebaut werden muss
          // • Bekommt neuen BuildContext für die neue Seite
          // • Gibt das Widget der neuen Seite zurück
          //
          // Warum nicht einfach direkt UserDetailScreen()?
          // • Route verwaltet Animationen (Slide-in/out)
          // • Route verwaltet Lifecycle (wann bauen, wann entfernen)
          // • Route verwaltet Zurück-Navigation
          //
          // Andere Navigator-Methoden:
          // • Navigator.pop(context)         → Seite schließen
          // • Navigator.pushReplacement()    → Seite ersetzen (ohne Zurück)
          // • Navigator.pushNamed('/detail') → Mit benannten Routes
          //
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(userId: user.id),
            ),
          );
        },
      ),
    );
  }
}
