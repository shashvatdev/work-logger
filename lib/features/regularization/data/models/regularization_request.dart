class RegularizationRequest {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String date; // yyyy-MM-dd
  final String? requestedPunchIn;
  final String? requestedPunchOut;
  final String reason;
  final String? adminNotes;
  final String status; // PENDING, APPROVED, REJECTED
  final String createdAt;

  RegularizationRequest({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.date,
    this.requestedPunchIn,
    this.requestedPunchOut,
    required this.reason,
    this.adminNotes,
    required this.status,
    required this.createdAt,
  });

  factory RegularizationRequest.fromJson(Map<String, dynamic> json) {
    return RegularizationRequest(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? (json['user'] is Map ? json['user']['name'] : null),
      userAvatar: json['userAvatar'],
      date: json['date'] ?? '',
      requestedPunchIn: json['requestedPunchInTime'] ?? json['requestedPunchIn'],
      requestedPunchOut: json['requestedPunchOutTime'] ?? json['requestedPunchOut'],
      reason: json['reason'] ?? '',
      adminNotes: json['adminNotes'],
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
