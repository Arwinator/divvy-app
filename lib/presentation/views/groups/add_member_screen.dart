import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/core/constants/app_constants.dart';

class AddMemberScreen extends StatefulWidget {
  final int groupId;

  const AddMemberScreen({super.key, required this.groupId});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendInvitation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final groupViewModel = context.read<GroupViewModel>();
    final success = await groupViewModel.sendInvitation(
      groupId: widget.groupId,
      identifier: _identifierController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invitation sent successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      // Clear the field for another invitation
      _identifierController.clear();
      // Clear any previous errors
      groupViewModel.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupViewModel = context.watch<GroupViewModel>();
    final group = groupViewModel.getGroupById(widget.groupId);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Group Name
                if (group != null) ...[
                  Text(
                    'Adding member to',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.name,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                ],

                // Description
                Text(
                  'Enter the email address or username of the person you want to add',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingXl),

                // Email/Username Field
                TextFormField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Username',
                    hintText: 'e.g., john@example.com or johndoe',
                    prefixIcon: Icon(Icons.search),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSendInvitation(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email or username is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Please enter at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Info Card
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            'The user will receive an invitation that they can accept or decline',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),

                // Error Message
                Consumer<GroupViewModel>(
                  builder: (context, groupViewModel, child) {
                    if (groupViewModel.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.spacingMd,
                        ),
                        child: Card(
                          color: theme.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.spacingMd,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: AppConstants.spacingSm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Failed to send invitation',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onErrorContainer,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        groupViewModel.error!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onErrorContainer,
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
                    return const SizedBox.shrink();
                  },
                ),

                // Send Invitation Button
                Consumer<GroupViewModel>(
                  builder: (context, groupViewModel, child) {
                    return ElevatedButton.icon(
                      onPressed: groupViewModel.isLoading
                          ? null
                          : _handleSendInvitation,
                      icon: groupViewModel.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        groupViewModel.isLoading
                            ? 'Sending...'
                            : 'Send Invitation',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
