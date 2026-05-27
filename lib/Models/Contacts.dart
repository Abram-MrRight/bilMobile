class WhatsAppContact {
  final int id;
  final String name;
  final String phoneNumber;

  WhatsAppContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory WhatsAppContact.fromJson(Map<String, dynamic> json) {
    return WhatsAppContact(
      id: json['id'],
      name: json['name'] ?? 'Support',
      phoneNumber: json['phone_number'],
    );
  }
}