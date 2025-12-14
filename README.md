# Flutter Concepts Learning - MVVM Template

Ein umfassendes Flutter-Lernprojekt, das wichtige Software-Engineering-Konzepte demonstriert.

## 🎯 Lernziele

Dieses Projekt zeigt Best Practices für:
- **MVVM (Model-View-ViewModel)** Architektur
- **Repository Pattern** für Datenabstraktion
- **Dependency Injection** mit Provider
- **State Management** mit ChangeNotifier
- **Testing** (Unit Tests & Widget Tests)
- **Clean Architecture** Prinzipien

## 📁 Projektstruktur

```
lib/
├── models/           # Datenmodelle (User)
├── services/         # API-Services (HTTP-Kommunikation)
├── repositories/     # Repository Pattern (Datenabstraktion + Caching)
├── viewmodels/       # ViewModels (Business-Logik + State)
└── views/            # UI-Komponenten (Screens & Widgets)

test/
├── models/           # Model Tests
├── repositories/     # Repository Tests (mit Mocks)
├── viewmodels/       # ViewModel Tests (mit Mocks)
└── views/            # Widget Tests
```

## 🏗️ Architektur-Übersicht

### 1. **Model Layer** ([models/user.dart](lib/models/user.dart))
- Datenstrukturen mit `fromJson` / `toJson`
- Immutable mit `final` fields
- `copyWith` für Updates
- Equality & HashCode

```dart
class User {
  final int id;
  final String name;
  final String email;

  factory User.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
  User copyWith({...}) { ... }
}
```

### 2. **Service Layer** ([services/api_service.dart](lib/services/api_service.dart))
- Abstrakte Interfaces für Testbarkeit
- HTTP-Kommunikation isoliert
- Error Handling mit Custom Exceptions
- Dependency Injection Ready

```dart
abstract class ApiService {
  Future<List<User>> fetchUsers();
}

class ApiServiceImpl implements ApiService {
  final http.Client client; // Injected!
  // ...
}
```

### 3. **Repository Layer** ([repositories/user_repository.dart](lib/repositories/user_repository.dart))
- Abstrahiert Datenquellen (API, Cache, DB)
- Implementiert Caching-Strategien
- Business-Logik für Datenzugriff
- Kombiniert mehrere Services

```dart
abstract class UserRepository {
  Future<List<User>> getUsers();
  void clearCache();
}

class UserRepositoryImpl implements UserRepository {
  final ApiService apiService; // Injected!
  List<User>? _cachedUsers; // Caching
  // ...
}
```

### 4. **ViewModel Layer** ([viewmodels/user_list_viewmodel.dart](lib/viewmodels/user_list_viewmodel.dart))
- Erweitert `ChangeNotifier` für State Management
- Kommuniziert mit Repositories
- UI-unabhängige Business-Logik
- Verwaltung von Loading/Error/Success States

```dart
class UserListViewModel extends ChangeNotifier {
  final UserRepository repository; // Injected!

  ViewState _state = ViewState.idle;
  List<User> _users = [];

  Future<void> loadUsers() async {
    _state = ViewState.loading;
    notifyListeners(); // UI wird aktualisiert!

    _users = await repository.getUsers();
    _state = ViewState.success;
    notifyListeners();
  }
}
```

### 5. **View Layer** ([views/user_list_screen.dart](lib/views/user_list_screen.dart))
- Stateless/Stateful Widgets
- `Consumer<T>` für reactive Updates
- `context.read<T>()` für Methoden-Aufrufe
- Keine Business-Logik

```dart
Consumer<UserListViewModel>(
  builder: (context, viewModel, child) {
    if (viewModel.isLoading) return CircularProgressIndicator();
    if (viewModel.hasError) return ErrorWidget();
    return ListView(children: ...);
  },
)
```

## 🔧 Dependency Injection Setup ([main.dart](lib/main.dart))

MultiProvider erstellt eine Dependency-Hierarchie:

```dart
MultiProvider(
  providers: [
    // 1. Service Layer
    Provider<ApiService>(
      create: (_) => ApiServiceImpl(client: http.Client()),
    ),

    // 2. Repository Layer (nutzt ApiService)
    ProxyProvider<ApiService, UserRepository>(
      update: (_, apiService, _) => UserRepositoryImpl(apiService: apiService),
    ),

    // 3. ViewModel Layer (nutzt Repository)
    ChangeNotifierProxyProvider<UserRepository, UserListViewModel>(
      create: (ctx) => UserListViewModel(repository: ctx.read<UserRepository>()),
      update: (_, repo, vm) => vm ?? UserListViewModel(repository: repo),
    ),
  ],
  child: MaterialApp(...),
)
```

## 🧪 Testing

### Unit Tests

**Model Tests** ([test/models/user_test.dart](test/models/user_test.dart)):
- JSON Serialisierung/Deserialisierung
- copyWith Funktionalität
- Equality & HashCode

**Repository Tests** ([test/repositories/user_repository_test.dart](test/repositories/user_repository_test.dart)):
```dart
@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late UserRepositoryImpl repository;

  setUp(() {
    mockApiService = MockApiService();
    repository = UserRepositoryImpl(apiService: mockApiService);
  });

  test('should cache users', () async {
    when(mockApiService.fetchUsers()).thenAnswer((_) async => testUsers);

    await repository.getUsers(); // 1. API Call
    await repository.getUsers(); // Von Cache

    verify(mockApiService.fetchUsers()).called(1); // Nur 1x!
  });
}
```

**ViewModel Tests** ([test/viewmodels/user_list_viewmodel_test.dart](test/viewmodels/user_list_viewmodel_test.dart)):
- State Transitions (idle → loading → success)
- Error Handling
- Repository Interaktionen

### Widget Tests

**Screen Tests** ([test/views/user_list_screen_test.dart](test/views/user_list_screen_test.dart)):
```dart
testWidgets('shows loading indicator when loading', (tester) async {
  when(mockViewModel.isLoading).thenReturn(true);

  await tester.pumpWidget(
    ChangeNotifierProvider<UserListViewModel>.value(
      value: mockViewModel,
      child: UserListScreen(),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Tests ausführen

```bash
# Mocks generieren
flutter pub run build_runner build --delete-conflicting-outputs

# Alle Tests ausführen
flutter test

# Mit Coverage
flutter test --coverage
```

## 🚀 App starten

```bash
# Dependencies installieren
flutter pub get

# App starten
flutter run

# Tests ausführen
flutter test
```

## 📚 Konzepte im Detail

### MVVM (Model-View-ViewModel)

**Vorteile:**
- ✅ Klare Trennung von UI und Logik
- ✅ Testbar ohne UI
- ✅ Wiederverwendbare ViewModels
- ✅ Reaktive UI-Updates

**Datenfluss:**
```
View ← notifyListeners() ← ViewModel ← Repository ← Service ← API
View → Aktion → ViewModel → Repository → Service → API
```

### Repository Pattern

**Vorteile:**
- ✅ Abstrahiert Datenquellen
- ✅ Ermöglicht Caching
- ✅ Austauschbare Implementierungen
- ✅ Zentrale Datenzugriff-Logik

### Dependency Injection

**Vorteile:**
- ✅ Loose Coupling
- ✅ Testbarkeit (Mocking)
- ✅ Flexibilität
- ✅ Single Responsibility

### Provider Pattern

**Vorteile:**
- ✅ Built-in in Flutter
- ✅ Reactive State Management
- ✅ Scoped Dependencies
- ✅ Efficient Rebuilds

## 🎓 Was du hier lernst

1. **Clean Architecture**: Schichten-Trennung für wartbaren Code
2. **SOLID Prinzipien**: Besonders Dependency Inversion
3. **Testing**: Unit Tests mit Mocks, Widget Tests
4. **State Management**: ChangeNotifier & Provider
5. **Async Programming**: Futures, async/await
6. **Error Handling**: Try-catch, Custom Exceptions
7. **Caching**: In-Memory Caching Strategien

## 🔍 Nächste Schritte zum Lernen

1. **Erweitere das User-Model**: Füge Address, Company hinzu
2. **Implementiere CRUD**: Create, Update, Delete User
3. **Persistenz**: Speichere Daten lokal (SharedPreferences, SQLite)
4. **Navigation**: Implementiere komplexere Navigation
5. **Themes**: Dark Mode mit Provider
6. **Error States**: Besseres Error Handling
7. **Integration Tests**: End-to-End Tests

## 📖 Weitere Ressourcen

- [Provider Documentation](https://pub.dev/packages/provider)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)
- [Mockito Documentation](https://pub.dev/packages/mockito)
