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

  /// Getter to return full URL for logo or placeholder
  /// Detailed getter for company logo URL
  String get fullLogoUrl {
    // If no logo, return a company-specific placeholder
    if (logoImage == null || logoImage!.isEmpty) {
      return 'assets/images/company_logo_placeholder.png';
    }

    String path = logoImage!;

    // Handle different backend response formats for company logos
    if (path.startsWith('http')) {
      // Clean full URL
      return _cleanLogoUrl(path);
    }

    // Company logos might be in different locations
    if (path.startsWith('/static/')) {
      // Static files (common for logos)
      return '${ApiConstants.publicBaseUrl}$path';
    }

    if (path.startsWith('/media/company/') || path.startsWith('/media/logos/')) {
      return '${ApiConstants.publicBaseUrl}$path';
    }

    if (path.startsWith('company/') || path.startsWith('logos/')) {
      return '${ApiConstants.publicBaseUrl}/media/$path';
    }

    // Fallback to generic
    return ApiConstants.getFullMediaUrl(path, defaultPath: 'media/company/logo.png');
  }

  /// Special cleaning for logo URLs
  String _cleanLogoUrl(String url) {
    // Company logos might have specific issues
    const baseUrl = 'http://10.0.2.2:8000';

    // Fix common backend response issues
    if (url.contains('$baseUrl/static$baseUrl')) {
      url = url.replaceAll('$baseUrl/static$baseUrl', '$baseUrl/static');
    }

    return url;
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
