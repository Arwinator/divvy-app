import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/group_model.dart';

/// Invitation response from API
class InvitationResponse {
  final int id;
  final int groupId;
  final int inviterId;
  final int inviteeId;
  final String status;
  final DateTime createdAt;

  InvitationResponse({
    required this.id,
    required this.groupId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    required this.createdAt,
  });

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    return InvitationResponse(
      id: json['id'],
      groupId: json['group_id'],
      inviterId: json['inviter_id'],
      inviteeId: json['invitee_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Remote data source for group management operations
class GroupRemoteDataSource {
  final ApiClient apiClient;

  GroupRemoteDataSource({required this.apiClient});

  /// Create a new group
  /// POST /api/groups
  Future<GroupModel> createGroup({required String name}) async {
    final response = await apiClient.post(ApiConstants.groups, {'name': name});

    return GroupModel.fromJson(response);
  }

  /// Get all groups for the authenticated user
  /// GET /api/groups
  Future<List<GroupModel>> getGroups() async {
    final response = await apiClient.get(ApiConstants.groups);

    final List<dynamic> groupsData = response['data'];
    return groupsData.map((json) => GroupModel.fromJson(json)).toList();
  }

  /// Send an invitation to join a group
  /// POST /api/groups/{id}/invitations
  Future<InvitationResponse> sendInvitation({
    required int groupId,
    required String identifier,
  }) async {
    final response = await apiClient.post(
      ApiConstants.groupInvitations(groupId),
      {'identifier': identifier},
    );

    return InvitationResponse.fromJson(response);
  }

  /// Accept a group invitation
  /// POST /api/invitations/{id}/accept
  Future<GroupModel> acceptInvitation({required int invitationId}) async {
    final response = await apiClient.post(
      ApiConstants.acceptInvitation(invitationId),
      {},
    );

    return GroupModel.fromJson(response['group']);
  }

  /// Decline a group invitation
  /// POST /api/invitations/{id}/decline
  Future<void> declineInvitation({required int invitationId}) async {
    await apiClient.post(ApiConstants.declineInvitation(invitationId), {});
  }

  /// Remove a member from a group (creator only)
  /// DELETE /api/groups/{id}/members/{userId}
  Future<void> removeMember({required int groupId, required int userId}) async {
    await apiClient.delete('${ApiConstants.groupMembers(groupId)}/$userId');
  }

  /// Leave a group (non-creator only)
  /// POST /api/groups/{id}/leave
  Future<void> leaveGroup({required int groupId}) async {
    await apiClient.post('${ApiConstants.groups}/$groupId/leave', {});
  }
}
