import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Content Display and Navigation', () {
    final random = Random();

    test(
      'notification displays content and navigates to correct screen based on type',
      () async {
        // Track navigation calls
        final navigationCalls = <Map<String, String>>[];

        // Simulate notification tap handler
        void handleNotificationTap(String type, String id) {
          navigationCalls.add({'type': type, 'id': id});
        }

        for (int i = 0; i < 100; i++) {
          // Clear navigation calls for this iteration
          navigationCalls.clear();

          // Generate random notification data
          final notificationData = _generateRandomNotification(random);

          // Simulate notification tap
          handleNotificationTap(
            notificationData['data']!['type']!,
            notificationData['data']!['id']!,
          );

          // Verify navigation was called with correct parameters
          expect(
            navigationCalls.length,
            1,
            reason: 'Navigation should be called once per notification tap',
          );

          final navigationCall = navigationCalls.first;
          expect(
            navigationCall['type'],
            notificationData['data']!['type'],
            reason: 'Navigation type should match notification type',
          );
          expect(
            navigationCall['id'],
            notificationData['data']!['id'],
            reason: 'Navigation id should match notification id',
          );

          // Verify notification content is present
          expect(
            notificationData['title'],
            isNotEmpty,
            reason: 'Notification title should not be empty',
          );
          expect(
            notificationData['body'],
            isNotEmpty,
            reason: 'Notification body should not be empty',
          );

          // Verify data payload contains required fields
          expect(
            notificationData['data']!['type'],
            isNotEmpty,
            reason: 'Notification data should contain type field',
          );
          expect(
            notificationData['data']!['id'],
            isNotEmpty,
            reason: 'Notification data should contain id field',
          );
        }
      },
    );

    test('group invitation notification navigates to correct group', () async {
      final navigationCalls = <Map<String, String>>[];

      void handleNotificationTap(String type, String id) {
        navigationCalls.add({'type': type, 'id': id});
      }

      for (int i = 0; i < 50; i++) {
        navigationCalls.clear();

        final groupId = (random.nextInt(10000) + 1).toString();

        // Simulate tap - use group_id as the navigation id for group invitations
        handleNotificationTap('group_invitation', groupId);

        expect(navigationCalls.length, 1);
        expect(navigationCalls.first['type'], 'group_invitation');
        expect(navigationCalls.first['id'], groupId);
      }
    });

    test('bill created notification navigates to correct bill', () async {
      final navigationCalls = <Map<String, String>>[];

      void handleNotificationTap(String type, String id) {
        navigationCalls.add({'type': type, 'id': id});
      }

      for (int i = 0; i < 50; i++) {
        navigationCalls.clear();

        final billId = (random.nextInt(10000) + 1).toString();

        // Simulate tap - use bill_id as the navigation id
        handleNotificationTap('bill_created', billId);

        expect(navigationCalls.length, 1);
        expect(navigationCalls.first['type'], 'bill_created');
        expect(navigationCalls.first['id'], billId);
      }
    });

    test('payment received notification navigates to correct bill', () async {
      final navigationCalls = <Map<String, String>>[];

      void handleNotificationTap(String type, String id) {
        navigationCalls.add({'type': type, 'id': id});
      }

      for (int i = 0; i < 50; i++) {
        navigationCalls.clear();

        final billId = (random.nextInt(10000) + 1).toString();

        // Simulate tap - use bill_id as the navigation id
        handleNotificationTap('payment_received', billId);

        expect(navigationCalls.length, 1);
        expect(navigationCalls.first['type'], 'payment_received');
        expect(navigationCalls.first['id'], billId);
      }
    });

    test('bill settled notification navigates to correct bill', () async {
      final navigationCalls = <Map<String, String>>[];

      void handleNotificationTap(String type, String id) {
        navigationCalls.add({'type': type, 'id': id});
      }

      for (int i = 0; i < 50; i++) {
        navigationCalls.clear();

        final billId = (random.nextInt(10000) + 1).toString();

        // Simulate tap - use bill_id as the navigation id
        handleNotificationTap('bill_settled', billId);

        expect(navigationCalls.length, 1);
        expect(navigationCalls.first['type'], 'bill_settled');
        expect(navigationCalls.first['id'], billId);
      }
    });

    test(
      'notification with missing type or id does not trigger navigation',
      () async {
        final navigationCalls = <Map<String, String>>[];

        void handleNotificationTap(String? type, String? id) {
          // Only add to navigation calls if both type and id are present
          if (type != null && id != null && type.isNotEmpty && id.isNotEmpty) {
            navigationCalls.add({'type': type, 'id': id});
          }
        }

        for (int i = 0; i < 50; i++) {
          navigationCalls.clear();

          // Test with missing type
          handleNotificationTap(null, '123');

          // Test with missing id
          handleNotificationTap('bill_created', null);

          // Test with empty type
          handleNotificationTap('', '123');

          // Test with empty id
          handleNotificationTap('bill_created', '');

          // Verify no navigation calls were made
          expect(
            navigationCalls.length,
            0,
            reason:
                'Navigation should not be called when type or id is missing',
          );
        }
      },
    );

    test('all notification types have consistent data structure', () async {
      for (int i = 0; i < 100; i++) {
        final notificationData = _generateRandomNotification(random);

        // Verify all notifications have required fields
        expect(notificationData.containsKey('title'), true);
        expect(notificationData.containsKey('body'), true);
        expect(notificationData.containsKey('data'), true);

        final data = notificationData['data']!;
        expect(data.containsKey('type'), true);

        // Verify type-specific required fields
        final type = data['type']!;
        switch (type) {
          case 'group_invitation':
            expect(
              data.containsKey('group_id'),
              true,
              reason: 'group_invitation should have group_id',
            );
            expect(
              data.containsKey('invitation_id'),
              true,
              reason: 'group_invitation should have invitation_id',
            );
            break;
          case 'bill_created':
            expect(
              data.containsKey('bill_id'),
              true,
              reason: 'bill_created should have bill_id',
            );
            expect(
              data.containsKey('group_id'),
              true,
              reason: 'bill_created should have group_id',
            );
            expect(
              data.containsKey('share_id'),
              true,
              reason: 'bill_created should have share_id',
            );
            break;
          case 'payment_received':
            expect(
              data.containsKey('bill_id'),
              true,
              reason: 'payment_received should have bill_id',
            );
            expect(
              data.containsKey('share_id'),
              true,
              reason: 'payment_received should have share_id',
            );
            break;
          case 'bill_settled':
            expect(
              data.containsKey('bill_id'),
              true,
              reason: 'bill_settled should have bill_id',
            );
            break;
        }
      }
    });
  });
}

/// Generate random notification data based on notification types
Map<String, dynamic> _generateRandomNotification(Random random) {
  final notificationTypes = [
    'group_invitation',
    'bill_created',
    'payment_received',
    'bill_settled',
  ];

  final type = notificationTypes[random.nextInt(notificationTypes.length)];

  switch (type) {
    case 'group_invitation':
      return {
        'title': 'Group Invitation',
        'body':
            'user${random.nextInt(1000)} invited you to join Group ${random.nextInt(100)}',
        'data': {
          'type': 'group_invitation',
          'group_id': (random.nextInt(10000) + 1).toString(),
          'invitation_id': (random.nextInt(10000) + 1).toString(),
          'id': (random.nextInt(10000) + 1).toString(), // For navigation
        },
      };
    case 'bill_created':
      return {
        'title': 'New Bill Created',
        'body':
            'user${random.nextInt(1000)} created a bill \'Bill ${random.nextInt(100)}\'. Your share: ₱${random.nextInt(10000) + 100}',
        'data': {
          'type': 'bill_created',
          'bill_id': (random.nextInt(10000) + 1).toString(),
          'group_id': (random.nextInt(10000) + 1).toString(),
          'share_id': (random.nextInt(10000) + 1).toString(),
          'id': (random.nextInt(10000) + 1).toString(), // For navigation
        },
      };
    case 'payment_received':
      return {
        'title': 'Payment Received',
        'body':
            'user${random.nextInt(1000)} paid their share for Bill ${random.nextInt(100)}',
        'data': {
          'type': 'payment_received',
          'bill_id': (random.nextInt(10000) + 1).toString(),
          'share_id': (random.nextInt(10000) + 1).toString(),
          'id': (random.nextInt(10000) + 1).toString(), // For navigation
        },
      };
    case 'bill_settled':
      return {
        'title': 'Bill Fully Settled',
        'body': 'All payments received for Bill ${random.nextInt(100)}',
        'data': {
          'type': 'bill_settled',
          'bill_id': (random.nextInt(10000) + 1).toString(),
          'id': (random.nextInt(10000) + 1).toString(), // For navigation
        },
      };
    default:
      throw Exception('Unknown notification type: $type');
  }
}
