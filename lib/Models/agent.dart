import '../services/api/api_constants.dart';

class Agent {
  final int? id;
  final String name;
  final String? accountName;
  final String? phone;
  final String? email;
  final String? logoImage; // stored path from server: "agent-logos/xxx.jpg"
  final String? notes;

  Agent({
    this.id,
    required this.name,
    this.accountName,
    this.phone,
    this.email,
    this.logoImage,
    this.notes,
  });

  String get fullLogoUrl {
    if (logoImage == null || logoImage!.isEmpty) {
      return '${ApiConstants.publicBaseUrl}/images/logo.png';
    }
    return ApiConstants.getFullMediaUrl(logoImage!);
  }

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
    id: json['id'] == null ? null : int.tryParse(json['id'].toString()),
    name: json['name']?.toString() ?? '',
    accountName: json['account_name']?.toString(),
    phone: json['phone']?.toString(),
    email: json['email']?.toString(),
    logoImage: json['logo_image']?.toString(),
    notes: json['notes']?.toString(),
  );
}
