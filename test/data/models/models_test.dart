import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/data/models/user_model.dart';
import 'package:divvy/data/models/group_model.dart';
import 'package:divvy/data/models/bill_model.dart';
import 'package:divvy/data/models/share_model.dart';
import 'package:divvy/data/models/transaction_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates UserModel from JSON', () {
      final json = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'created_at': '2024-01-01T00:00:00.000000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.createdAt, DateTime.parse('2024-01-01T00:00:00.000000Z'));
    });

    test('toJson converts UserModel to JSON', () {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000000Z'),
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['username'], 'testuser');
      expect(json['email'], 'test@example.com');
      expect(json['created_at'], '2024-01-01T00:00:00.000Z');
    });

    test('fromMap creates UserModel from SQLite Map', () {
      final map = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromMap(map);

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('toMap converts UserModel to SQLite Map', () {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final map = user.toMap();

      expect(map['id'], 1);
      expect(map['username'], 'testuser');
      expect(map['email'], 'test@example.com');
      expect(map['created_at'], '2024-01-01T00:00:00.000Z');
    });

    test('JSON serialization round trip preserves data', () {
      final original = UserModel(
        id: 42,
        username: 'roundtrip',
        email: 'roundtrip@test.com',
        createdAt: DateTime.parse('2024-03-15T10:30:00.000Z'),
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.email, original.email);
      expect(restored.createdAt, original.createdAt);
    });

    test('SQLite serialization round trip preserves data', () {
      final original = UserModel(
        id: 42,
        username: 'roundtrip',
        email: 'roundtrip@test.com',
        createdAt: DateTime.parse('2024-03-15T10:30:00.000Z'),
      );

      final map = original.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.email, original.email);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('GroupModel', () {
    test('fromJson creates GroupModel from JSON', () {
      final json = {
        'id': 1,
        'name': 'Test Group',
        'creator_id': 1,
        'members': [
          {
            'id': 1,
            'username': 'user1',
            'email': 'user1@test.com',
            'created_at': '2024-01-01T00:00:00.000000Z',
          },
          {
            'id': 2,
            'username': 'user2',
            'email': 'user2@test.com',
            'created_at': '2024-01-01T00:00:00.000000Z',
          },
        ],
        'created_at': '2024-01-01T00:00:00.000000Z',
      };

      final group = GroupModel.fromJson(json);

      expect(group.id, 1);
      expect(group.name, 'Test Group');
      expect(group.creatorId, 1);
      expect(group.members.length, 2);
      expect(group.members[0].username, 'user1');
      expect(group.members[1].username, 'user2');
      expect(group.createdAt, DateTime.parse('2024-01-01T00:00:00.000000Z'));
    });

    test('toJson converts GroupModel to JSON', () {
      final group = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: [
          UserModel(
            id: 1,
            username: 'user1',
            email: 'user1@test.com',
            createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
          ),
        ],
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = group.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test Group');
      expect(json['creator_id'], 1);
      expect(json['members'], isA<List>());
      expect(json['members'].length, 1);
      expect(json['created_at'], '2024-01-01T00:00:00.000Z');
    });

    test('fromMap creates GroupModel from SQLite Map', () {
      final map = {
        'id': 1,
        'name': 'Test Group',
        'creator_id': 1,
        'created_at': '2024-01-01T00:00:00.000Z',
        'is_synced': 1,
      };

      final group = GroupModel.fromMap(map);

      expect(group.id, 1);
      expect(group.name, 'Test Group');
      expect(group.creatorId, 1);
      expect(group.members, isEmpty);
      expect(group.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(group.isSynced, true);
    });

    test('toMap converts GroupModel to SQLite Map', () {
      final group = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: [],
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        isSynced: false,
      );

      final map = group.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Test Group');
      expect(map['creator_id'], 1);
      expect(map['created_at'], '2024-01-01T00:00:00.000Z');
      expect(map['is_synced'], 0);
    });

    test('isSynced defaults to true', () {
      final group = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: [],
        createdAt: DateTime.now(),
      );

      expect(group.isSynced, true);
    });
  });

  group('ShareStatus enum', () {
    test('toJson converts enum to string', () {
      expect(ShareStatus.unpaid.toJson(), 'unpaid');
      expect(ShareStatus.paid.toJson(), 'paid');
    });

    test('fromJson parses valid status', () {
      expect(ShareStatus.fromJson('unpaid'), ShareStatus.unpaid);
      expect(ShareStatus.fromJson('paid'), ShareStatus.paid);
    });

    test('fromJson defaults to unpaid for invalid status', () {
      expect(ShareStatus.fromJson('invalid'), ShareStatus.unpaid);
      expect(ShareStatus.fromJson(''), ShareStatus.unpaid);
    });
  });

  group('ShareModel', () {
    test('fromJson creates ShareModel from JSON', () {
      final json = {
        'id': 1,
        'bill_id': 1,
        'user_id': 1,
        'amount': 500.0,
        'status': 'paid',
        'user': {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'created_at': '2024-01-01T00:00:00.000000Z',
        },
      };

      final share = ShareModel.fromJson(json);

      expect(share.id, 1);
      expect(share.billId, 1);
      expect(share.userId, 1);
      expect(share.amount, 500.0);
      expect(share.status, ShareStatus.paid);
      expect(share.user.username, 'testuser');
    });

    test('fromJson handles unpaid status', () {
      final json = {
        'id': 1,
        'bill_id': 1,
        'user_id': 1,
        'amount': 500.0,
        'status': 'unpaid',
        'user': {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'created_at': '2024-01-01T00:00:00.000000Z',
        },
      };

      final share = ShareModel.fromJson(json);

      expect(share.status, ShareStatus.unpaid);
    });

    test('toJson converts ShareModel to JSON', () {
      final share = ShareModel(
        id: 1,
        billId: 1,
        userId: 1,
        amount: 500.0,
        status: ShareStatus.paid,
        user: UserModel(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        ),
      );

      final json = share.toJson();

      expect(json['id'], 1);
      expect(json['bill_id'], 1);
      expect(json['user_id'], 1);
      expect(json['amount'], 500.0);
      expect(json['status'], 'paid');
      expect(json['user'], isA<Map>());
    });

    test('fromMap creates ShareModel from SQLite Map', () {
      final map = {
        'id': 1,
        'bill_id': 1,
        'user_id': 1,
        'amount': 500.0,
        'status': 'paid',
      };

      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      final share = ShareModel.fromMap(map, user);

      expect(share.id, 1);
      expect(share.billId, 1);
      expect(share.userId, 1);
      expect(share.amount, 500.0);
      expect(share.status, ShareStatus.paid);
      expect(share.user, user);
    });

    test('toMap converts ShareModel to SQLite Map', () {
      final share = ShareModel(
        id: 1,
        billId: 1,
        userId: 1,
        amount: 500.0,
        status: ShareStatus.unpaid,
        user: UserModel(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        ),
      );

      final map = share.toMap();

      expect(map['id'], 1);
      expect(map['bill_id'], 1);
      expect(map['user_id'], 1);
      expect(map['amount'], 500.0);
      expect(map['status'], 'unpaid');
      expect(map.containsKey('user'), false);
    });

    test('handles integer amount conversion to double', () {
      final json = {
        'id': 1,
        'bill_id': 1,
        'user_id': 1,
        'amount': 500,
        'status': 'paid',
        'user': {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'created_at': '2024-01-01T00:00:00.000000Z',
        },
      };

      final share = ShareModel.fromJson(json);

      expect(share.amount, 500.0);
      expect(share.amount, isA<double>());
    });
  });

  group('PaymentMethod enum', () {
    test('toJson converts enum to string', () {
      expect(PaymentMethod.gcash.toJson(), 'gcash');
      expect(PaymentMethod.paymaya.toJson(), 'paymaya');
    });

    test('fromJson parses valid payment method', () {
      expect(PaymentMethod.fromJson('gcash'), PaymentMethod.gcash);
      expect(PaymentMethod.fromJson('paymaya'), PaymentMethod.paymaya);
    });

    test('fromJson defaults to gcash for invalid method', () {
      expect(PaymentMethod.fromJson('invalid'), PaymentMethod.gcash);
      expect(PaymentMethod.fromJson(''), PaymentMethod.gcash);
    });
  });

  group('TransactionStatus enum', () {
    test('toJson converts enum to string', () {
      expect(TransactionStatus.pending.toJson(), 'pending');
      expect(TransactionStatus.paid.toJson(), 'paid');
      expect(TransactionStatus.failed.toJson(), 'failed');
    });

    test('fromJson parses valid status', () {
      expect(TransactionStatus.fromJson('pending'), TransactionStatus.pending);
      expect(TransactionStatus.fromJson('paid'), TransactionStatus.paid);
      expect(TransactionStatus.fromJson('failed'), TransactionStatus.failed);
    });

    test('fromJson defaults to pending for invalid status', () {
      expect(TransactionStatus.fromJson('invalid'), TransactionStatus.pending);
      expect(TransactionStatus.fromJson(''), TransactionStatus.pending);
    });
  });

  group('TransactionModel', () {
    test('fromJson creates TransactionModel from JSON', () {
      final json = {
        'id': 1,
        'share_id': 1,
        'user_id': 1,
        'amount': 500.0,
        'payment_method': 'gcash',
        'paymongo_transaction_id': 'pm_123',
        'status': 'paid',
        'paid_at': '2024-01-01T12:00:00.000000Z',
        'created_at': '2024-01-01T00:00:00.000000Z',
      };

      final transaction = TransactionModel.fromJson(json);

      expect(transaction.id, 1);
      expect(transaction.shareId, 1);
      expect(transaction.userId, 1);
      expect(transaction.amount, 500.0);
      expect(transaction.paymentMethod, PaymentMethod.gcash);
      expect(transaction.paymongoTransactionId, 'pm_123');
      expect(transaction.status, TransactionStatus.paid);
      expect(transaction.paidAt, DateTime.parse('2024-01-01T12:00:00.000000Z'));
      expect(
        transaction.createdAt,
        DateTime.parse('2024-01-01T00:00:00.000000Z'),
      );
    });

    test('fromJson handles null paidAt', () {
      final json = {
        'id': 1,
        'share_id': 1,
        'user_id': 1,
        'amount': 500.0,
        'payment_method': 'gcash',
        'paymongo_transaction_id': null,
        'status': 'pending',
        'paid_at': null,
        'created_at': '2024-01-01T00:00:00.000000Z',
      };

      final transaction = TransactionModel.fromJson(json);

      expect(transaction.paidAt, isNull);
      expect(transaction.paymongoTransactionId, isNull);
    });

    test('toJson converts TransactionModel to JSON', () {
      final transaction = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 500.0,
        paymentMethod: PaymentMethod.paymaya,
        paymongoTransactionId: 'pm_123',
        status: TransactionStatus.paid,
        paidAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = transaction.toJson();

      expect(json['id'], 1);
      expect(json['share_id'], 1);
      expect(json['user_id'], 1);
      expect(json['amount'], 500.0);
      expect(json['payment_method'], 'paymaya');
      expect(json['paymongo_transaction_id'], 'pm_123');
      expect(json['status'], 'paid');
      expect(json['paid_at'], '2024-01-01T12:00:00.000Z');
      expect(json['created_at'], '2024-01-01T00:00:00.000Z');
    });

    test('fromMap creates TransactionModel from SQLite Map', () {
      final map = {
        'id': 1,
        'share_id': 1,
        'user_id': 1,
        'amount': 500.0,
        'payment_method': 'gcash',
        'paymongo_transaction_id': 'pm_123',
        'status': 'paid',
        'paid_at': '2024-01-01T12:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final transaction = TransactionModel.fromMap(map);

      expect(transaction.id, 1);
      expect(transaction.shareId, 1);
      expect(transaction.userId, 1);
      expect(transaction.amount, 500.0);
      expect(transaction.paymentMethod, PaymentMethod.gcash);
      expect(transaction.status, TransactionStatus.paid);
    });

    test('toMap converts TransactionModel to SQLite Map', () {
      final transaction = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 500.0,
        paymentMethod: PaymentMethod.gcash,
        paymongoTransactionId: 'pm_123',
        status: TransactionStatus.failed,
        paidAt: null,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final map = transaction.toMap();

      expect(map['id'], 1);
      expect(map['share_id'], 1);
      expect(map['user_id'], 1);
      expect(map['amount'], 500.0);
      expect(map['payment_method'], 'gcash');
      expect(map['status'], 'failed');
      expect(map['paid_at'], isNull);
    });

    test('handles integer amount conversion to double', () {
      final json = {
        'id': 1,
        'share_id': 1,
        'user_id': 1,
        'amount': 500,
        'payment_method': 'gcash',
        'paymongo_transaction_id': null,
        'status': 'pending',
        'paid_at': null,
        'created_at': '2024-01-01T00:00:00.000000Z',
      };

      final transaction = TransactionModel.fromJson(json);

      expect(transaction.amount, 500.0);
      expect(transaction.amount, isA<double>());
    });
  });

  group('BillModel', () {
    test('fromJson creates BillModel from JSON', () {
      final json = {
        'id': 1,
        'group_id': 1,
        'creator_id': 1,
        'title': 'Dinner',
        'total_amount': 1500.0,
        'bill_date': '2024-01-01',
        'created_at': '2024-01-01T00:00:00.000000Z',
        'shares': [
          {
            'id': 1,
            'bill_id': 1,
            'user_id': 1,
            'amount': 500.0,
            'status': 'paid',
            'user': {
              'id': 1,
              'username': 'user1',
              'email': 'user1@test.com',
              'created_at': '2024-01-01T00:00:00.000000Z',
            },
          },
          {
            'id': 2,
            'bill_id': 1,
            'user_id': 2,
            'amount': 500.0,
            'status': 'unpaid',
            'user': {
              'id': 2,
              'username': 'user2',
              'email': 'user2@test.com',
              'created_at': '2024-01-01T00:00:00.000000Z',
            },
          },
        ],
      };

      final bill = BillModel.fromJson(json);

      expect(bill.id, 1);
      expect(bill.groupId, 1);
      expect(bill.creatorId, 1);
      expect(bill.title, 'Dinner');
      expect(bill.totalAmount, 1500.0);
      expect(bill.billDate, DateTime.parse('2024-01-01'));
      expect(bill.shares.length, 2);
    });

    test('toJson converts BillModel to JSON', () {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Dinner',
        totalAmount: 1500.0,
        billDate: DateTime.parse('2024-01-01'),
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        shares: [],
      );

      final json = bill.toJson();

      expect(json['id'], 1);
      expect(json['group_id'], 1);
      expect(json['creator_id'], 1);
      expect(json['title'], 'Dinner');
      expect(json['total_amount'], 1500.0);
      expect(json['bill_date'], '2024-01-01');
      expect(json['shares'], isA<List>());
    });

    test('fromMap creates BillModel from SQLite Map', () {
      final map = {
        'id': 1,
        'group_id': 1,
        'creator_id': 1,
        'title': 'Dinner',
        'total_amount': 1500.0,
        'bill_date': '2024-01-01',
        'created_at': '2024-01-01T00:00:00.000Z',
        'is_synced': 1,
      };

      final bill = BillModel.fromMap(map);

      expect(bill.id, 1);
      expect(bill.groupId, 1);
      expect(bill.creatorId, 1);
      expect(bill.title, 'Dinner');
      expect(bill.totalAmount, 1500.0);
      expect(bill.billDate, DateTime.parse('2024-01-01'));
      expect(bill.shares, isEmpty);
      expect(bill.isSynced, true);
    });

    test('toMap converts BillModel to SQLite Map', () {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Dinner',
        totalAmount: 1500.0,
        billDate: DateTime.parse('2024-01-01'),
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        shares: [],
        isSynced: false,
      );

      final map = bill.toMap();

      expect(map['id'], 1);
      expect(map['group_id'], 1);
      expect(map['creator_id'], 1);
      expect(map['title'], 'Dinner');
      expect(map['total_amount'], 1500.0);
      expect(map['bill_date'], '2024-01-01');
      expect(map['is_synced'], 0);
    });

    test('totalPaid calculates sum of paid shares', () {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Dinner',
        totalAmount: 1500.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [
          ShareModel(
            id: 1,
            billId: 1,
            userId: 1,
            amount: 500.0,
            status: ShareStatus.paid,
            user: UserModel(
              id: 1,
              username: 'user1',
              email: 'user1@test.com',
              createdAt: DateTime.now(),
            ),
          ),
          ShareModel(
            id: 2,
            billId: 1,
            userId: 2,
            amount: 500.0,
            status: ShareStatus.paid,
            user: UserModel(
              id: 2,
              username: 'user2',
              email: 'user2@test.com',
              createdAt: DateTime.now(),
            ),
          ),
          ShareModel(
            id: 3,
            billId: 1,
            userId: 3,
            amount: 500.0,
            status: ShareStatus.unpaid,
            user: UserModel(
              id: 3,
              username: 'user3',
              email: 'user3@test.com',
              createdAt: DateTime.now(),
            ),
          ),
        ],
      );

      expect(bill.totalPaid, 1000.0);
    });

    test('totalRemaining calculates unpaid amount', () {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Dinner',
        totalAmount: 1500.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [
          ShareModel(
            id: 1,
            billId: 1,
            userId: 1,
            amount: 500.0,
            status: ShareStatus.paid,
            user: UserModel(
              id: 1,
              username: 'user1',
              email: 'user1@test.com',
              createdAt: DateTime.now(),
            ),
          ),
          ShareModel(
            id: 2,
            billId: 1,
            userId: 2,
            amount: 1000.0,
            status: ShareStatus.unpaid,
            user: UserModel(
              id: 2,
              username: 'user2',
              email: 'user2@test.com',
              createdAt: DateTime.now(),
            ),
          ),
        ],
      );

      expect(bill.totalRemaining, 1000.0);
    });

    test('isFullySettled returns true when all shares paid', () {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Dinner',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [
          ShareModel(
            id: 1,
            billId: 1,
            userId: 1,
            amount: 500.0,
            status: ShareStatus.paid,
            user: UserModel(
              id: 1,
              username: 'user1',
              email: 'user1@test.com',
              createdAt: DateTime.now(),
            ),
          ),
          ShareModel(
            id: 2,
            billId: 1,
            userId: 2,
            amount: 500.0,
            status: ShareStatus.paid,
            user: UserModel(
              id: 2,
              username: 'user2',
              email: 'user2@test.com',
              createdAt: DateTime.now(),
            ),
          ),
        ],
      );

      expect(bill.isFullySettled, true);
    });

    test('isFullySettled returns false when shares unpaid', () {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Dinner',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [
          ShareModel(
            id: 1,
            billId: 1,
            userId: 1,
            amount: 500.0,
            status: ShareStatus.paid,
            user: UserModel(
              id: 1,
              username: 'user1',
              email: 'user1@test.com',
              createdAt: DateTime.now(),
            ),
          ),
          ShareModel(
            id: 2,
            billId: 1,
            userId: 2,
            amount: 500.0,
            status: ShareStatus.unpaid,
            user: UserModel(
              id: 2,
              username: 'user2',
              email: 'user2@test.com',
              createdAt: DateTime.now(),
            ),
          ),
        ],
      );

      expect(bill.isFullySettled, false);
    });

    test('handles integer amount conversion to double', () {
      final json = {
        'id': 1,
        'group_id': 1,
        'creator_id': 1,
        'title': 'Dinner',
        'total_amount': 1500,
        'bill_date': '2024-01-01',
        'created_at': '2024-01-01T00:00:00.000000Z',
        'shares': [],
      };

      final bill = BillModel.fromJson(json);

      expect(bill.totalAmount, 1500.0);
      expect(bill.totalAmount, isA<double>());
    });

    test('isSynced defaults to true', () {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Dinner',
        totalAmount: 1500.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
      );

      expect(bill.isSynced, true);
    });
  });
}
