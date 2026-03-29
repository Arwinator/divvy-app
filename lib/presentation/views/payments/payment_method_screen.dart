import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/data/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

/// Payment method selection screen
/// Allows user to choose GCash or PayMaya for payment
class PaymentMethodScreen extends StatefulWidget {
  final ShareModel share;
  final String billTitle;

  const PaymentMethodScreen({
    super.key,
    required this.share,
    required this.billTitle,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Method')),
      body: Consumer<PaymentViewModel>(
        builder: (context, viewModel, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Share details card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Bill', widget.billTitle, theme),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Amount',
                            '₱${widget.share.amount.toStringAsFixed(2)}',
                            theme,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Payee',
                            widget.share.user.username,
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment method selection
                  Text(
                    'Choose Payment Method',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // GCash option
                  _buildPaymentMethodCard(
                    context: context,
                    method: 'gcash',
                    title: 'GCash',
                    description: 'Pay using your GCash wallet',
                    icon: Icons.account_balance_wallet,
                    color: colorScheme.primary,
                    isSelected: _selectedMethod == 'gcash',
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'gcash';
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // PayMaya option
                  _buildPaymentMethodCard(
                    context: context,
                    method: 'paymaya',
                    title: 'PayMaya',
                    description: 'Pay using your PayMaya account',
                    icon: Icons.credit_card,
                    color: colorScheme.secondary,
                    isSelected: _selectedMethod == 'paymaya',
                    onTap: () {
                      setState(() {
                        _selectedMethod = 'paymaya';
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Error message
                  if (viewModel.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              viewModel.error!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (viewModel.error != null) const SizedBox(height: 16),

                  // Proceed button
                  ElevatedButton(
                    onPressed: _selectedMethod == null || viewModel.isProcessing
                        ? null
                        : () => _handlePayment(context, viewModel),
                    child: viewModel.isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Proceed to Payment'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required String method,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment(
    BuildContext context,
    PaymentViewModel viewModel,
  ) async {
    if (_selectedMethod == null) return;

    // Clear any previous errors
    viewModel.clearError();

    // Capture context-dependent objects before async gap
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Initiate payment
    final success = await viewModel.initiatePayment(
      shareId: widget.share.id,
      paymentMethod: _selectedMethod!,
    );

    if (!mounted) return;

    if (success && viewModel.paymentUrl != null) {
      // Open payment URL in browser
      await _launchPaymentUrl(viewModel.paymentUrl!);

      // Show success message and navigate back
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Payment initiated. Complete payment in browser.'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear payment URL
        viewModel.clearPaymentUrl();

        // Navigate back
        navigator.pop();
      }
    }
  }

  Future<void> _launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not open payment page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
