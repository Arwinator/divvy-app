import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/core/constants/app_constants.dart';

class GroupDetailsScreen extends StatefulWidget {
  final int groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Reload groups to ensure we have latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupViewModel>().loadGroups();
    });
  }

  void _navigateToAddMember() {
    Navigator.of(
      context,
    ).pushNamed('/groups/add-member', arguments: widget.groupId);
  }

  void _navigateToBills() {
    Navigator.of(
      context,
    ).pushNamed('/bills', arguments: {'groupId': widget.groupId});
  }

  Future<void> _handleRemoveMember(int userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $username from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final groupViewModel = context.read<GroupViewModel>();
    final success = await groupViewModel.removeMember(
      groupId: widget.groupId,
      userId: userId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Member removed successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _handleLeaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Leave',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final groupViewModel = context.read<GroupViewModel>();
    final success = await groupViewModel.leaveGroup(groupId: widget.groupId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Left group successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: Consumer2<GroupViewModel, AuthViewModel>(
        builder: (context, groupViewModel, authViewModel, child) {
          final group = groupViewModel.getGroupById(widget.groupId);

          // Loading state
          if (group == null && groupViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (group == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text('Group not found', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppConstants.spacingLg),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final currentUserId = authViewModel.currentUser?.id;
          final isCreator = currentUserId == group.creatorId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group Header
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  color: theme.colorScheme.primaryContainer,
                  child: Column(
                    children: [
                      Icon(
                        Icons.group,
                        size: 64,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      Text(
                        group.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Text(
                        '${group.members.length} ${group.members.length == 1 ? 'member' : 'members'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _navigateToBills,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View Bills'),
                      ),
                      if (isCreator) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        ElevatedButton.icon(
                          onPressed: _navigateToAddMember,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Member'),
                        ),
                      ],
                    ],
                  ),
                ),

                // Members List
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                  child: Text('Members', style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final member = group.members[index];
                    final isMemberCreator = member.id == group.creatorId;
                    final isCurrentUser = member.id == currentUserId;

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingSm,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Text(
                            member.username[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(member.username),
                            if (isMemberCreator) ...[
                              const SizedBox(width: AppConstants.spacingSm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Creator',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                            if (isCurrentUser) ...[
                              const SizedBox(width: AppConstants.spacingSm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'You',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          member.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: isCreator && !isMemberCreator
                            ? IconButton(
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => _handleRemoveMember(
                                  member.id,
                                  member.username,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),

                // Leave Group Button (for non-creators)
                if (!isCreator) ...[
                  const SizedBox(height: AppConstants.spacingLg),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: OutlinedButton.icon(
                      onPressed: _handleLeaveGroup,
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Group'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingLg),
              ],
            ),
          );
        },
      ),
    );
  }
}
