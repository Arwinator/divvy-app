import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';

/// Sync status indicator widget
/// Displays last sync timestamp, sync animation, and pending operations count
/// Tap to trigger manual sync
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncViewModel>(
      builder: (context, syncViewModel, child) {
        return InkWell(
          onTap: syncViewModel.isOnline && !syncViewModel.isSyncing
              ? () => _handleSyncTap(context, syncViewModel)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sync icon with animation
                _buildSyncIcon(context, syncViewModel),
                const SizedBox(width: 8),
                // Last sync timestamp
                Text(
                  syncViewModel.getTimeSinceLastSync(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                // Pending operations badge
                if (syncViewModel.hasPendingOperations) ...[
                  const SizedBox(width: 8),
                  _buildPendingBadge(context, syncViewModel),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build sync icon with animation when syncing
  Widget _buildSyncIcon(BuildContext context, SyncViewModel syncViewModel) {
    if (syncViewModel.isSyncing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Icon(
      Icons.sync,
      size: 16,
      color: syncViewModel.isOnline
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  /// Build pending operations count badge
  Widget _buildPendingBadge(BuildContext context, SyncViewModel syncViewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${syncViewModel.pendingOperationsCount}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Handle sync tap - trigger manual sync
  Future<void> _handleSyncTap(
    BuildContext context,
    SyncViewModel syncViewModel,
  ) async {
    final success = await syncViewModel.triggerSync();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sync completed successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sync failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
