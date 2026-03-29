/// Model for group invitations
class InvitationModel {
  final int id;
  final int groupId;
  final String groupName;
  final int inviterId;
  final String inviterUsername;
  final String status;
  final DateTime createdAt;

  InvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterId,
    required this.inviterUsername,
    required this.status,
    required this.createdAt,
  });

  /// Create from API JSON response
  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'],
      groupId: json['group_id'],
      groupName: json['group_name'],
      inviterId: json['inviter_id'],
      inviterUsername: json['inviter_username'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'group_name': groupName,
      'inviter_id': inviterId,
      'inviter_username': inviterUsername,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
