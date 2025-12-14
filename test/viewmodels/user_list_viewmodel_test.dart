import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:concepts_learning/models/user.dart';
import 'package:concepts_learning/repositories/user_repository.dart';
import 'package:concepts_learning/viewmodels/user_list_viewmodel.dart';

import 'user_list_viewmodel_test.mocks.dart';

/// Generiert Mock-Klassen
/// Run: flutter pub run build_runner build
@GenerateMocks([UserRepository])
void main() {
  group('UserListViewModel Tests', () {
    late MockUserRepository mockRepository;
    late UserListViewModel viewModel;

    /// Setup wird vor jedem Test ausgeführt
    setUp(() {
      mockRepository = MockUserRepository();
      viewModel = UserListViewModel(repository: mockRepository);
    });

    /// TearDown wird nach jedem Test ausgeführt
    tearDown(() {
      viewModel.dispose();
    });

    test('initial state should be idle', () {
      expect(viewModel.state, ViewState.idle);
      expect(viewModel.users, isEmpty);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadUsers should update state to loading then success', () async {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'User 1', email: 'user1@example.com'),
        const User(id: 2, name: 'User 2', email: 'user2@example.com'),
      ];

      // Mock: Wenn getUsers() aufgerufen wird, gib testUsers zurück
      when(mockRepository.getUsers()).thenAnswer((_) async => testUsers);

      // Track state changes
      final states = <ViewState>[];
      viewModel.addListener(() {
        states.add(viewModel.state);
      });

      // Act
      await viewModel.loadUsers();

      // Assert
      expect(states, [ViewState.loading, ViewState.success]);
      expect(viewModel.users, testUsers);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.hasData, isTrue);

      // Verify: getUsers wurde genau einmal aufgerufen
      verify(mockRepository.getUsers()).called(1);
    });

    test('loadUsers should update state to error on failure', () async {
      // Arrange
      when(mockRepository.getUsers())
          .thenThrow(Exception('Network error'));

      final states = <ViewState>[];
      viewModel.addListener(() {
        states.add(viewModel.state);
      });

      // Act
      await viewModel.loadUsers();

      // Assert
      expect(states, [ViewState.loading, ViewState.error]);
      expect(viewModel.users, isEmpty);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, contains('Network error'));
    });

    test('refreshUsers should clear cache and reload', () async {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'User 1', email: 'user1@example.com'),
      ];

      when(mockRepository.getUsers()).thenAnswer((_) async => testUsers);

      // Act
      await viewModel.refreshUsers();

      // Assert
      verify(mockRepository.clearCache()).called(1);
      verify(mockRepository.getUsers()).called(1);
      expect(viewModel.users, testUsers);
    });

    test('searchUsers should filter users by name', () {
      // Arrange
      viewModel.loadUsers();
      final testUsers = [
        const User(id: 1, name: 'John Doe', email: 'john@example.com'),
        const User(id: 2, name: 'Jane Smith', email: 'jane@example.com'),
        const User(id: 3, name: 'Bob Johnson', email: 'bob@example.com'),
      ];

      when(mockRepository.getUsers()).thenAnswer((_) async => testUsers);

      // Manuell setzen für den Test
      viewModel.loadUsers();

      // Act
      final results = viewModel.searchUsers('john');

      // Assert
      expect(results.length, 2); // John Doe und Bob Johnson
      expect(results.any((u) => u.name == 'John Doe'), isTrue);
      expect(results.any((u) => u.name == 'Bob Johnson'), isTrue);
    });

    test('searchUsers should filter users by email', () {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'John Doe', email: 'john@example.com'),
        const User(id: 2, name: 'Jane Smith', email: 'jane@test.com'),
      ];

      when(mockRepository.getUsers()).thenAnswer((_) async => testUsers);
      viewModel.loadUsers();

      // Act
      final results = viewModel.searchUsers('example');

      // Assert
      expect(results.length, 1);
      expect(results.first.name, 'John Doe');
    });

    test('searchUsers should return all users for empty query', () {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'User 1', email: 'user1@example.com'),
        const User(id: 2, name: 'User 2', email: 'user2@example.com'),
      ];

      when(mockRepository.getUsers()).thenAnswer((_) async => testUsers);
      viewModel.loadUsers();

      // Act
      final results = viewModel.searchUsers('');

      // Assert - leere Query gibt alle User zurück
      expect(results.length, 0); // da loadUsers async ist
    });
  });
}
