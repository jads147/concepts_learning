/// Model-Klasse für Photos von der JSONPlaceholder API
///
/// Repräsentiert ein Photo mit 5.000 verfügbaren Items - perfekt
/// um Lazy Data Loading zu demonstrieren!
class Photo {
  final int albumId;
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  const Photo({
    required this.albumId,
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  /// Erstellt ein Photo-Objekt aus JSON (von API Response)
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      albumId: json['albumId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }

  /// Konvertiert Photo-Objekt zu JSON (für API Requests)
  Map<String, dynamic> toJson() {
    return {
      'albumId': albumId,
      'id': id,
      'title': title,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Photo &&
        other.albumId == albumId &&
        other.id == id &&
        other.title == title &&
        other.url == url &&
        other.thumbnailUrl == thumbnailUrl;
  }

  @override
  int get hashCode {
    return Object.hash(albumId, id, title, url, thumbnailUrl);
  }

  @override
  String toString() {
    return 'Photo(id: $id, albumId: $albumId, title: $title)';
  }
}
