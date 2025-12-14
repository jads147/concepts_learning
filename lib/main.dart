import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/user_repository_impl.dart';
import 'repositories/photo_repository.dart';
import 'repositories/photo_repository_impl.dart';
import 'viewmodels/user_list_viewmodel.dart';
import 'viewmodels/user_detail_viewmodel.dart';
import 'viewmodels/photo_list_viewmodel.dart';
import 'views/user_list_screen.dart';
import 'screens/photo_list_screen.dart';

/// Main Entry Point
///
/// KONZEPT: Dependency Injection mit Provider
/// - MultiProvider erstellt alle benötigten Dependencies
/// - Provider stellt Instanzen im gesamten Widget-Tree zur Verfügung
/// - Hierarchie: Services -> Repositories -> ViewModels -> Views
///
/// VORTEILE:
/// - Zentrale Konfiguration aller Dependencies
/// - Testbar: Dependencies können ausgetauscht werden (siehe user_repository.dart)
/// - Loose Coupling: Komponenten kennen nur ihre direkten Dependencies
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// 1. Service Layer (unterste Ebene)
        /// Provider erstellt eine einzelne Instanz für die gesamte App
        Provider<ApiService>(
          create: (_) => ApiServiceImpl(
            client: http.Client(),
          ),
        ),

        /// 2. Repository Layer
        /// ProxyProvider nutzt ApiService um Repository zu erstellen
        ProxyProvider<ApiService, UserRepository>(
          update: (_, apiService, _) => UserRepositoryImpl(
            apiService: apiService,
          ),
        ),

        /// 2b. Repository Layer - Photos
        /// Separates Repository für Photo-Daten mit Pagination-Support
        ProxyProvider<ApiService, PhotoRepository>(
          update: (_, apiService, _) => PhotoRepositoryImpl(apiService),
        ),

        /// 3. ViewModel Layer - User List
        /// ChangeNotifierProxyProvider für reaktive ViewModels
        /// Erstellt UserListViewModel mit UserRepository
        ChangeNotifierProxyProvider<UserRepository, UserListViewModel>(
          create: (context) => UserListViewModel(
            repository: context.read<UserRepository>(),
          ),
          update: (_, repository, viewModel) =>
              viewModel ?? UserListViewModel(repository: repository),
        ),

        /// 4. ViewModel Layer - User Detail
        /// ChangeNotifierProxyProvider da UserDetailViewModel ChangeNotifier erweitert
        ChangeNotifierProxyProvider<UserRepository, UserDetailViewModel>(
          create: (context) => UserDetailViewModel(
            repository: context.read<UserRepository>(),
          ),
          update: (_, repository, viewModel) =>
              viewModel ?? UserDetailViewModel(repository: repository),
        ),

        /// 5. ViewModel Layer - Photo List
        /// ViewModel für große Listen mit LAZY DATA LOADING
        ChangeNotifierProxyProvider<PhotoRepository, PhotoListViewModel>(
          create: (context) => PhotoListViewModel(
            context.read<PhotoRepository>(),
          ),
          update: (_, repository, viewModel) =>
              viewModel ?? PhotoListViewModel(repository),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Concepts Learning',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ),
          useMaterial3: true,
        ),
        home: const MainTabScreen(),
      ),
    );
  }
}

/// Main Screen mit Tab-Navigation
///
/// VERGLEICH DER BEIDEN TABS:
///
/// 1. USERS TAB (10 Items):
///    - Lädt ALLE User auf einmal
///    - Nutzt nur LAZY RENDERING (ListView.builder)
///    - Perfekt für kleine Datensätze
///
/// 2. PHOTOS TAB (5.000 Items):
///    - Lädt Photos SCHRITTWEISE (20 pro Scroll)
///    - Nutzt LAZY RENDERING + LAZY DATA LOADING
///    - Optimal für große Datensätze
class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.primary,
              child: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.people), text: 'Users'),
                  Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  UserListScreen(),
                  PhotoListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
