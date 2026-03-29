import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/presentation/widgets/widgets.dart';
import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  int? _selectedGroupId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    // Load bills when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillViewModel>().loadBills();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<BillViewModel>().loadBills(
      groupId: _selectedGroupId,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  void _navigateToCreateBill() {
    Navigator.of(context).pushNamed('/bills/create');
  }

  void _navigateToBillDetails(int billId) {
    Navigator.of(context).pushNamed('/bills/details', arguments: billId);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: Icon(
              _selectedGroupId != null || _fromDate != null || _toDate != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filter bills',
          ),
        ],
      ),
      body: Consumer<BillViewModel>(
        builder: (context, billViewModel, child) {
          // Loading state
          if (billViewModel.isLoading && billViewModel.bills.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (billViewModel.error != null && billViewModel.bills.isEmpty) {
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
                      'Failed to load bills',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      billViewModel.error!,
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
          if (billViewModel.bills.isEmpty) {
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
                    Text('No bills yet', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Create your first bill to start tracking expenses',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    ElevatedButton.icon(
                      onPressed: _navigateToCreateBill,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Bill'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Bills list
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              itemCount: billViewModel.bills.length,
              itemBuilder: (context, index) {
                final bill = billViewModel.bills[index];
                return _BillCard(
                  bill: bill,
                  onTap: () => _navigateToBillDetails(bill.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateBill,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback onTap;

  const _BillCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            bill.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        SyncStatusBadge(isSynced: bill.isSynced, compact: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Text(
                    dateFormat.format(bill.billDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),

              // Total amount
              Text(
                '₱${bill.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),

              // Payment status
              Row(
                children: [
                  Expanded(
                    child: _PaymentStatusIndicator(
                      label: 'Paid',
                      amount: bill.totalPaid,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _PaymentStatusIndicator(
                      label: 'Remaining',
                      amount: bill.totalRemaining,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),

              // Fully settled badge
              if (bill.isFullySettled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fully Settled',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentStatusIndicator extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _PaymentStatusIndicator({
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
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final List<GroupModel> groups;
  final int? selectedGroupId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(int?, DateTime?, DateTime?) onApply;

  const _FilterDialog({
    required this.groups,
    required this.selectedGroupId,
    required this.fromDate,
    required this.toDate,
    required this.onApply,
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
      title: const Text('Filter Bills'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group filter
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
              onChanged: (value) {
                setState(() => _selectedGroupId = value);
              },
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Date range filter
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
        TextButton(onPressed: _clearFilters, child: const Text('Clear')),
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
