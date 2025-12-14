import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

/// API Service - Verantwortlich für HTTP-Kommunikation
///
/// KONZEPT: Service-Schicht
/// - Isoliert externe Abhängigkeiten (HTTP, Datenbank, etc.)
/// - Macht HTTP-Calls und gibt rohe Daten zurück
/// - Keine Business-Logik
/// - Einfach zu mocken für Tests
///
/// DEPENDENCY INJECTION:
/// - Interface (abstract class) definiert Vertrag
/// - Implementierung kann ausgetauscht werden (z.B. für Tests)
abstract class ApiService {
  Future<List<User>> fetchUsers();
  Future<User> fetchUserById(int id);
}

/// Konkrete Implementierung des ApiService
class ApiServiceImpl implements ApiService {
  final http.Client client;
  final String baseUrl;

  /// Constructor mit Dependency Injection
  /// Der HTTP Client wird von außen übergeben (testbar!)
  ApiServiceImpl({
    required this.client,
    this.baseUrl = 'https://jsonplaceholder.typicode.com',
  });

  @override
  Future<List<User>> fetchUsers() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to load users. Status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  @override
  Future<User> fetchUserById(int id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/$id'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return User.fromJson(jsonMap);
      } else if (response.statusCode == 404) {
        throw ApiException('User not found', 404);
      } else {
        throw ApiException(
          'Failed to load user. Status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }
}

/// Custom Exception für API-Fehler
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}
