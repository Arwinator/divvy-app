import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/constants/app_constants.dart';
import 'package:divvy/presentation/views/payments/payment_views.dart';
import 'package:intl/intl.dart';

class BillDetailsScreen extends StatefulWidget {
  final int billId;

  const BillDetailsScreen({super.key, required this.billId});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load bills to ensure we have the latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillViewModel>().loadBills();
    });
  }

  void _navigateToPayment(ShareModel share, String billTitle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PaymentMethodScreen(share: share, billTitle: billTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Details')),
      body: Consumer<BillViewModel>(
        builder: (context, billViewModel, child) {
          // Loading state
          if (billViewModel.isLoading && billViewModel.bills.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Find the bill
          final bill = billViewModel.getBillById(widget.billId);

          if (bill == null) {
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
                    Text('Bill not found', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'This bill may have been deleted',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bill header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(bill.title, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: AppConstants.spacingSm),

                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppConstants.spacingXs),
                            Text(
                              DateFormat('MMMM d, yyyy').format(bill.billDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingMd),

                        // Total amount
                        Text(
                          'Total Amount',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '₱${bill.totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),

                        // Payment summary
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryItem(
                                label: 'Paid',
                                amount: bill.totalPaid,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingMd),
                            Expanded(
                              child: _SummaryItem(
                                label: 'Remaining',
                                amount: bill.totalRemaining,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingMd),

                        // Fully settled badge
                        if (bill.isFullySettled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingMd,
                              vertical: AppConstants.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: AppConstants.spacingSm),
                                Text(
                                  'Fully Settled',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),

                // Shares section
                Text('Shares', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppConstants.spacingSm),

                // Shares list
                ...bill.shares.map((share) {
                  final isCurrentUser = share.userId == currentUserId;
                  final isPaid = share.status == ShareStatus.paid;

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.spacingSm,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // User avatar
                              CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text(
                                  share.user.username[0].toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingMd),

                              // User info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          share.user.username,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        if (isCurrentUser) ...[
                                          const SizedBox(
                                            width: AppConstants.spacingXs,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'You',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '₱${share.amount.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status indicator
                              _ShareStatusBadge(
                                status: share.status,
                                theme: theme,
                              ),
                            ],
                          ),

                          // Pay button for current user's unpaid shares
                          if (isCurrentUser && !isPaid) ...[
                            const SizedBox(height: AppConstants.spacingMd),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _navigateToPayment(share, bill.title),
                                icon: const Icon(Icons.payment),
                                label: const Text('Pay Now'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ShareStatusBadge extends StatelessWidget {
  final ShareStatus status;
  final ThemeData theme;

  const _ShareStatusBadge({required this.status, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == ShareStatus.paid;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isPaid
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            size: 16,
            color: isPaid
                ? theme.colorScheme.onTertiaryContainer
                : theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'Paid' : 'Unpaid',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isPaid
                  ? theme.colorScheme.onTertiaryContainer
                  : theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
