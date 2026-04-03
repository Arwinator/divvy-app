import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart';
import 'package:divvy/data/models/models.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late TestDatabaseHelper databaseHelper;
  late TransactionLocalDataSource dataSource;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await createTestDatabase();
    databaseHelper = TestDatabaseHelper(db);
    dataSource = TransactionLocalDataSource(databaseHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionLocalDataSource - Save Operations', () {
    test('saveTransaction inserts transaction into database', () async {
      final transaction = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 500.0,
        paymentMethod: PaymentMethod.gcash,
        paymongoTransactionId: 'pm_test_123',
        status: TransactionStatus.paid,
        paidAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await dataSource.saveTransaction(transaction);

      final transactions = await databaseHelper.query('transactions');
      expect(transactions.length, 1);
      expect(transactions[0]['amount'], 500.0);
      expect(transactions[0]['payment_method'], 'gcash');
      expect(transactions[0]['status'], 'paid');
    });

    test(
      'saveTransaction replaces existing transaction with same ID',
      () async {
        final transaction1 = TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: null,
          status: TransactionStatus.pending,
          paidAt: null,
          createdAt: DateTime.now(),
        );

        await dataSource.saveTransaction(transaction1);

        final transaction2 = TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_123',
          status: TransactionStatus.paid,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await dataSource.saveTransaction(transaction2);

        final transactions = await databaseHelper.query('transactions');
        expect(transactions.length, 1);
        expect(transactions[0]['status'], 'paid');
        expect(transactions[0]['paymongo_transaction_id'], 'pm_test_123');
      },
    );

    test(
      'saveTransaction handles null paidAt and paymongoTransactionId',
      () async {
        final transaction = TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.paymaya,
          paymongoTransactionId: null,
          status: TransactionStatus.pending,
          paidAt: null,
          createdAt: DateTime.now(),
        );

        await dataSource.saveTransaction(transaction);

        final transactions = await databaseHelper.query('transactions');
        expect(transactions[0]['paid_at'], isNull);
        expect(transactions[0]['paymongo_transaction_id'], isNull);
      },
    );
  });

  group('TransactionLocalDataSource - Get Operations', () {
    test('getTransactions returns all transactions', () async {
      for (int i = 1; i <= 3; i++) {
        await dataSource.saveTransaction(
          TransactionModel(
            id: i,
            shareId: i,
            userId: 1,
            amount: 500.0 * i,
            paymentMethod: PaymentMethod.gcash,
            paymongoTransactionId: 'pm_test_$i',
            status: TransactionStatus.paid,
            paidAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
      }

      final transactions = await dataSource.getTransactions();

      expect(transactions.length, 3);
    });

    test(
      'getTransactions returns empty list when no transactions exist',
      () async {
        final transactions = await dataSource.getTransactions();

        expect(transactions, isEmpty);
      },
    );

    test('getTransactions filters by date range', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      await dataSource.saveTransaction(
        TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_1',
          status: TransactionStatus.paid,
          paidAt: yesterday,
          createdAt: yesterday,
        ),
      );

      await dataSource.saveTransaction(
        TransactionModel(
          id: 2,
          shareId: 2,
          userId: 1,
          amount: 600.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_2',
          status: TransactionStatus.paid,
          paidAt: today,
          createdAt: today,
        ),
      );

      await dataSource.saveTransaction(
        TransactionModel(
          id: 3,
          shareId: 3,
          userId: 1,
          amount: 700.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_3',
          status: TransactionStatus.paid,
          paidAt: tomorrow,
          createdAt: tomorrow,
        ),
      );

      final transactions = await dataSource.getTransactions(
        fromDate: today,
        toDate: tomorrow,
      );

      expect(transactions.length, 2);
      expect(transactions.any((t) => t.id == 2), isTrue);
      expect(transactions.any((t) => t.id == 3), isTrue);
    });

    test('getTransactions parses payment methods correctly', () async {
      await dataSource.saveTransaction(
        TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_1',
          status: TransactionStatus.paid,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      await dataSource.saveTransaction(
        TransactionModel(
          id: 2,
          shareId: 2,
          userId: 1,
          amount: 600.0,
          paymentMethod: PaymentMethod.paymaya,
          paymongoTransactionId: 'pm_test_2',
          status: TransactionStatus.paid,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      final transactions = await dataSource.getTransactions();

      expect(transactions[1].paymentMethod, PaymentMethod.gcash);
      expect(transactions[0].paymentMethod, PaymentMethod.paymaya);
    });

    test('getTransactions parses transaction statuses correctly', () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 2));
      final latest = now.add(const Duration(hours: 1));

      await dataSource.saveTransaction(
        TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: null,
          status: TransactionStatus.pending,
          paidAt: null,
          createdAt: earlier,
        ),
      );

      await dataSource.saveTransaction(
        TransactionModel(
          id: 2,
          shareId: 2,
          userId: 1,
          amount: 600.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_2',
          status: TransactionStatus.paid,
          paidAt: now,
          createdAt: now,
        ),
      );

      await dataSource.saveTransaction(
        TransactionModel(
          id: 3,
          shareId: 3,
          userId: 1,
          amount: 700.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: null,
          status: TransactionStatus.failed,
          paidAt: null,
          createdAt: latest,
        ),
      );

      final transactions = await dataSource.getTransactions();

      expect(transactions[0].status, TransactionStatus.failed);
      expect(transactions[1].status, TransactionStatus.paid);
      expect(transactions[2].status, TransactionStatus.pending);
    });
  });

  group('TransactionLocalDataSource - Upsert Operations', () {
    test('upsertTransactions inserts new transactions', () async {
      final transactions = [
        TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_1',
          status: TransactionStatus.paid,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        TransactionModel(
          id: 2,
          shareId: 2,
          userId: 1,
          amount: 600.0,
          paymentMethod: PaymentMethod.paymaya,
          paymongoTransactionId: 'pm_test_2',
          status: TransactionStatus.paid,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      await dataSource.upsertTransactions(transactions);

      final savedTransactions = await databaseHelper.query('transactions');
      expect(savedTransactions.length, 2);
    });

    test('upsertTransactions updates existing transactions', () async {
      final transaction1 = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 500.0,
        paymentMethod: PaymentMethod.gcash,
        paymongoTransactionId: null,
        status: TransactionStatus.pending,
        paidAt: null,
        createdAt: DateTime.now(),
      );

      await dataSource.saveTransaction(transaction1);

      final transaction2 = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 500.0,
        paymentMethod: PaymentMethod.gcash,
        paymongoTransactionId: 'pm_test_123',
        status: TransactionStatus.paid,
        paidAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await dataSource.upsertTransactions([transaction2]);

      final transactions = await databaseHelper.query('transactions');
      expect(transactions.length, 1);
      expect(transactions[0]['status'], 'paid');
      expect(transactions[0]['paymongo_transaction_id'], 'pm_test_123');
    });

    test('upsertTransactions handles mixed insert and update', () async {
      final transaction1 = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 500.0,
        paymentMethod: PaymentMethod.gcash,
        paymongoTransactionId: 'pm_test_1',
        status: TransactionStatus.paid,
        paidAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await dataSource.saveTransaction(transaction1);

      final transactions = [
        TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 500.0,
          paymentMethod: PaymentMethod.gcash,
          paymongoTransactionId: 'pm_test_1_updated',
          status: TransactionStatus.paid,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        TransactionModel(
          id: 2,
          shareId: 2,
          userId: 1,
          amount: 600.0,
          paymentMethod: PaymentMethod.paymaya,
          paymongoTransactionId: 'pm_test_2',
          status: TransactionStatus.paid,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      await dataSource.upsertTransactions(transactions);

      final savedTransactions = await databaseHelper.query('transactions');
      expect(savedTransactions.length, 2);
      expect(
        savedTransactions.firstWhere(
          (t) => t['id'] == 1,
        )['paymongo_transaction_id'],
        'pm_test_1_updated',
      );
    });
  });

  group('TransactionLocalDataSource - Edge Cases', () {
    test('saveTransaction handles decimal amounts correctly', () async {
      final transaction = TransactionModel(
        id: 1,
        shareId: 1,
        userId: 1,
        amount: 123.45,
        paymentMethod: PaymentMethod.gcash,
        paymongoTransactionId: 'pm_test_123',
        status: TransactionStatus.paid,
        paidAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await dataSource.saveTransaction(transaction);

      final transactions = await dataSource.getTransactions();
      expect(transactions[0].amount, 123.45);
    });

    test(
      'getTransactions returns transactions ordered by creation date',
      () async {
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(hours: 2));
        final latest = now.add(const Duration(hours: 1));

        await dataSource.saveTransaction(
          TransactionModel(
            id: 1,
            shareId: 1,
            userId: 1,
            amount: 500.0,
            paymentMethod: PaymentMethod.gcash,
            paymongoTransactionId: 'pm_test_1',
            status: TransactionStatus.paid,
            paidAt: now,
            createdAt: now,
          ),
        );

        await dataSource.saveTransaction(
          TransactionModel(
            id: 2,
            shareId: 2,
            userId: 1,
            amount: 600.0,
            paymentMethod: PaymentMethod.gcash,
            paymongoTransactionId: 'pm_test_2',
            status: TransactionStatus.paid,
            paidAt: earlier,
            createdAt: earlier,
          ),
        );

        await dataSource.saveTransaction(
          TransactionModel(
            id: 3,
            shareId: 3,
            userId: 1,
            amount: 700.0,
            paymentMethod: PaymentMethod.gcash,
            paymongoTransactionId: 'pm_test_3',
            status: TransactionStatus.paid,
            paidAt: latest,
            createdAt: latest,
          ),
        );

        final transactions = await dataSource.getTransactions();

        expect(transactions[0].id, 3);
        expect(transactions[1].id, 1);
        expect(transactions[2].id, 2);
      },
    );
  });
}
