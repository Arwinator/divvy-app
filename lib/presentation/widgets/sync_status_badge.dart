import 'package:flutter/material.dart';

/// Sync status badge widget
/// Shows "synced" or "pending" indicator for individual items
class SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  final bool compact;

  const SyncStatusBadge({
    super.key,
    required this.isSynced,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBadge(context);
    }

    return _buildFullBadge(context);
  }

  /// Build compact badge (icon only)
  Widget _buildCompactBadge(BuildContext context) {
    return Icon(
      isSynced ? Icons.check_circle : Icons.sync,
      size: 16,
      color: isSynced
          ? Theme.of(context).colorScheme.tertiary
          : Theme.of(context).colorScheme.secondary,
    );
  }

  /// Build full badge (icon + text)
  Widget _buildFullBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSynced
            ? Theme.of(context).colorScheme.tertiaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.check_circle : Icons.sync,
            size: 14,
            color: isSynced
                ? Theme.of(context).colorScheme.onTertiaryContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? 'Synced' : 'Pending',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSynced
                  ? Theme.of(context).colorScheme.onTertiaryContainer
                  : Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
