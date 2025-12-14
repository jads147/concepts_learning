import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_detail_viewmodel.dart';

/// User Detail Screen
///
/// Zeigt Details eines einzelnen Users
/// Demonstriert:
/// - ChangeNotifierProvider.value für existierende Provider
/// - Erstellen eines neuen ViewModels für diesen Screen
class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Daten laden nach dem ersten Build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserDetailViewModel>().loadUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<UserDetailViewModel>(
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
                    onPressed: () => viewModel.loadUser(widget.userId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Success State
          final user = viewModel.user;
          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info Cards
                _InfoCard(
                  icon: Icons.person,
                  title: 'Name',
                  value: user.name,
                ),
                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.email,
                  title: 'Email',
                  value: user.email,
                ),
                const SizedBox(height: 12),

                if (user.phone != null)
                  _InfoCard(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: user.phone!,
                  ),

                const SizedBox(height: 24),

                // ID Badge
                Center(
                  child: Chip(
                    avatar: const Icon(Icons.tag, size: 16),
                    label: Text('ID: ${user.id}'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Info Card Widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
