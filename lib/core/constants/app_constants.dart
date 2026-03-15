import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Divvy';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF111827);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  // Status Colors
  static const Color paidColor = Color(0xFF10B981); // Green
  static const Color unpaidColor = Color(0xFFF59E0B); // Amber
  static const Color pendingColor = Color(0xFF6B7280); // Gray
  static const Color failedColor = Color(0xFFEF4444); // Red

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;

  // Border Radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 9999.0;

  // Font Sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;

  // Font Weights
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: fontSize3xl,
    fontWeight: fontWeightBold,
    color: textPrimaryColor,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: fontSize2xl,
    fontWeight: fontWeightBold,
    color: textPrimaryColor,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: fontSizeXl,
    fontWeight: fontWeightSemibold,
    color: textPrimaryColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: fontSizeLg,
    fontWeight: fontWeightNormal,
    color: textPrimaryColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: fontSizeMd,
    fontWeight: fontWeightNormal,
    color: textPrimaryColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSizeSm,
    fontWeight: fontWeightNormal,
    color: textSecondaryColor,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: fontSizeMd,
    fontWeight: fontWeightMedium,
    color: textPrimaryColor,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: fontSizeSm,
    fontWeight: fontWeightMedium,
    color: textPrimaryColor,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: fontSizeXs,
    fontWeight: fontWeightMedium,
    color: textSecondaryColor,
  );

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiLongTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  static const int maxBillTitleLength = 255;
  static const int maxGroupNameLength = 255;

  // Currency
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';
  static const int decimalPlaces = 2;

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String timeFormat = 'hh:mm a';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String offlineMessage =
      'You are offline. Some features may be unavailable.';
  static const String syncErrorMessage =
      'Failed to sync data. Will retry when online.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registerSuccessMessage = 'Registration successful!';
  static const String groupCreatedMessage = 'Group created successfully!';
  static const String billCreatedMessage = 'Bill created successfully!';
  static const String paymentInitiatedMessage =
      'Payment initiated. Complete payment in browser.';
  static const String invitationSentMessage = 'Invitation sent successfully!';
  static const String invitationAcceptedMessage = 'Invitation accepted!';
  static const String memberRemovedMessage = 'Member removed successfully!';
  static const String leftGroupMessage = 'You have left the group.';

  // Empty State Messages
  static const String noGroupsMessage =
      'No groups yet. Create your first group to get started!';
  static const String noBillsMessage =
      'No bills yet. Add a bill to split expenses.';
  static const String noTransactionsMessage =
      'No transactions yet. Your payment history will appear here.';
  static const String noInvitationsMessage = 'No pending invitations.';
  static const String noMembersMessage = 'No members in this group yet.';
  static const String noSharesMessage = 'No shares for this bill.';

  // Button Labels
  static const String createGroupButton = 'Create Group';
  static const String createBillButton = 'Create Bill';
  static const String payButton = 'Pay';
  static const String acceptButton = 'Accept';
  static const String declineButton = 'Decline';
  static const String removeButton = 'Remove';
  static const String leaveButton = 'Leave Group';
  static const String sendInvitationButton = 'Send Invitation';
  static const String loginButton = 'Login';
  static const String registerButton = 'Register';
  static const String logoutButton = 'Logout';
  static const String syncButton = 'Sync';
  static const String retryButton = 'Retry';
  static const String cancelButton = 'Cancel';
  static const String saveButton = 'Save';
  static const String submitButton = 'Submit';
}
