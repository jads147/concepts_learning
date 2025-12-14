import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/photo.dart';

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

  /// Lädt Photos mit Pagination-Support
  ///
  /// [start] - Ab welchem Index soll geladen werden (0-basiert)
  /// [limit] - Wie viele Photos sollen geladen werden
  ///
  /// Beispiel: fetchPhotos(start: 0, limit: 20) lädt die ersten 20 Photos
  /// Beispiel: fetchPhotos(start: 20, limit: 20) lädt Photos 20-39
  Future<List<Photo>> fetchPhotos({int start = 0, int limit = 20});
}

/// Konkrete Implementierung des ApiService
class ApiServiceImpl implements ApiService {
  final http.Client client;
  final String baseUrl;

  /// Constructor mit Dependency Injection.
  /// Der HTTP Client wird von außen übergeben (testbar!).
  /// Die Url ist eine gratis Mock Url.
  ApiServiceImpl({
    required this.client,
    this.baseUrl = 'https://jsonplaceholder.typicode.com',
  });

  @override
  Future<List<User>> fetchUsers() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/users'));

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
      final response = await client.get(Uri.parse('$baseUrl/users/$id'));

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

  @override
  Future<List<Photo>> fetchPhotos({int start = 0, int limit = 20}) async {
    try {
      // Query-Parameter für Pagination:
      // _start = Ab welchem Index (0-basiert)
      // _limit = Wie viele Items maximal
      //
      // WICHTIG: Dies demonstriert LAZY DATA LOADING!
      // Statt alle 5.000 Photos zu laden, laden wir nur 20 auf einmal.
      final uri = Uri.parse('$baseUrl/photos').replace(queryParameters: {
        '_start': start.toString(),
        '_limit': limit.toString(),
      });

      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Photo.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to load photos. Status: ${response.statusCode}',
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
  String toString() =>
      'ApiException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}
