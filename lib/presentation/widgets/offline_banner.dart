import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';

/// Offline banner widget that displays when the device is offline
/// Automatically shows/hides based on network connectivity
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncViewModel>(
      builder: (context, syncViewModel, child) {
        // Only show banner when offline
        if (syncViewModel.isOnline) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Theme.of(context).colorScheme.errorContainer,
          elevation: 4,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are offline',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
