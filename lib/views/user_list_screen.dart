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
    // Daten beim ersten Laden abrufen
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
      appBar: AppBar(
        title: const Text('Users (MVVM Demo)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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

          // User-Liste
          Expanded(
            child: Consumer<UserListViewModel>(
              builder: (context, viewModel, child) {
                // Loading State
                if (viewModel.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error State
                if (viewModel.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                // Success State mit Daten
                final users = _searchQuery.isEmpty
                    ? viewModel.users
                    : viewModel.searchUsers(_searchQuery);

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users match your search'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.refreshUsers(),
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
        leading: CircleAvatar(
          child: Text(user.name[0].toUpperCase()),
        ),
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation zu Detail-Screen
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
