import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  int? _selectedGroupId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionViewModel>().loadTransactions();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<TransactionViewModel>().loadTransactions(
      groupId: _selectedGroupId,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  Future<void> _showFilterDialog() async {
    final groupViewModel = context.read<GroupViewModel>();
    await groupViewModel.loadGroups();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        groups: groupViewModel.groups,
        selectedGroupId: _selectedGroupId,
        fromDate: _fromDate,
        toDate: _toDate,
        onApply: (groupId, fromDate, toDate) {
          setState(() {
            _selectedGroupId = groupId;
            _fromDate = fromDate;
            _toDate = toDate;
          });
          _handleRefresh();
        },
        onClear: () {
          setState(() {
            _selectedGroupId = null;
            _fromDate = null;
            _toDate = null;
          });
          context.read<TransactionViewModel>().clearFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: Icon(
              _selectedGroupId != null || _fromDate != null || _toDate != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filter transactions',
          ),
        ],
      ),
      body: Consumer<TransactionViewModel>(
        builder: (context, transactionViewModel, child) {
          if (transactionViewModel.isLoading &&
              transactionViewModel.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactionViewModel.error != null &&
              transactionViewModel.transactions.isEmpty) {
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
                      'Failed to load transactions',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      transactionViewModel.error!,
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

          if (transactionViewModel.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Your payment history will appear here after you make payments',
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

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Column(
              children: [
                _SummaryCard(
                  totalPaid: transactionViewModel.totalPaid,
                  totalOwed: transactionViewModel.totalOwed,
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    itemCount: transactionViewModel.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction =
                          transactionViewModel.transactions[index];
                      return _TransactionCard(transaction: transaction);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalPaid;
  final double totalOwed;

  const _SummaryCard({required this.totalPaid, required this.totalOwed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(AppConstants.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(
                        'Total Paid',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${totalPaid.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: AppConstants.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pending,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text(
                        'Total Owed',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${totalOwed.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₱${transaction.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(transaction.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: transaction.status),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                _PaymentMethodBadge(paymentMethod: transaction.paymentMethod),
                if (transaction.paymongoTransactionId != null) ...[
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      'ID: ${transaction.paymongoTransactionId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (transaction.paidAt != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid on ${DateFormat('MMM d, yyyy').format(transaction.paidAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case TransactionStatus.paid:
        backgroundColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        icon = Icons.check_circle;
        label = 'Paid';
        break;
      case TransactionStatus.pending:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        icon = Icons.pending;
        label = 'Pending';
        break;
      case TransactionStatus.failed:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        icon = Icons.error;
        label = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  final PaymentMethod paymentMethod;

  const _PaymentMethodBadge({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String label;
    Color backgroundColor;
    Color textColor;

    switch (paymentMethod) {
      case PaymentMethod.gcash:
        label = 'GCash';
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case PaymentMethod.paymaya:
        label = 'PayMaya';
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final List<GroupModel> groups;
  final int? selectedGroupId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(int?, DateTime?, DateTime?) onApply;
  final VoidCallback onClear;

  const _FilterDialog({
    required this.groups,
    required this.selectedGroupId,
    required this.fromDate,
    required this.toDate,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late int? _selectedGroupId;
  late DateTime? _fromDate;
  late DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.selectedGroupId;
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedGroupId = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return AlertDialog(
      title: const Text('Filter Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spacingSm),
            DropdownButtonFormField<int?>(
              initialValue: _selectedGroupId,
              decoration: const InputDecoration(
                hintText: 'All groups',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All groups'),
                ),
                ...widget.groups.map((group) {
                  return DropdownMenuItem<int?>(
                    value: group.id,
                    child: Text(group.name),
                  );
                }),
              ],
              onChanged: (initialValue) {
                setState(() => _selectedGroupId = initialValue);
              },
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text('Date Range', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectFromDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _fromDate != null
                          ? dateFormat.format(_fromDate!)
                          : 'From',
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectToDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _toDate != null ? dateFormat.format(_toDate!) : 'To',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _clearFilters();
            widget.onClear();
            Navigator.of(context).pop();
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedGroupId, _fromDate, _toDate);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
