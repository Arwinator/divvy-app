import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  int? _selectedGroupId;
  DateTime _selectedDate = DateTime.now();
  SplitType _splitType = SplitType.equal;
  final Map<int, TextEditingController> _customShareControllers = {};

  @override
  void initState() {
    super.initState();
    // Load groups when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupViewModel>().loadGroups();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (var controller in _customShareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onSplitTypeChanged(SplitType? value) {
    if (value != null) {
      setState(() {
        _splitType = value;
        context.read<BillViewModel>().setSplitType(value);
      });
    }
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a group')));
      return;
    }

    final billViewModel = context.read<BillViewModel>();
    final title = _titleController.text.trim();
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;

    bool success;

    if (_splitType == SplitType.equal) {
      success = await billViewModel.createBillWithEqualSplit(
        groupId: _selectedGroupId!,
        title: title,
        totalAmount: totalAmount,
        billDate: _selectedDate,
      );
    } else {
      // Custom split
      final groupViewModel = context.read<GroupViewModel>();
      final group = groupViewModel.groups.firstWhere(
        (g) => g.id == _selectedGroupId,
      );

      final shares = group.members.map((member) {
        final controller = _customShareControllers[member.id];
        final amount = double.tryParse(controller?.text ?? '0') ?? 0.0;
        return {'user_id': member.id, 'amount': amount};
      }).toList();

      success = await billViewModel.createBillWithCustomSplit(
        groupId: _selectedGroupId!,
        title: title,
        totalAmount: totalAmount,
        billDate: _selectedDate,
        shares: shares,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill created successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billViewModel.error ?? 'Failed to create bill'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Bill')),
      body: Consumer2<GroupViewModel, BillViewModel>(
        builder: (context, groupViewModel, billViewModel, child) {
          if (groupViewModel.isLoading && groupViewModel.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

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
                    Text(
                      'No groups available',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Create a group first before creating bills',
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Title',
                      hintText: 'e.g., Dinner at Restaurant',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Amount field
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                      hintText: '0.00',
                      prefixText: '₱ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Trigger rebuild to update equal split preview
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Date field
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Bill Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Group selection
                  DropdownButtonFormField<int>(
                    initialValue: _selectedGroupId,
                    decoration: const InputDecoration(labelText: 'Group'),
                    items: groupViewModel.groups.map((group) {
                      return DropdownMenuItem<int>(
                        value: group.id,
                        child: Text(group.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGroupId = value;
                        _customShareControllers.clear();
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a group';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Split type toggle
                  Text('Split Type', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppConstants.spacingSm),
                  SegmentedButton<SplitType>(
                    segments: const [
                      ButtonSegment<SplitType>(
                        value: SplitType.equal,
                        label: Text('Equal Split'),
                        icon: Icon(Icons.pie_chart_outline),
                      ),
                      ButtonSegment<SplitType>(
                        value: SplitType.custom,
                        label: Text('Custom Split'),
                        icon: Icon(Icons.edit_outlined),
                      ),
                    ],
                    selected: {_splitType},
                    onSelectionChanged: (Set<SplitType> newSelection) {
                      _onSplitTypeChanged(newSelection.first);
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Split preview/input
                  if (_selectedGroupId != null) ...[
                    if (_splitType == SplitType.equal)
                      _EqualSplitPreview(
                        group: groupViewModel.groups.firstWhere(
                          (g) => g.id == _selectedGroupId,
                        ),
                        totalAmount:
                            double.tryParse(_amountController.text) ?? 0.0,
                      )
                    else
                      _CustomSplitInput(
                        group: groupViewModel.groups.firstWhere(
                          (g) => g.id == _selectedGroupId,
                        ),
                        totalAmount:
                            double.tryParse(_amountController.text) ?? 0.0,
                        controllers: _customShareControllers,
                        onControllersChanged: () => setState(() {}),
                      ),
                  ],

                  const SizedBox(height: AppConstants.spacingLg),

                  // Create button
                  ElevatedButton(
                    onPressed: billViewModel.isLoading ? null : _createBill,
                    child: billViewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Bill'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EqualSplitPreview extends StatelessWidget {
  final GroupModel group;
  final double totalAmount;

  const _EqualSplitPreview({required this.group, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billViewModel = context.read<BillViewModel>();
    final shares = billViewModel.calculateEqualSplit(
      totalAmount,
      group.members.length,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split Preview', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppConstants.spacingSm),
            ...List.generate(group.members.length, (index) {
              final member = group.members[index];
              final amount = index < shares.length ? shares[index] : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingXs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(member.username, style: theme.textTheme.bodyMedium),
                    Text(
                      '₱${amount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CustomSplitInput extends StatefulWidget {
  final GroupModel group;
  final double totalAmount;
  final Map<int, TextEditingController> controllers;
  final VoidCallback onControllersChanged;

  const _CustomSplitInput({
    required this.group,
    required this.totalAmount,
    required this.controllers,
    required this.onControllersChanged,
  });

  @override
  State<_CustomSplitInput> createState() => _CustomSplitInputState();
}

class _CustomSplitInputState extends State<_CustomSplitInput> {
  @override
  void initState() {
    super.initState();
    // Initialize controllers for each member
    for (var member in widget.group.members) {
      if (!widget.controllers.containsKey(member.id)) {
        widget.controllers[member.id] = TextEditingController(text: '0.00');
      }
    }
  }

  double get _totalEntered {
    return widget.controllers.values.fold(0.0, (sum, controller) {
      return sum + (double.tryParse(controller.text) ?? 0.0);
    });
  }

  bool get _isValid {
    return (widget.totalAmount - _totalEntered).abs() < 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custom Split', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppConstants.spacingSm),
            ...widget.group.members.map((member) {
              final controller = widget.controllers[member.id]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        member.username,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          prefixText: '₱ ',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingSm,
                            vertical: AppConstants.spacingSm,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (value) {
                          widget.onControllersChanged();
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Entered:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₱${_totalEntered.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isValid
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            if (!_isValid) ...[
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                'Total must equal ₱${widget.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
