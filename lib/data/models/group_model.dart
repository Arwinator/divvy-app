import 'user_model.dart';

/// Group model for API communication and local storage
class GroupModel {
  final int id;
  final String name;
  final int creatorId;
  final List<UserModel> members;
  final DateTime createdAt;
  final bool isSynced;

  GroupModel({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.members,
    required this.createdAt,
    this.isSynced = true,
  });

  /// Create Group from API JSON response
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      creatorId: json['creator_id'],
      members: (json['members'] as List)
          .map((m) => UserModel.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convert Group to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creator_id': creatorId,
      'members': members.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create Group from SQLite Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'],
      creatorId: map['creator_id'],
      members: [], // Members loaded separately via join
      createdAt: DateTime.parse(map['created_at']),
      isSynced: map['is_synced'] == 1,
    );
  }

  /// Convert Group to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
