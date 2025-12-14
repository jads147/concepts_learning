# Architektur-Dokumentation

## Übersicht der Schichten

```
┌─────────────────────────────────────────────────┐
│                    VIEW LAYER                    │
│  (user_list_screen.dart, user_detail_screen.dart)│
│                                                   │
│  - Stateless/Stateful Widgets                   │
│  - Consumer<ViewModel> für reactive UI          │
│  - context.read<T>() für Methoden               │
│  - KEINE Business-Logik                         │
└────────────────┬────────────────────────────────┘
                 │ notifyListeners() / context.read()
                 ▼
┌─────────────────────────────────────────────────┐
│                 VIEWMODEL LAYER                  │
│     (user_list_viewmodel.dart, ...)             │
│                                                   │
│  - extends ChangeNotifier                       │
│  - Verwaltet UI State (loading/error/success)   │
│  - Business-Logik für UI                        │
│  - Keine UI-Widgets                             │
└────────────────┬────────────────────────────────┘
                 │ Dependency Injection
                 ▼
┌─────────────────────────────────────────────────┐
│                REPOSITORY LAYER                  │
│          (user_repository.dart)                  │
│                                                   │
│  - Abstrahiert Datenquellen                     │
│  - Implementiert Caching                        │
│  - Kombiniert mehrere Services                  │
│  - Business-Logik für Daten                     │
└────────────────┬────────────────────────────────┘
                 │ Dependency Injection
                 ▼
┌─────────────────────────────────────────────────┐
│                 SERVICE LAYER                    │
│             (api_service.dart)                   │
│                                                   │
│  - HTTP-Kommunikation                           │
│  - Externe API-Calls                            │
│  - Error Handling                               │
│  - KEINE Business-Logik                         │
└────────────────┬────────────────────────────────┘
                 │ HTTP Client
                 ▼
┌─────────────────────────────────────────────────┐
│                  EXTERNAL API                    │
│       (jsonplaceholder.typicode.com)            │
└─────────────────────────────────────────────────┘
```

## Datenfluss

### Daten laden (API → UI)

```
1. View ruft ViewModel-Methode auf
   UserListScreen → viewModel.loadUsers()

2. ViewModel setzt State auf "loading"
   UserListViewModel._state = ViewState.loading
   notifyListeners() → UI zeigt Loading-Spinner

3. ViewModel ruft Repository auf
   repository.getUsers()

4. Repository prüft Cache
   if (_cachedUsers != null) return cache
   else: apiService.fetchUsers()

5. Service macht HTTP-Request
   http.Client.get('api/users')

6. Daten fließen zurück
   API → Service → Repository → ViewModel

7. ViewModel aktualisiert State
   _users = data
   _state = ViewState.success
   notifyListeners() → UI zeigt User-Liste
```

### Dependency Injection Flow

```
main.dart
    │
    ├─→ Provider<ApiService>
    │      └─→ ApiServiceImpl(client: http.Client())
    │
    ├─→ ProxyProvider<ApiService, UserRepository>
    │      └─→ UserRepositoryImpl(apiService: ↑)
    │
    └─→ ChangeNotifierProxyProvider<UserRepository, UserListViewModel>
           └─→ UserListViewModel(repository: ↑)
```

## Testing-Strategie

### Unit Tests (Isolierte Komponenten)

```
┌──────────────────────────────────────────┐
│  UserListViewModel Tests                 │
│  ├─ Mock: UserRepository                 │
│  ├─ Verify: State Transitions            │
│  └─ Assert: Business-Logik korrekt       │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  UserRepository Tests                    │
│  ├─ Mock: ApiService                     │
│  ├─ Verify: Caching funktioniert         │
│  └─ Assert: Daten korrekt                │
└──────────────────────────────────────────┘
```

### Widget Tests (UI-Komponenten)

```
┌──────────────────────────────────────────┐
│  UserListScreen Tests                    │
│  ├─ Mock: UserListViewModel              │
│  ├─ Verify: UI reagiert auf States       │
│  └─ Assert: Widgets korrekt angezeigt    │
└──────────────────────────────────────────┘
```

## SOLID Prinzipien im Projekt

### Single Responsibility Principle (SRP)
- **Model**: Nur Datenstruktur und Serialisierung
- **Service**: Nur HTTP-Kommunikation
- **Repository**: Nur Datenzugriff und Caching
- **ViewModel**: Nur UI-State und Business-Logik
- **View**: Nur UI-Darstellung

### Open/Closed Principle (OCP)
- Abstrakte Interfaces (`ApiService`, `UserRepository`)
- Erweiterbar durch neue Implementierungen
- Geschlossen für Modifikationen

### Liskov Substitution Principle (LSP)
- `ApiServiceImpl` kann `ApiService` ersetzen
- `UserRepositoryImpl` kann `UserRepository` ersetzen
- Tests verwenden Mocks statt echter Implementierungen

### Interface Segregation Principle (ISP)
- Kleine, fokussierte Interfaces
- `ApiService` hat nur notwendige Methoden
- Keine "fetten" Interfaces mit vielen Methoden

### Dependency Inversion Principle (DIP)
- High-level (ViewModel) hängt von Abstraktionen ab (Repository Interface)
- Low-level (Repository) implementiert Abstraktion
- Provider injiziert Dependencies von außen

## State Management mit Provider

### ChangeNotifier Pattern

```dart
class UserListViewModel extends ChangeNotifier {
  // Private State
  List<User> _users = [];
  ViewState _state = ViewState.idle;

  // Public Getters (Read-Only)
  List<User> get users => _users;
  ViewState get state => _state;

  // Methods ändern State und notifizieren
  Future<void> loadUsers() async {
    _state = ViewState.loading;
    notifyListeners(); // ← UI wird neu gebaut!

    _users = await repository.getUsers();
    _state = ViewState.success;
    notifyListeners(); // ← UI wird neu gebaut!
  }
}
```

### Consumer Pattern in UI

```dart
// Baut nur neu wenn notifyListeners() aufgerufen wird
Consumer<UserListViewModel>(
  builder: (context, viewModel, child) {
    // Zugriff auf viewModel.users, viewModel.state, etc.
    return ListView(...);
  },
)
```

## Caching-Strategie

### In-Memory Cache

```dart
class UserRepositoryImpl {
  List<User>? _cachedUsers;  // Null = kein Cache
  Map<int, User> _cachedUserById = {};

  Future<List<User>> getUsers() async {
    // Cache Hit
    if (_cachedUsers != null) {
      return _cachedUsers!;
    }

    // Cache Miss - von API laden
    _cachedUsers = await apiService.fetchUsers();
    return _cachedUsers!;
  }

  void clearCache() {
    _cachedUsers = null;
    _cachedUserById.clear();
  }
}
```

**Vorteile:**
- Schneller Zugriff auf bereits geladene Daten
- Reduziert API-Calls
- Einfach zu implementieren

**Nachteile:**
- Daten gehen bei App-Neustart verloren
- Keine Persistenz

**Erweiterungsmöglichkeiten:**
- SharedPreferences für einfache Persistenz
- SQLite für komplexe Daten
- Hive für schnelle NoSQL-Datenbank

## Error Handling

### Custom Exceptions

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);
}
```

### Error Flow

```
API Error
    ↓
Service wirft ApiException
    ↓
Repository fängt ab oder leitet weiter
    ↓
ViewModel fängt ab
    ↓
    _errorMessage = e.toString()
    _state = ViewState.error
    notifyListeners()
    ↓
View zeigt Error-UI
```

## Best Practices im Projekt

1. **Immutable Models**: `final` fields, `const` constructors
2. **Dependency Injection**: Keine `new` im Code, alles injected
3. **Interfaces**: Abstrakte Klassen für alle Services/Repositories
4. **Testing**: Jede Schicht einzeln testbar durch Mocking
5. **Separation of Concerns**: Jede Klasse hat eine klare Verantwortung
6. **State Management**: ChangeNotifier für reaktive UI
7. **Error Handling**: Try-catch mit spezifischen Exceptions
8. **Code Documentation**: Kommentare für Konzepte und Lernzwecke

## Erweiterungsmöglichkeiten

### 1. Lokale Persistenz
```dart
class UserRepositoryImpl {
  final ApiService apiService;
  final SharedPreferences prefs; // Neu!

  Future<List<User>> getUsers() async {
    // 1. Versuche aus lokalem Storage
    final cachedJson = prefs.getString('users');
    if (cachedJson != null) {
      return parseUsers(cachedJson);
    }

    // 2. Von API laden
    final users = await apiService.fetchUsers();

    // 3. Lokal speichern
    prefs.setString('users', jsonEncode(users));

    return users;
  }
}
```

### 2. Pagination
```dart
class UserListViewModel extends ChangeNotifier {
  int _page = 1;

  Future<void> loadMoreUsers() async {
    _page++;
    final newUsers = await repository.getUsers(page: _page);
    _users.addAll(newUsers);
    notifyListeners();
  }
}
```

### 3. Real-time Updates
```dart
class UserRepository {
  final ApiService apiService;
  final WebSocketService wsService; // Neu!

  Stream<List<User>> getUserStream() {
    return wsService.userUpdates;
  }
}
```
