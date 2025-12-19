class StatusUpdate {
  final int id;
  final int userId;
  final int proofId;
  final String status;
  final String? statusNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isRead;

  StatusUpdate({
    required this.id,
    required this.userId,
    required this.proofId,
    required this.status,
    this.statusNote,
    this.createdAt,
    this.updatedAt,
    this.isRead = false,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      id: json['id'] ?? 0,           // default to 0 if null
      userId: json['user_id'] ?? 0,  // default to 0 if null
      proofId: json['proof_id'] ?? 0,
      status: json['status'] ?? '',
      statusNote: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isRead: (json['is_read'] ?? 0) == 1,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'proof_id': proofId,
      'status': status,
      if (statusNote != null) 'notes': statusNote,
      'is_read': isRead ? 1 : 0,
    };
  }
}
