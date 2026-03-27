import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/storage/database_helper.dart';

/// Local data source for Group operations using SQLite
class GroupLocalDataSource {
  final DatabaseHelper _dbHelper;

  GroupLocalDataSource(this._dbHelper);

  /// Save group to local database
  /// Also saves group members to group_members table
  Future<void> saveGroup(GroupModel group) async {
    await _dbHelper.insert('groups', group.toMap());

    // Save group members
    for (final member in group.members) {
      await _dbHelper.insert('group_members', {
        'group_id': group.id,
        'user_id': member.id,
        'username': member.username,
        'email': member.email,
      });
    }
  }

  /// Get all groups from local database with members
  Future<List<GroupModel>> getGroups() async {
    final groupMaps = await _dbHelper.query(
      'groups',
      orderBy: 'created_at DESC',
    );

    final groups = <GroupModel>[];
    for (final groupMap in groupMaps) {
      final members = await _getGroupMembers(groupMap['id'] as int);
      groups.add(GroupModel.fromMap(groupMap).copyWith(members: members));
    }

    return groups;
  }

  /// Get group by ID with members
  Future<GroupModel?> getGroupById(int groupId) async {
    final results = await _dbHelper.query(
      'groups',
      where: 'id = ?',
      whereArgs: [groupId],
    );

    if (results.isEmpty) return null;

    final members = await _getGroupMembers(groupId);
    return GroupModel.fromMap(results.first).copyWith(members: members);
  }

  /// Delete group from local database
  /// Cascade deletes group_members automatically
  Future<void> deleteGroup(int groupId) async {
    await _dbHelper.delete('groups', where: 'id = ?', whereArgs: [groupId]);
  }

  /// Upsert multiple groups (insert or update)
  /// Used during sync to update local cache
  Future<void> upsertGroups(List<GroupModel> groups) async {
    for (final group in groups) {
      await _dbHelper.insert('groups', group.toMap());

      // Delete existing members and re-insert
      await _dbHelper.delete(
        'group_members',
        where: 'group_id = ?',
        whereArgs: [group.id],
      );

      for (final member in group.members) {
        await _dbHelper.insert('group_members', {
          'group_id': group.id,
          'user_id': member.id,
          'username': member.username,
          'email': member.email,
        });
      }
    }
  }

  /// Helper method to get group members
  Future<List<UserModel>> _getGroupMembers(int groupId) async {
    final memberMaps = await _dbHelper.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );

    return memberMaps
        .map(
          (map) => UserModel(
            id: map['user_id'] as int,
            username: map['username'] as String,
            email: map['email'] as String,
            createdAt: DateTime.now(), // Not stored in group_members
          ),
        )
        .toList();
  }
}

// Extension to add copyWith method to GroupModel
extension GroupModelExtension on GroupModel {
  GroupModel copyWith({
    int? id,
    String? name,
    int? creatorId,
    List<UserModel>? members,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
