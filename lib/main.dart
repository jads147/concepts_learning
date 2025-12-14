import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/user_repository_impl.dart';
import 'viewmodels/user_list_viewmodel.dart';
import 'viewmodels/user_detail_viewmodel.dart';
import 'views/user_list_screen.dart';

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
        home: const UserListScreen(),
      ),
    );
  }
}
