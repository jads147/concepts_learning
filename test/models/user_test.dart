import 'package:flutter_test/flutter_test.dart';
import 'package:concepts_learning/models/user.dart';

/// Unit Tests für User Model
///
/// KONZEPT: Unit Testing
/// - Teste isolierte Komponenten (Models, ViewModels, Repositories)
/// - Keine Dependencies zu anderen Komponenten
/// - Schnell und deterministisch
void main() {
  group('User Model Tests', () {
    test('fromJson should create User from JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '123-456-7890',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, 1);
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '123-456-7890');
    });

    test('fromJson should handle null phone', () {
      final json = {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': null,
      };

      final user = User.fromJson(json);

      expect(user.phone, isNull);
    });

    test('toJson should convert User to JSON', () {
      // Arrange
      const user = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        phone: '123-456-7890',
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['id'], 1);
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['phone'], '123-456-7890');
    });

    test('copyWith should create a copy with updated values', () {
      const original = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      final updated = original.copyWith(
        name: 'Jane Doe',
        email: 'jane@example.com',
      );

      expect(updated.id, 1); // unchanged
      expect(updated.name, 'Jane Doe'); // changed
      expect(updated.email, 'jane@example.com'); // changed
    });

    test('equality should work correctly', () {
      const user1 = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      const user2 = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      const user3 = User(
        id: 2,
        name: 'Jane Doe',
        email: 'jane@example.com',
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('hashCode should be consistent', () {
      const user1 = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      const user2 = User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      expect(user1.hashCode, equals(user2.hashCode));
    });
  });
}
