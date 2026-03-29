import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';
import 'package:divvy/data/models/models.dart';

/// Repository for group management operations
/// Implements offline-first pattern with background sync
class GroupRepository {
  final remote.GroupRemoteDataSource remoteDataSource;
  final local.GroupLocalDataSource localDataSource;
  final local.SyncQueueLocalDataSource syncQueueDataSource;
  final NetworkInfo networkInfo;

  GroupRepository({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncQueueDataSource,
    required this.networkInfo,
  });

  /// Create a new group
  /// Tries remote first, queues for sync if offline, saves locally
  Future<GroupModel> createGroup({required String name}) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Try remote creation
        final group = await remoteDataSource.createGroup(name: name);

        // Save to local cache
        await localDataSource.saveGroup(group);

        return group;
      } catch (e) {
        // If remote fails, queue for sync
        await _queueGroupCreation(name);
        rethrow;
      }
    } else {
      // Offline: queue for sync
      await _queueGroupCreation(name);
      throw Exception(
        'Cannot create group while offline. Will sync when online.',
      );
    }
  }

  /// Queue group creation for later sync
  Future<void> _queueGroupCreation(String name) async {
    final operation = local.SyncOperation(
      operationType: 'create_group',
      endpoint: '/api/groups',
      payload: {'name': name},
      createdAt: DateTime.now(),
    );
    await syncQueueDataSource.addOperation(operation);
  }

  /// Get all groups for current user
  /// Returns from cache, syncs in background if online
  Future<List<GroupModel>> getGroups() async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Fetch from remote
        final groups = await remoteDataSource.getGroups();

        // Update local cache
        for (final group in groups) {
          await localDataSource.saveGroup(group);
        }

        return groups;
      } catch (e) {
        // If remote fails, return cached data
        return await localDataSource.getGroups();
      }
    } else {
      // Offline: return cached data
      return await localDataSource.getGroups();
    }
  }

  /// Get pending invitations for current user
  /// Requires online connection
  Future<List<InvitationModel>> getInvitations() async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      throw Exception('Cannot fetch invitations while offline');
    }

    return await remoteDataSource.getInvitations();
  }

  /// Get a specific group by ID
  /// Returns from cache, syncs in background if online
  Future<GroupModel?> getGroup(int groupId) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Try to fetch from remote (not implemented in remote datasource yet)
        // For now, return from cache
        return await localDataSource.getGroupById(groupId);
      } catch (e) {
        return await localDataSource.getGroupById(groupId);
      }
    } else {
      return await localDataSource.getGroupById(groupId);
    }
  }

  /// Send group invitation
  /// Requires online connection
  Future<void> sendInvitation({
    required int groupId,
    required String identifier,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      throw Exception('Cannot send invitation while offline');
    }

    await remoteDataSource.sendInvitation(
      groupId: groupId,
      identifier: identifier,
    );
  }

  /// Accept group invitation
  /// Requires online connection
  Future<GroupModel> acceptInvitation({required int invitationId}) async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      throw Exception('Cannot accept invitation while offline');
    }

    final group = await remoteDataSource.acceptInvitation(
      invitationId: invitationId,
    );

    // Save to local cache
    await localDataSource.saveGroup(group);

    return group;
  }

  /// Decline group invitation
  /// Requires online connection
  Future<void> declineInvitation({required int invitationId}) async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      throw Exception('Cannot decline invitation while offline');
    }

    await remoteDataSource.declineInvitation(invitationId: invitationId);
  }

  /// Remove member from group
  /// Requires online connection
  Future<void> removeMember({required int groupId, required int userId}) async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      throw Exception('Cannot remove member while offline');
    }

    await remoteDataSource.removeMember(groupId: groupId, userId: userId);

    // Refresh group data from remote
    final groups = await remoteDataSource.getGroups();
    for (final group in groups) {
      await localDataSource.saveGroup(group);
    }
  }

  /// Leave a group
  /// Requires online connection
  Future<void> leaveGroup({required int groupId}) async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      throw Exception('Cannot leave group while offline');
    }

    await remoteDataSource.leaveGroup(groupId: groupId);

    // Remove from local cache
    await localDataSource.deleteGroup(groupId);
  }
}
