import '../services/api/api_constants.dart';

class AuthUser {
  final int id;
  final String fullname;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String? location;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profileImage;

  AuthUser({
    required this.id,
    required this.fullname,
    this.email,
    this.phoneNumber,
    this.role,
    this.location,
    this.accessToken,
    this.refreshToken,
    this.createdAt,
    this.updatedAt,
    this.profileImage,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      fullname: json['fullname'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String?,
      location: json['location'] as String?,
      accessToken: json['token']?['access'],
      refreshToken: json['token']?['refresh'],
      profileImage: json['profile_image'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // 👇 This is the missing piece you need to add
  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id'] as int,
      fullname: map['fullname'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phone_number'] as String?,
      role: map['role'] as String?,
      location: map['location'] as String?,
      profileImage: map['profile_image'] as String?,
      accessToken: map['access_token'] as String?,  // Read from database
      refreshToken: map['refresh_token'] as String?, // Read from database
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullname,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'role': role,
      'location': location,  // Add this
      'access_token': accessToken,  // CRITICAL: Add this
      'refresh_token': refreshToken, // CRITICAL: Add this
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  /// Getter to return full URL for profile image with error fixing
  String get fullProfileImageUrl {
    if (profileImage == null || profileImage!.isEmpty) {
      return '${ApiConstants.publicBaseUrl}/media/profile_images/default_avatar.png';
    }

    String url = profileImage!;

    // ⭐⭐⭐ FIX THE MALFORMED URL PATTERN ⭐⭐⭐
    const baseUrl = 'http://10.0.2.2:8000';
    const malformedPattern = '$baseUrl/storage/$baseUrl/';

    if (url.startsWith(malformedPattern)) {
      print('🔄 Fixing malformed profile image URL');
      print('   Before: $url');
      url = url.replaceFirst(malformedPattern, '$baseUrl/');
      print('   After:  $url');
      return url;
    }

    // Also fix other possible malformed patterns
    if (url.contains('/storage/http://')) {
      url = url.replaceAll('/storage/http://', 'http://');
    }

    if (url.contains('/storage/https://')) {
      url = url.replaceAll('/storage/https://', 'https://');
    }

    // If it's already a proper full URL, return it
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If it's a relative path, construct the full URL
    return ApiConstants.getFullMediaUrl(url, defaultPath: 'media/profile_images/default_avatar.png');
  }
}