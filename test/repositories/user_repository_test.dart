import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:concepts_learning/models/user.dart';
import 'package:concepts_learning/repositories/user_repository.dart';
import 'package:concepts_learning/services/api_service.dart';

import 'user_repository_test.mocks.dart';

/// Generiert Mock-Klassen für ApiService
/// Run: flutter pub run build_runner build
@GenerateMocks([ApiService])
void main() {
  group('UserRepository Tests', () {
    late MockApiService mockApiService;
    late UserRepositoryImpl repository;

    setUp(() {
      mockApiService = MockApiService();
      repository = UserRepositoryImpl(apiService: mockApiService);
    });

    test('getUsers should return cached users on second call', () async {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'User 1', email: 'user1@example.com'),
      ];

      when(mockApiService.fetchUsers()).thenAnswer((_) async => testUsers);

      // Act
      final firstCall = await repository.getUsers();
      final secondCall = await repository.getUsers();

      // Assert
      expect(firstCall, testUsers);
      expect(secondCall, testUsers);
      // API sollte nur einmal aufgerufen werden (Caching!)
      verify(mockApiService.fetchUsers()).called(1);
    });

    test('getUsers should fetch from API when cache is empty', () async {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'User 1', email: 'user1@example.com'),
      ];

      when(mockApiService.fetchUsers()).thenAnswer((_) async => testUsers);

      // Act
      final result = await repository.getUsers();

      // Assert
      expect(result, testUsers);
      verify(mockApiService.fetchUsers()).called(1);
    });

    test('getUserById should return user from API', () async {
      // Arrange
      const testUser = User(id: 1, name: 'User 1', email: 'user1@example.com');

      when(mockApiService.fetchUserById(1)).thenAnswer((_) async => testUser);

      // Act
      final result = await repository.getUserById(1);

      // Assert
      expect(result, testUser);
      verify(mockApiService.fetchUserById(1)).called(1);
    });

    test('getUserById should cache user', () async {
      // Arrange
      const testUser = User(id: 1, name: 'User 1', email: 'user1@example.com');

      when(mockApiService.fetchUserById(1)).thenAnswer((_) async => testUser);

      // Act
      final firstCall = await repository.getUserById(1);
      final secondCall = await repository.getUserById(1);

      // Assert
      expect(firstCall, testUser);
      expect(secondCall, testUser);
      // API sollte nur einmal aufgerufen werden
      verify(mockApiService.fetchUserById(1)).called(1);
    });

    test('clearCache should clear all cached data', () async {
      // Arrange
      final testUsers = [
        const User(id: 1, name: 'User 1', email: 'user1@example.com'),
      ];

      when(mockApiService.fetchUsers()).thenAnswer((_) async => testUsers);

      // Erst Daten laden (wird gecached)
      await repository.getUsers();

      // Cache leeren
      repository.clearCache();

      // Nochmal laden
      await repository.getUsers();

      // Assert: fetchUsers sollte jetzt 2x aufgerufen worden sein (einmal vor clear, einmal nach)
      verify(mockApiService.fetchUsers()).called(2);
    });

    test('getUsers should rethrow exception and clear cache on error', () async {
      // Arrange
      when(mockApiService.fetchUsers())
          .thenThrow(ApiException('Network error'));

      // Act & Assert
      expect(
        () => repository.getUsers(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
