class Announcement {
  final int id;
  final String title;
  final String description;
  final String? image;
  final String? imageUrl;
  final int? createdBy;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.imageUrl,
    this.createdBy,
    required this.isActive,
    this.startAt,
    this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to parse JSON from API
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      imageUrl: json['image_url'],
      createdBy: json['created_by'],
      isActive: json['is_active'] ?? true,
      startAt: json['start_at'] != null ? DateTime.parse(json['start_at']) : null,
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convert to JSON for API POST/PUT
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'is_active': isActive,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
    };
  }
}
