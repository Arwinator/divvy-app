import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/core/constants/app_constants.dart';

/// Screen for displaying and managing group invitations
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load invitations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupViewModel>().loadInvitations();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<GroupViewModel>().loadInvitations();
  }

  Future<void> _handleAccept(int invitationId, String groupName) async {
    final groupViewModel = context.read<GroupViewModel>();
    final success = await groupViewModel.acceptInvitation(
      invitationId: invitationId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined $groupName successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _handleDecline(int invitationId, String groupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: Text(
          'Are you sure you want to decline the invitation to $groupName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Decline',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final groupViewModel = context.read<GroupViewModel>();
    final success = await groupViewModel.declineInvitation(
      invitationId: invitationId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Declined invitation to $groupName'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: Consumer<GroupViewModel>(
        builder: (context, groupViewModel, child) {
          // Loading state
          if (groupViewModel.isLoading && groupViewModel.invitations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (groupViewModel.error != null &&
              groupViewModel.invitations.isEmpty) {
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
                    Text(
                      'Failed to load invitations',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      groupViewModel.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    ElevatedButton.icon(
                      onPressed: _handleRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          if (groupViewModel.invitations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      'No pending invitations',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'When someone invites you to a group, you\'ll see it here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Invitations list
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              itemCount: groupViewModel.invitations.length,
              itemBuilder: (context, index) {
                final invitation = groupViewModel.invitations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group name
                        Row(
                          children: [
                            Icon(Icons.group, color: theme.colorScheme.primary),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Text(
                                invitation.groupName,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        // Inviter info
                        Text(
                          'Invited by ${invitation.inviterUsername}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: groupViewModel.isLoading
                                  ? null
                                  : () => _handleDecline(
                                      invitation.id,
                                      invitation.groupName,
                                    ),
                              child: const Text('Decline'),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            ElevatedButton(
                              onPressed: groupViewModel.isLoading
                                  ? null
                                  : () => _handleAccept(
                                      invitation.id,
                                      invitation.groupName,
                                    ),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
