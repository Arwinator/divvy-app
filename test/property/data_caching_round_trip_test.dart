import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/data/models/models.dart';

/// Property-Based Test: Data Caching Round Trip
///
/// This test validates that data fetched from the API (JSON) matches data
/// retrieved from SQLite cache after serialization/deserialization round trip.
///
/// Tests all model types: groups, bills, shares, transactions
/// Uses 100 iterations with random data to catch edge cases
void main() {
  group('Data Caching Round Trip', () {
    final random = Random();

    test('user model JSON to SQLite round trip preserves data', () {
      for (int i = 0; i < 100; i++) {
        // Generate random user data
        final originalUser = _generateRandomUser(random);

        // Simulate API response (JSON serialization)
        final json = originalUser.toJson();
        final fromJson = UserModel.fromJson(json);

        // Simulate SQLite storage (Map serialization)
        final map = fromJson.toMap();
        final fromMap = UserModel.fromMap(map);

        // Verify round trip integrity
        expect(
          fromMap.id,
          originalUser.id,
          reason: 'User ID should match after round trip',
        );
        expect(
          fromMap.username,
          originalUser.username,
          reason: 'Username should match after round trip',
        );
        expect(
          fromMap.email,
          originalUser.email,
          reason: 'Email should match after round trip',
        );
        expect(
          fromMap.createdAt.toIso8601String(),
          originalUser.createdAt.toIso8601String(),
          reason: 'Created date should match after round trip',
        );
      }
    });

    test('group model JSON to SQLite round trip preserves data', () {
      for (int i = 0; i < 100; i++) {
        // Generate random group data
        final originalGroup = _generateRandomGroup(random);

        // Simulate API response (JSON serialization)
        final json = originalGroup.toJson();
        final fromJson = GroupModel.fromJson(json);

        // Simulate SQLite storage (Map serialization)
        final map = fromJson.toMap();
        final fromMap = GroupModel.fromMap(map);

        // Verify round trip integrity
        expect(
          fromMap.id,
          originalGroup.id,
          reason: 'Group ID should match after round trip',
        );
        expect(
          fromMap.name,
          originalGroup.name,
          reason: 'Group name should match after round trip',
        );
        expect(
          fromMap.creatorId,
          originalGroup.creatorId,
          reason: 'Creator ID should match after round trip',
        );
        expect(
          fromMap.createdAt.toIso8601String(),
          originalGroup.createdAt.toIso8601String(),
          reason: 'Created date should match after round trip',
        );
        expect(
          fromMap.isSynced,
          fromJson.isSynced,
          reason: 'Sync status should match after round trip',
        );

        // Verify members (from JSON)
        expect(
          fromJson.members.length,
          originalGroup.members.length,
          reason: 'Member count should match after JSON deserialization',
        );
        for (int j = 0; j < fromJson.members.length; j++) {
          expect(fromJson.members[j].id, originalGroup.members[j].id);
          expect(
            fromJson.members[j].username,
            originalGroup.members[j].username,
          );
          expect(fromJson.members[j].email, originalGroup.members[j].email);
        }
      }
    });

    test('bill model JSON to SQLite round trip preserves data', () {
      for (int i = 0; i < 100; i++) {
        // Generate random bill data
        final originalBill = _generateRandomBill(random);

        // Simulate API response (JSON serialization)
        final json = originalBill.toJson();
        final fromJson = BillModel.fromJson(json);

        // Simulate SQLite storage (Map serialization)
        final map = fromJson.toMap();
        final fromMap = BillModel.fromMap(map);

        // Verify round trip integrity
        expect(
          fromMap.id,
          originalBill.id,
          reason: 'Bill ID should match after round trip',
        );
        expect(
          fromMap.groupId,
          originalBill.groupId,
          reason: 'Group ID should match after round trip',
        );
        expect(
          fromMap.creatorId,
          originalBill.creatorId,
          reason: 'Creator ID should match after round trip',
        );
        expect(
          fromMap.title,
          originalBill.title,
          reason: 'Title should match after round trip',
        );
        expect(
          fromMap.totalAmount,
          originalBill.totalAmount,
          reason: 'Total amount should match after round trip',
        );
        expect(
          fromMap.billDate.toIso8601String().split('T')[0],
          originalBill.billDate.toIso8601String().split('T')[0],
          reason: 'Bill date should match after round trip',
        );
        expect(
          fromMap.isSynced,
          fromJson.isSynced,
          reason: 'Sync status should match after round trip',
        );

        // Verify shares (from JSON)
        expect(
          fromJson.shares.length,
          originalBill.shares.length,
          reason: 'Share count should match after JSON deserialization',
        );
        for (int j = 0; j < fromJson.shares.length; j++) {
          expect(fromJson.shares[j].id, originalBill.shares[j].id);
          expect(fromJson.shares[j].billId, originalBill.shares[j].billId);
          expect(fromJson.shares[j].userId, originalBill.shares[j].userId);
          expect(fromJson.shares[j].amount, originalBill.shares[j].amount);
          expect(fromJson.shares[j].status, originalBill.shares[j].status);
        }
      }
    });

    test('share model JSON to SQLite round trip preserves data', () {
      for (int i = 0; i < 100; i++) {
        // Generate random share data
        final originalShare = _generateRandomShare(random);

        // Simulate API response (JSON serialization)
        final json = originalShare.toJson();
        final fromJson = ShareModel.fromJson(json);

        // Simulate SQLite storage (Map serialization)
        final map = fromJson.toMap();
        final fromMap = ShareModel.fromMap(map, fromJson.user);

        // Verify round trip integrity
        expect(
          fromMap.id,
          originalShare.id,
          reason: 'Share ID should match after round trip',
        );
        expect(
          fromMap.billId,
          originalShare.billId,
          reason: 'Bill ID should match after round trip',
        );
        expect(
          fromMap.userId,
          originalShare.userId,
          reason: 'User ID should match after round trip',
        );
        expect(
          fromMap.amount,
          originalShare.amount,
          reason: 'Amount should match after round trip',
        );
        expect(
          fromMap.status,
          originalShare.status,
          reason: 'Status should match after round trip',
        );

        // Verify user data
        expect(
          fromMap.user.id,
          originalShare.user.id,
          reason: 'User ID should match after round trip',
        );
        expect(
          fromMap.user.username,
          originalShare.user.username,
          reason: 'Username should match after round trip',
        );
        expect(
          fromMap.user.email,
          originalShare.user.email,
          reason: 'User email should match after round trip',
        );
      }
    });

    test('transaction model JSON to SQLite round trip preserves data', () {
      for (int i = 0; i < 100; i++) {
        // Generate random transaction data
        final originalTransaction = _generateRandomTransaction(random);

        // Simulate API response (JSON serialization)
        final json = originalTransaction.toJson();
        final fromJson = TransactionModel.fromJson(json);

        // Simulate SQLite storage (Map serialization)
        final map = fromJson.toMap();
        final fromMap = TransactionModel.fromMap(map);

        // Verify round trip integrity
        expect(
          fromMap.id,
          originalTransaction.id,
          reason: 'Transaction ID should match after round trip',
        );
        expect(
          fromMap.shareId,
          originalTransaction.shareId,
          reason: 'Share ID should match after round trip',
        );
        expect(
          fromMap.userId,
          originalTransaction.userId,
          reason: 'User ID should match after round trip',
        );
        expect(
          fromMap.amount,
          originalTransaction.amount,
          reason: 'Amount should match after round trip',
        );
        expect(
          fromMap.paymentMethod,
          originalTransaction.paymentMethod,
          reason: 'Payment method should match after round trip',
        );
        expect(
          fromMap.paymongoTransactionId,
          originalTransaction.paymongoTransactionId,
          reason: 'PayMongo transaction ID should match after round trip',
        );
        expect(
          fromMap.status,
          originalTransaction.status,
          reason: 'Status should match after round trip',
        );

        // Verify timestamps
        if (originalTransaction.paidAt != null) {
          expect(
            fromMap.paidAt?.toIso8601String(),
            originalTransaction.paidAt?.toIso8601String(),
            reason: 'Paid at timestamp should match after round trip',
          );
        } else {
          expect(
            fromMap.paidAt,
            isNull,
            reason: 'Paid at should be null when original is null',
          );
        }

        expect(
          fromMap.createdAt.toIso8601String(),
          originalTransaction.createdAt.toIso8601String(),
          reason: 'Created at timestamp should match after round trip',
        );
      }
    });

    test('edge case: special characters in strings survive round trip', () {
      final specialChars = [
        "Test's Group",
        'Group "with quotes"',
        'Group\nwith\nnewlines',
        'Group\twith\ttabs',
        'Group with émojis 🎉💰',
        'Group with unicode: 你好世界',
        'Group with backslash\\test',
      ];

      for (final name in specialChars) {
        final group = GroupModel(
          id: 1,
          name: name,
          creatorId: 1,
          members: [],
          createdAt: DateTime.now(),
        );

        final json = group.toJson();
        final fromJson = GroupModel.fromJson(json);
        final map = fromJson.toMap();
        final fromMap = GroupModel.fromMap(map);

        expect(
          fromMap.name,
          name,
          reason: 'Special characters should survive round trip: $name',
        );
      }
    });

    test('edge case: boundary values for amounts survive round trip', () {
      final amounts = [
        0.01, // Minimum valid amount
        0.99,
        1.00,
        999.99,
        9999.99,
        99999.99,
        0.001, // Sub-cent precision
        123.456789, // High precision
      ];

      for (final amount in amounts) {
        final transaction = TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: amount,
          paymentMethod: PaymentMethod.gcash,
          status: TransactionStatus.paid,
          createdAt: DateTime.now(),
        );

        final json = transaction.toJson();
        final fromJson = TransactionModel.fromJson(json);
        final map = fromJson.toMap();
        final fromMap = TransactionModel.fromMap(map);

        expect(
          fromMap.amount,
          amount,
          reason: 'Amount $amount should survive round trip',
        );
      }
    });

    test('edge case: all enum values survive round trip', () {
      // Test all ShareStatus values
      for (final status in ShareStatus.values) {
        final share = ShareModel(
          id: 1,
          billId: 1,
          userId: 1,
          amount: 100.0,
          status: status,
          user: _generateRandomUser(random),
        );

        final json = share.toJson();
        final fromJson = ShareModel.fromJson(json);
        final map = fromJson.toMap();
        final fromMap = ShareModel.fromMap(map, fromJson.user);

        expect(
          fromMap.status,
          status,
          reason: 'ShareStatus.$status should survive round trip',
        );
      }

      // Test all PaymentMethod values
      for (final method in PaymentMethod.values) {
        final transaction = TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 100.0,
          paymentMethod: method,
          status: TransactionStatus.paid,
          createdAt: DateTime.now(),
        );

        final json = transaction.toJson();
        final fromJson = TransactionModel.fromJson(json);
        final map = fromJson.toMap();
        final fromMap = TransactionModel.fromMap(map);

        expect(
          fromMap.paymentMethod,
          method,
          reason: 'PaymentMethod.$method should survive round trip',
        );
      }

      // Test all TransactionStatus values
      for (final status in TransactionStatus.values) {
        final transaction = TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 100.0,
          paymentMethod: PaymentMethod.gcash,
          status: status,
          createdAt: DateTime.now(),
        );

        final json = transaction.toJson();
        final fromJson = TransactionModel.fromJson(json);
        final map = fromJson.toMap();
        final fromMap = TransactionModel.fromMap(map);

        expect(
          fromMap.status,
          status,
          reason: 'TransactionStatus.$status should survive round trip',
        );
      }
    });

    test('edge case: null values survive round trip', () {
      // Transaction with null paidAt
      final transaction1 = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 100.0,
        paymentMethod: PaymentMethod.gcash,
        status: TransactionStatus.pending,
        paidAt: null,
        createdAt: DateTime.now(),
      );

      final json1 = transaction1.toJson();
      final fromJson1 = TransactionModel.fromJson(json1);
      final map1 = fromJson1.toMap();
      final fromMap1 = TransactionModel.fromMap(map1);

      expect(
        fromMap1.paidAt,
        isNull,
        reason: 'Null paidAt should survive round trip',
      );

      // Transaction with null paymongoTransactionId
      final transaction2 = TransactionModel(
        id: 2,
        shareId: 2,
        userId: 2,
        amount: 200.0,
        paymentMethod: PaymentMethod.paymaya,
        paymongoTransactionId: null,
        status: TransactionStatus.pending,
        createdAt: DateTime.now(),
      );

      final json2 = transaction2.toJson();
      final fromJson2 = TransactionModel.fromJson(json2);
      final map2 = fromJson2.toMap();
      final fromMap2 = TransactionModel.fromMap(map2);

      expect(
        fromMap2.paymongoTransactionId,
        isNull,
        reason: 'Null paymongoTransactionId should survive round trip',
      );
    });
  });
}

// Helper functions to generate random test data

UserModel _generateRandomUser(Random random) {
  return UserModel(
    id: random.nextInt(100000),
    username: 'user_${random.nextInt(10000)}',
    email: 'user${random.nextInt(10000)}@example.com',
    createdAt: _randomDateTime(random),
  );
}

GroupModel _generateRandomGroup(Random random) {
  final memberCount = random.nextInt(10) + 1;
  final members = List.generate(
    memberCount,
    (_) => _generateRandomUser(random),
  );

  return GroupModel(
    id: random.nextInt(100000),
    name: 'Group ${random.nextInt(10000)}',
    creatorId: members.first.id,
    members: members,
    createdAt: _randomDateTime(random),
    isSynced: random.nextBool(),
  );
}

BillModel _generateRandomBill(Random random) {
  final shareCount = random.nextInt(10) + 1;
  final shares = List.generate(shareCount, (_) => _generateRandomShare(random));
  final totalAmount = shares.fold(0.0, (sum, share) => sum + share.amount);

  return BillModel(
    id: random.nextInt(100000),
    groupId: random.nextInt(10000),
    creatorId: random.nextInt(10000),
    title: 'Bill ${random.nextInt(10000)}',
    totalAmount: totalAmount,
    billDate: _randomDate(random),
    createdAt: _randomDateTime(random),
    shares: shares,
    isSynced: random.nextBool(),
  );
}

ShareModel _generateRandomShare(Random random) {
  return ShareModel(
    id: random.nextInt(100000),
    billId: random.nextInt(10000),
    userId: random.nextInt(10000),
    amount: _randomAmount(random),
    status: random.nextBool() ? ShareStatus.paid : ShareStatus.unpaid,
    user: _generateRandomUser(random),
  );
}

TransactionModel _generateRandomTransaction(Random random) {
  final hasPaidAt = random.nextBool();
  final hasPaymongoId = random.nextBool();

  return TransactionModel(
    id: random.nextInt(100000),
    shareId: random.nextInt(10000),
    userId: random.nextInt(10000),
    amount: _randomAmount(random),
    paymentMethod: random.nextBool()
        ? PaymentMethod.gcash
        : PaymentMethod.paymaya,
    paymongoTransactionId: hasPaymongoId
        ? 'pay_${random.nextInt(1000000)}'
        : null,
    status: _randomTransactionStatus(random),
    paidAt: hasPaidAt ? _randomDateTime(random) : null,
    createdAt: _randomDateTime(random),
  );
}

double _randomAmount(Random random) {
  // Generate amounts between 0.01 and 10000.00
  return (random.nextDouble() * 10000 + 0.01).roundToDouble() / 100 * 100;
}

DateTime _randomDateTime(Random random) {
  final now = DateTime.now();
  final daysAgo = random.nextInt(365);
  return now.subtract(Duration(days: daysAgo));
}

DateTime _randomDate(Random random) {
  final now = DateTime.now();
  final daysAgo = random.nextInt(365);
  return DateTime(now.year, now.month, now.day - daysAgo);
}

TransactionStatus _randomTransactionStatus(Random random) {
  final statuses = TransactionStatus.values;
  return statuses[random.nextInt(statuses.length)];
}
