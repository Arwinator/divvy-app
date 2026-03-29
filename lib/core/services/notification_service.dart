import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for managing Firebase Cloud Messaging (FCM) notifications
///
/// Handles:
/// - FCM token retrieval and management
/// - Device ID generation (Android ID or UUID)
/// - Foreground notification handling
/// - Background notification handling
/// - Notification tap handling and navigation
///

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _fcmToken;
  String? _deviceId;

  /// Callback for handling notification taps
  /// Parameters: (notificationType, resourceId)
  /// Example: ('bill', '123') navigates to bill with ID 123
  Function(String type, String id)? onNotificationTap;

  /// Initialize Firebase Messaging and request permissions
  Future<void> initialize() async {
    // Request notification permissions (iOS requires explicit permission)
    await _requestPermissions();

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print('FCM Token: $_fcmToken');
    }

    // Generate device ID
    _deviceId = await _generateDeviceId();
    if (kDebugMode) {
      print('Device ID: $_deviceId');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      if (kDebugMode) {
        print('FCM Token refreshed: $newToken');
      }
      // Token updates are handled by AuthViewModel during login/registration
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundNotification);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Request notification permissions (required for iOS)
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('Notification permission status: ${settings.authorizationStatus}');
    }
  }

  /// Generate unique device ID
  /// - Android: Uses Android ID
  /// - iOS: Uses identifierForVendor
  /// - Fallback: Generates UUID
  Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? _generateUUID();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device ID: $e');
      }
    }

    // Fallback to UUID
    return _generateUUID();
  }

  /// Generate a simple UUID (fallback)
  String _generateUUID() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    return 'device_${timestamp}_$random';
  }

  /// Handle foreground notifications (when app is open)
  void _handleForegroundNotification(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground notification received:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // TODO: Show in-app notification banner
    // For now, notifications will be handled by the system
  }

  /// Handle notification tap (when user taps notification)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped:');
      print('Data: ${message.data}');
    }

    // Extract navigation data from notification
    final type = message.data['type'] as String?;
    final id = message.data['id'] as String?;

    if (type != null && id != null && onNotificationTap != null) {
      onNotificationTap!(type, id);
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Get current device ID
  String? get deviceId => _deviceId;

  /// Dispose resources
  void dispose() {
    // Clean up if needed
  }
}

/// Background message handler (must be top-level function)
/// This handles notifications when app is terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background notification received:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }

  // Background notifications are handled by the system
  // Data is available when user taps the notification
}
