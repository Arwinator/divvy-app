import 'package:flutter/foundation.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/models/models.dart';

/// ViewModel for group management operations
/// Manages group state and coordinates with GroupRepository
class GroupViewModel extends ChangeNotifier {
  final GroupRepository _repository;

  GroupViewModel({required GroupRepository repository})
    : _repository = repository;

  // State
  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all groups for the current user
  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _repository.getGroups();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new group
  Future<bool> createGroup({required String name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newGroup = await _repository.createGroup(name: name);
      _groups.add(newGroup);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send invitation to a user by email or username
  Future<bool> sendInvitation({
    required int groupId,
    required String identifier,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.sendInvitation(
        groupId: groupId,
        identifier: identifier,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept a group invitation
  Future<bool> acceptInvitation({required int invitationId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final group = await _repository.acceptInvitation(
        invitationId: invitationId,
      );

      // Add the group to the list if not already present
      if (!_groups.any((g) => g.id == group.id)) {
        _groups.add(group);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Decline a group invitation
  Future<bool> declineInvitation({required int invitationId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.declineInvitation(invitationId: invitationId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a member from a group
  Future<bool> removeMember({required int groupId, required int userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.removeMember(groupId: groupId, userId: userId);

      // Update the group in the list
      await loadGroups();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup({required int groupId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.leaveGroup(groupId: groupId);

      // Remove the group from the list
      _groups.removeWhere((g) => g.id == groupId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get a specific group by ID
  GroupModel? getGroupById(int groupId) {
    try {
      return _groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
