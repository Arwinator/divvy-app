import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/presentation/widgets/widgets.dart';
import 'package:divvy/core/constants/app_constants.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load groups when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupViewModel>().loadGroups();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<GroupViewModel>().loadGroups();
  }

  void _navigateToCreateGroup() {
    Navigator.of(context).pushNamed('/groups/create');
  }

  void _navigateToGroupDetails(int groupId) {
    Navigator.of(context).pushNamed('/groups/details', arguments: groupId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: Consumer<GroupViewModel>(
        builder: (context, groupViewModel, child) {
          // Loading state
          if (groupViewModel.isLoading && groupViewModel.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (groupViewModel.error != null && groupViewModel.groups.isEmpty) {
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
                      'Failed to load groups',
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
          if (groupViewModel.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text('No groups yet', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Create your first group to start splitting bills with friends',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    ElevatedButton.icon(
                      onPressed: _navigateToCreateGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Group'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Groups list
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              itemCount: groupViewModel.groups.length,
              itemBuilder: (context, index) {
                final group = groupViewModel.groups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMd,
                      vertical: AppConstants.spacingSm,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.group,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        SyncStatusBadge(
                          isSynced: group.isSynced,
                          compact: true,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${group.members.length} ${group.members.length == 1 ? 'member' : 'members'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => _navigateToGroupDetails(group.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateGroup,
        child: const Icon(Icons.add),
      ),
    );
  }
}
