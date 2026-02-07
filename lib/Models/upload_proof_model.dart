import 'package:get/get.dart';
import '../services/api/api_constants.dart';

class Proof {
  final int? id;
  final String? imageUrl;
  late final int userId;
  final String? senderName;
  final String? receiverName;
  final String? receiverContact;
  final String? receiverEmail;
  final String amount;
  final String currency;
  final String? notes;
  final RxString status;
  final RxString statusNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RxBool isRead;
  final RxBool isNewForAdmin;

  Proof({
    this.id,
    this.imageUrl,
    required this.userId,
    this.senderName,
    this.receiverName,
    this.receiverContact,
    this.receiverEmail,
    required this.amount,
    required this.currency,
    this.notes,
    String? status,
    String? statusNote,
    this.createdAt,
    this.updatedAt,
    RxBool? isRead,
    RxBool? isNewForAdmin,
  })  : status = (status ?? '').obs,
        statusNote = (statusNote ?? '').obs,
        isRead = isRead ?? false.obs,
        isNewForAdmin = isNewForAdmin ?? true.obs;

  /// Full proof image URL or placeholder
  String get fullImageUrl {
    return ApiConstants.getProofImageUrl(imageUrl);
  }

  factory Proof.fromJson(Map<String, dynamic> json) {
    return Proof(
      id: json['id'] as int?,
      // Support both backend keys: image or image_url
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      senderName: json['sender_name']?.toString(),
      receiverName: json['receiver_name']?.toString(),
      receiverContact: json['receiver_contact']?.toString(),
      receiverEmail: json['receiver_email']?.toString(),
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? '',
      notes: json['notes']?.toString(),
      status: json['status']?.toString(),
      statusNote: json['status_note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      isRead: (json['is_read'] == true || json['is_read'] == 1).obs,
      isNewForAdmin:
      (json['is_new_for_admin'] == true || json['is_new_for_admin'] == 1).obs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'user_id': userId,
      'receiver_name': receiverName,
      'receiver_contact': receiverContact,
      'sender_name': senderName,
      'receiver_email': receiverEmail,
      'amount': amount,
      'currency': currency,
      'notes': notes,
      'status': status.value,
      'status_note': statusNote.value,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_read': isRead.value ? 1 : 0,
      'is_new_for_admin': isNewForAdmin.value ? 1 : 0,
    };
  }
}
