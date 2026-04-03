import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart';
import 'package:divvy/data/models/models.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late TestDatabaseHelper databaseHelper;
  late BillLocalDataSource dataSource;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await createTestDatabase();
    databaseHelper = TestDatabaseHelper(db);
    dataSource = BillLocalDataSource(databaseHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('BillLocalDataSource - Save Operations', () {
    test('saveBill inserts bill and shares into database', () async {
      final shares = [
        ShareModel(
          id: 1,
          billId: 1,
          userId: 1,
          amount: 500.0,
          status: ShareStatus.unpaid,
          user: UserModel(
            id: 1,
            username: 'user1',
            email: 'user1@example.com',
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
            email: 'user2@example.com',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Test Bill',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: shares,
        isSynced: true,
      );

      await dataSource.saveBill(bill);

      final bills = await databaseHelper.query('bills');
      expect(bills.length, 1);
      expect(bills[0]['title'], 'Test Bill');

      final savedShares = await databaseHelper.query('shares');
      expect(savedShares.length, 2);
    });

    test('saveBill replaces existing bill with same ID', () async {
      final bill1 = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Original Bill',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.saveBill(bill1);

      final bill2 = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Updated Bill',
        totalAmount: 2000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.saveBill(bill2);

      final bills = await databaseHelper.query('bills');
      expect(bills.length, 1);
      expect(bills[0]['title'], 'Updated Bill');
      expect(bills[0]['total_amount'], 2000.0);
    });
  });

  group('BillLocalDataSource - Get Operations', () {
    test('getBills returns all bills with shares', () async {
      for (int i = 1; i <= 3; i++) {
        await dataSource.saveBill(
          BillModel(
            id: i,
            groupId: 1,
            creatorId: 1,
            title: 'Bill $i',
            totalAmount: 1000.0 * i,
            billDate: DateTime.now(),
            createdAt: DateTime.now(),
            shares: [],
            isSynced: true,
          ),
        );
      }

      final bills = await dataSource.getBills();

      expect(bills.length, 3);
    });

    test('getBills returns empty list when no bills exist', () async {
      final bills = await dataSource.getBills();

      expect(bills, isEmpty);
    });

    test('getBills filters by groupId', () async {
      await dataSource.saveBill(
        BillModel(
          id: 1,
          groupId: 1,
          creatorId: 1,
          title: 'Group 1 Bill',
          totalAmount: 1000.0,
          billDate: DateTime.now(),
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      await dataSource.saveBill(
        BillModel(
          id: 2,
          groupId: 2,
          creatorId: 1,
          title: 'Group 2 Bill',
          totalAmount: 2000.0,
          billDate: DateTime.now(),
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      final bills = await dataSource.getBills(groupId: 1);

      expect(bills.length, 1);
      expect(bills[0].title, 'Group 1 Bill');
    });

    test('getBills filters by date range', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      await dataSource.saveBill(
        BillModel(
          id: 1,
          groupId: 1,
          creatorId: 1,
          title: 'Yesterday Bill',
          totalAmount: 1000.0,
          billDate: yesterday,
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      await dataSource.saveBill(
        BillModel(
          id: 2,
          groupId: 1,
          creatorId: 1,
          title: 'Today Bill',
          totalAmount: 2000.0,
          billDate: today,
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      await dataSource.saveBill(
        BillModel(
          id: 3,
          groupId: 1,
          creatorId: 1,
          title: 'Tomorrow Bill',
          totalAmount: 3000.0,
          billDate: tomorrow,
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      final bills = await dataSource.getBills(
        fromDate: today,
        toDate: tomorrow,
      );

      expect(bills.length, 2);
      expect(bills.any((b) => b.title == 'Today Bill'), isTrue);
      expect(bills.any((b) => b.title == 'Tomorrow Bill'), isTrue);
    });

    test('getBills combines groupId and date filters', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await dataSource.saveBill(
        BillModel(
          id: 1,
          groupId: 1,
          creatorId: 1,
          title: 'Group 1 Today',
          totalAmount: 1000.0,
          billDate: today,
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      await dataSource.saveBill(
        BillModel(
          id: 2,
          groupId: 1,
          creatorId: 1,
          title: 'Group 1 Yesterday',
          totalAmount: 2000.0,
          billDate: yesterday,
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      await dataSource.saveBill(
        BillModel(
          id: 3,
          groupId: 2,
          creatorId: 1,
          title: 'Group 2 Today',
          totalAmount: 3000.0,
          billDate: today,
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      );

      final bills = await dataSource.getBills(groupId: 1, fromDate: today);

      expect(bills.length, 1);
      expect(bills[0].title, 'Group 1 Today');
    });

    test('getBillById returns bill with shares when exists', () async {
      final shares = [
        ShareModel(
          id: 1,
          billId: 1,
          userId: 1,
          amount: 500.0,
          status: ShareStatus.paid,
          user: UserModel(
            id: 1,
            username: 'user1',
            email: 'user1@example.com',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Test Bill',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: shares,
        isSynced: true,
      );

      await dataSource.saveBill(bill);

      final retrieved = await dataSource.getBillById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 1);
      expect(retrieved.title, 'Test Bill');
      expect(retrieved.shares.length, 1);
      expect(retrieved.shares[0].status, ShareStatus.paid);
    });

    test('getBillById returns null when bill does not exist', () async {
      final retrieved = await dataSource.getBillById(999);

      expect(retrieved, isNull);
    });
  });

  group('BillLocalDataSource - Delete Operations', () {
    test('deleteBill removes bill from database', () async {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Test Bill',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.saveBill(bill);
      await dataSource.deleteBill(1);

      final bills = await databaseHelper.query('bills');
      expect(bills, isEmpty);
    });

    test('deleteBill does not affect other bills', () async {
      for (int i = 1; i <= 3; i++) {
        await dataSource.saveBill(
          BillModel(
            id: i,
            groupId: 1,
            creatorId: 1,
            title: 'Bill $i',
            totalAmount: 1000.0,
            billDate: DateTime.now(),
            createdAt: DateTime.now(),
            shares: [],
            isSynced: true,
          ),
        );
      }

      await dataSource.deleteBill(2);

      final bills = await databaseHelper.query('bills');
      expect(bills.length, 2);
    });
  });

  group('BillLocalDataSource - Upsert Operations', () {
    test('upsertBills inserts new bills', () async {
      final bills = [
        BillModel(
          id: 1,
          groupId: 1,
          creatorId: 1,
          title: 'Bill 1',
          totalAmount: 1000.0,
          billDate: DateTime.now(),
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
        BillModel(
          id: 2,
          groupId: 1,
          creatorId: 1,
          title: 'Bill 2',
          totalAmount: 2000.0,
          billDate: DateTime.now(),
          createdAt: DateTime.now(),
          shares: [],
          isSynced: true,
        ),
      ];

      await dataSource.upsertBills(bills);

      final savedBills = await databaseHelper.query('bills');
      expect(savedBills.length, 2);
    });

    test('upsertBills updates existing bills', () async {
      final bill1 = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Original Title',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.saveBill(bill1);

      final bill2 = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Updated Title',
        totalAmount: 2000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.upsertBills([bill2]);

      final bills = await databaseHelper.query('bills');
      expect(bills.length, 1);
      expect(bills[0]['title'], 'Updated Title');
    });

    test('upsertBills updates share status correctly', () async {
      final shares1 = [
        ShareModel(
          id: 1,
          billId: 1,
          userId: 1,
          amount: 500.0,
          status: ShareStatus.unpaid,
          user: UserModel(
            id: 1,
            username: 'user1',
            email: 'user1@example.com',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      final bill1 = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Test Bill',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: shares1,
        isSynced: true,
      );

      await dataSource.saveBill(bill1);

      final shares2 = [
        ShareModel(
          id: 1,
          billId: 1,
          userId: 1,
          amount: 500.0,
          status: ShareStatus.paid,
          user: UserModel(
            id: 1,
            username: 'user1',
            email: 'user1@example.com',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      final bill2 = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Test Bill',
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: shares2,
        isSynced: true,
      );

      await dataSource.upsertBills([bill2]);

      final retrieved = await dataSource.getBillById(1);
      expect(retrieved!.shares[0].status, ShareStatus.paid);
    });
  });

  group('BillLocalDataSource - Edge Cases', () {
    test('saveBill handles bill with no shares', () async {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Empty Bill',
        totalAmount: 0.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.saveBill(bill);

      final retrieved = await dataSource.getBillById(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.shares, isEmpty);
    });

    test('saveBill handles decimal amounts correctly', () async {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Decimal Bill',
        totalAmount: 123.45,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.saveBill(bill);

      final retrieved = await dataSource.getBillById(1);
      expect(retrieved!.totalAmount, 123.45);
    });

    test('saveBill handles special characters in title', () async {
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: "Bill with 'quotes' and \"double quotes\"",
        totalAmount: 1000.0,
        billDate: DateTime.now(),
        createdAt: DateTime.now(),
        shares: [],
        isSynced: true,
      );

      await dataSource.saveBill(bill);

      final retrieved = await dataSource.getBillById(1);
      expect(retrieved!.title, "Bill with 'quotes' and \"double quotes\"");
    });
  });
}
