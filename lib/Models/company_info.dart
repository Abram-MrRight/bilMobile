import '../services/api/api_constants.dart';

class CompanyInfo {
  final int? id;
  final String type;        // e.g., logo, about, phone, email, address
  final String title;       // e.g., "MyCompany Ltd." or "Phone Numbers"
  final String content;     // description, phone numbers, etc.
  final String? icon;       // optional Material icon name
  final String? color;      // optional hex color
  final String? logoImage;  // optional logo image path
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyInfo({
    this.id,
    required this.type,
    required this.title,
    required this.content,
    this.icon,
    this.color,
    this.logoImage,
    this.createdAt,
    this.updatedAt,
  });
  /// Full logo URL or placeholder
  String get fullLogoUrl {
    return ApiConstants.getCompanyLogoUrl(logoImage);
  }

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id'] as int?,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      logoImage: json['logo_image']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'content': content,
      'icon': icon,
      'color': color,
      'logo_image': logoImage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
