import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:concepts_learning/models/user.dart';
import 'package:concepts_learning/viewmodels/user_list_viewmodel.dart';
import 'package:concepts_learning/views/user_list_screen.dart';

import 'user_list_screen_test.mocks.dart';

/// Widget Tests
///
/// KONZEPT: Widget Testing
/// - Testet UI-Komponenten
/// - Verifiziert dass UI korrekt auf State-Änderungen reagiert
/// - Nutzt testWidgets() statt test()
/// - Verwendet WidgetTester für Interaktionen
@GenerateMocks([UserListViewModel])
void main() {
  group('UserListScreen Widget Tests', () {
    late MockUserListViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockUserListViewModel();
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      // Arrange
      when(mockViewModel.isLoading).thenReturn(true);
      when(mockViewModel.hasError).thenReturn(false);
      when(mockViewModel.hasData).thenReturn(false);
      when(mockViewModel.users).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserListViewModel>.value(
            value: mockViewModel,
            child: const UserListScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when has error', (tester) async {
      // Arrange
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.hasError).thenReturn(true);
      when(mockViewModel.hasData).thenReturn(false);
      when(mockViewModel.errorMessage).thenReturn('Network error');
      when(mockViewModel.users).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserListViewModel>.value(
            value: mockViewModel,
            child: const UserListScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('Error: Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows user list when has data', (tester) async {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'John Doe', email: 'john@example.com'),
        const User(id: 2, name: 'Jane Smith', email: 'jane@example.com'),
      ];

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.hasError).thenReturn(false);
      when(mockViewModel.hasData).thenReturn(true);
      when(mockViewModel.users).thenReturn(testUsers);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserListViewModel>.value(
            value: mockViewModel,
            child: const UserListScreen(),
          ),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('calls loadUsers when retry button is tapped', (tester) async {
      // Arrange
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.hasError).thenReturn(true);
      when(mockViewModel.hasData).thenReturn(false);
      when(mockViewModel.errorMessage).thenReturn('Error');
      when(mockViewModel.users).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserListViewModel>.value(
            value: mockViewModel,
            child: const UserListScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert
      verify(mockViewModel.loadUsers()).called(1);
    });

    testWidgets('search field filters users', (tester) async {
      // Arrange
      final allUsers = [
        const User(id: 1, name: 'John Doe', email: 'john@example.com'),
        const User(id: 2, name: 'Jane Smith', email: 'jane@example.com'),
      ];

      final filteredUsers = [
        const User(id: 1, name: 'John Doe', email: 'john@example.com'),
      ];

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.hasError).thenReturn(false);
      when(mockViewModel.hasData).thenReturn(true);
      when(mockViewModel.users).thenReturn(allUsers);
      when(mockViewModel.searchUsers('john')).thenReturn(filteredUsers);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserListViewModel>.value(
            value: mockViewModel,
            child: const UserListScreen(),
          ),
        ),
      );

      // Suche nach "john"
      await tester.enterText(find.byType(TextField), 'john');
      await tester.pump();

      // Assert - searchUsers sollte aufgerufen worden sein
      verify(mockViewModel.searchUsers('john')).called(greaterThan(0));
    });
  });
}
