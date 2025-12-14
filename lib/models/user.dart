/// Model-Klasse für User
///
/// KONZEPT: Models repräsentieren die Datenstruktur der Anwendung
/// - Enthält nur Daten und Logik zur Datenkonvertierung
/// - Keine Business-Logik oder UI-Logik
/// - Immutable (unveränderlich) mit final fields
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  /// Factory Constructor für JSON Deserialisierung
  /// Konvertiert API-Response zu User-Objekt
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }

  /// Konvertiert User-Objekt zu JSON
  /// Nützlich für API-Requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  /// Erstellt eine Kopie mit geänderten Werten
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, email, phone);
  }
}
