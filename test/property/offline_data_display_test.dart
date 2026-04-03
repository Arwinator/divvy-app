import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';
import 'package:divvy/data/models/models.dart';

import 'offline_data_display_test.mocks.dart';

@GenerateMocks([
  remote.GroupRemoteDataSource,
  remote.BillRemoteDataSource,
  remote.TransactionRemoteDataSource,
  local.GroupLocalDataSource,
  local.BillLocalDataSource,
  local.TransactionLocalDataSource,
  local.SyncQueueLocalDataSource,
  NetworkInfo,
])
void main() {
  group('Offline Data Display from Cache', () {
    late MockGroupRemoteDataSource mockGroupRemote;
    late MockBillRemoteDataSource mockBillRemote;
    late MockTransactionRemoteDataSource mockTransactionRemote;
    late MockGroupLocalDataSource mockGroupLocal;
    late MockBillLocalDataSource mockBillLocal;
    late MockTransactionLocalDataSource mockTransactionLocal;
    late MockSyncQueueLocalDataSource mockSyncQueue;
    late MockNetworkInfo mockNetworkInfo;

    late GroupRepository groupRepository;
    late BillRepository billRepository;
    late TransactionRepository transactionRepository;

    final random = Random();

    setUp(() {
      mockGroupRemote = MockGroupRemoteDataSource();
      mockBillRemote = MockBillRemoteDataSource();
      mockTransactionRemote = MockTransactionRemoteDataSource();
      mockGroupLocal = MockGroupLocalDataSource();
      mockBillLocal = MockBillLocalDataSource();
      mockTransactionLocal = MockTransactionLocalDataSource();
      mockSyncQueue = MockSyncQueueLocalDataSource();
      mockNetworkInfo = MockNetworkInfo();

      groupRepository = GroupRepository(
        remoteDataSource: mockGroupRemote,
        localDataSource: mockGroupLocal,
        syncQueueDataSource: mockSyncQueue,
        networkInfo: mockNetworkInfo,
      );

      billRepository = BillRepository(
        remoteDataSource: mockBillRemote,
        localDataSource: mockBillLocal,
        syncQueueDataSource: mockSyncQueue,
        networkInfo: mockNetworkInfo,
      );

      transactionRepository = TransactionRepository(
        remoteDataSource: mockTransactionRemote,
        localDataSource: mockTransactionLocal,
        networkInfo: mockNetworkInfo,
      );
    });

    test(
      'when offline, getGroups returns data from local cache without calling remote',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random cached groups
          final cachedGroups = _generateRandomGroups(random);

          // Mock offline connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Mock local data source returning cached groups
          when(
            mockGroupLocal.getGroups(),
          ).thenAnswer((_) async => cachedGroups);

          // Execute repository method
          final result = await groupRepository.getGroups();

          // Verify remote was NOT called (offline)
          verifyNever(mockGroupRemote.getGroups());

          // Verify local cache was used
          verify(mockGroupLocal.getGroups()).called(1);

          // Verify result matches cached data
          expect(result.length, cachedGroups.length);
          for (int j = 0; j < result.length; j++) {
            expect(result[j].id, cachedGroups[j].id);
            expect(result[j].name, cachedGroups[j].name);
            expect(result[j].creatorId, cachedGroups[j].creatorId);
            expect(result[j].members.length, cachedGroups[j].members.length);
          }

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockGroupRemote);
          reset(mockGroupLocal);
        }
      },
    );

    test(
      'when offline, getBills returns data from local cache without calling remote',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random cached bills
          final cachedBills = _generateRandomBills(random);

          // Mock offline connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Mock local data source returning cached bills
          when(
            mockBillLocal.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).thenAnswer((_) async => cachedBills);

          // Execute repository method
          final result = await billRepository.getBills();

          // Verify remote was NOT called (offline)
          verifyNever(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          );

          // Verify local cache was used
          verify(
            mockBillLocal.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).called(1);

          // Verify result matches cached data
          expect(result.length, cachedBills.length);
          for (int j = 0; j < result.length; j++) {
            expect(result[j].id, cachedBills[j].id);
            expect(result[j].title, cachedBills[j].title);
            expect(result[j].totalAmount, cachedBills[j].totalAmount);
            expect(result[j].shares.length, cachedBills[j].shares.length);
          }

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockBillRemote);
          reset(mockBillLocal);
        }
      },
    );

    test(
      'when offline, getTransactions returns data from local cache without calling remote',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random cached transactions
          final cachedTransactions = _generateRandomTransactions(random);

          // Mock offline connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Mock local data source returning cached transactions
          when(
            mockTransactionLocal.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).thenAnswer((_) async => cachedTransactions);

          // Execute repository method
          final result = await transactionRepository.getTransactions();

          // Verify remote was NOT called (offline)
          verifyNever(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          );

          // Verify local cache was used
          verify(
            mockTransactionLocal.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).called(1);

          // Verify result matches cached data
          final resultTransactions =
              result['transactions'] as List<TransactionModel>;
          expect(resultTransactions.length, cachedTransactions.length);
          for (int j = 0; j < resultTransactions.length; j++) {
            expect(resultTransactions[j].id, cachedTransactions[j].id);
            expect(resultTransactions[j].amount, cachedTransactions[j].amount);
            expect(resultTransactions[j].status, cachedTransactions[j].status);
          }

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockTransactionRemote);
          reset(mockTransactionLocal);
        }
      },
    );

    test(
      'when offline, getBill returns data from local cache without calling remote',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random cached bill
          final cachedBill = _generateRandomBill(random);
          final billId = cachedBill.id;

          // Mock offline connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Mock local data source returning cached bill
          when(
            mockBillLocal.getBillById(billId),
          ).thenAnswer((_) async => cachedBill);

          // Execute repository method
          final result = await billRepository.getBill(billId);

          // Verify remote was NOT called (offline)
          // Note: Remote getBill not implemented yet, so no verifyNever needed

          // Verify local cache was used
          verify(mockBillLocal.getBillById(billId)).called(1);

          // Verify result matches cached data
          expect(result?.id, cachedBill.id);
          expect(result?.title, cachedBill.title);
          expect(result?.totalAmount, cachedBill.totalAmount);
          expect(result?.shares.length, cachedBill.shares.length);

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockBillRemote);
          reset(mockBillLocal);
        }
      },
    );

    test(
      'when offline, all read operations use local cache consistently',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random cached data for all types
          final cachedGroups = _generateRandomGroups(random);
          final cachedBills = _generateRandomBills(random);
          final cachedTransactions = _generateRandomTransactions(random);

          // Mock offline connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Mock local data sources
          when(
            mockGroupLocal.getGroups(),
          ).thenAnswer((_) async => cachedGroups);
          when(
            mockBillLocal.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).thenAnswer((_) async => cachedBills);
          when(
            mockTransactionLocal.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).thenAnswer((_) async => cachedTransactions);

          // Execute all repository read methods
          final groups = await groupRepository.getGroups();
          final bills = await billRepository.getBills();
          final transactions = await transactionRepository.getTransactions();

          // Verify NO remote calls were made (offline)
          verifyNever(mockGroupRemote.getGroups());
          verifyNever(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          );
          verifyNever(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          );

          // Verify all local cache calls were made
          verify(mockGroupLocal.getGroups()).called(1);
          verify(
            mockBillLocal.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).called(1);
          verify(
            mockTransactionLocal.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).called(1);

          // Verify all results match cached data
          expect(groups.length, cachedGroups.length);
          expect(bills.length, cachedBills.length);
          final resultTransactions =
              transactions['transactions'] as List<TransactionModel>;
          expect(resultTransactions.length, cachedTransactions.length);

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockGroupRemote);
          reset(mockBillRemote);
          reset(mockTransactionRemote);
          reset(mockGroupLocal);
          reset(mockBillLocal);
          reset(mockTransactionLocal);
        }
      },
    );

    test(
      'when offline, empty cache returns empty list without errors',
      () async {
        for (int i = 0; i < 50; i++) {
          // Mock offline connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Mock local data sources returning empty lists
          when(mockGroupLocal.getGroups()).thenAnswer((_) async => []);
          when(
            mockBillLocal.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).thenAnswer((_) async => []);
          when(
            mockTransactionLocal.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).thenAnswer((_) async => []);

          // Execute repository methods
          final groups = await groupRepository.getGroups();
          final bills = await billRepository.getBills();
          final transactions = await transactionRepository.getTransactions();

          // Verify remote was NOT called (offline)
          verifyNever(mockGroupRemote.getGroups());
          verifyNever(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          );
          verifyNever(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          );

          // Verify empty results without errors
          expect(groups, isEmpty);
          expect(bills, isEmpty);
          final resultTransactions =
              transactions['transactions'] as List<TransactionModel>;
          expect(resultTransactions, isEmpty);

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockGroupRemote);
          reset(mockBillRemote);
          reset(mockTransactionRemote);
          reset(mockGroupLocal);
          reset(mockBillLocal);
          reset(mockTransactionLocal);
        }
      },
    );

    test(
      'when offline, filtered queries use local cache with filters applied',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random data
          final groupId = random.nextInt(1000) + 1;
          final fromDate = DateTime.now().subtract(
            Duration(days: random.nextInt(30) + 30),
          );
          final toDate = DateTime.now().subtract(
            Duration(days: random.nextInt(30)),
          );

          final cachedBills = _generateRandomBills(random);
          final cachedTransactions = _generateRandomTransactions(random);

          // Mock offline connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Mock local data sources with filters (using any for nullable parameters)
          when(
            mockBillLocal.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).thenAnswer((_) async => cachedBills);
          when(
            mockTransactionLocal.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).thenAnswer((_) async => cachedTransactions);

          // Execute repository methods with filters
          final bills = await billRepository.getBills(
            groupId: groupId,
            fromDate: fromDate,
            toDate: toDate,
          );
          final transactions = await transactionRepository.getTransactions(
            fromDate: fromDate,
            toDate: toDate,
            groupId: groupId,
          );

          // Verify remote was NOT called (offline)
          verifyNever(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          );
          verifyNever(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          );

          // Verify local cache was called
          verify(
            mockBillLocal.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).called(1);
          verify(
            mockTransactionLocal.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).called(1);

          // Verify results match cached data
          expect(bills.length, cachedBills.length);
          final resultTransactions =
              transactions['transactions'] as List<TransactionModel>;
          expect(resultTransactions.length, cachedTransactions.length);

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockBillRemote);
          reset(mockTransactionRemote);
          reset(mockBillLocal);
          reset(mockTransactionLocal);
        }
      },
    );
  });
}

// Helper functions to generate random test data

List<GroupModel> _generateRandomGroups(Random random) {
  final count = random.nextInt(5) + 1;
  return List.generate(count, (_) => _generateRandomGroup(random));
}

GroupModel _generateRandomGroup(Random random) {
  final memberCount = random.nextInt(5) + 1;
  final members = List.generate(
    memberCount,
    (_) => _generateRandomUser(random),
  );

  return GroupModel(
    id: random.nextInt(100000),
    name: 'Group ${random.nextInt(10000)}',
    creatorId: members.first.id,
    members: members,
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    isSynced: true,
  );
}

List<BillModel> _generateRandomBills(Random random) {
  final count = random.nextInt(5) + 1;
  return List.generate(count, (_) => _generateRandomBill(random));
}

BillModel _generateRandomBill(Random random) {
  final shareCount = random.nextInt(5) + 1;
  final shares = List.generate(shareCount, (_) => _generateRandomShare(random));
  final totalAmount = shares.fold(0.0, (sum, share) => sum + share.amount);

  return BillModel(
    id: random.nextInt(100000),
    groupId: random.nextInt(10000),
    creatorId: random.nextInt(10000),
    title: 'Bill ${random.nextInt(10000)}',
    totalAmount: totalAmount,
    billDate: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    shares: shares,
    isSynced: true,
  );
}

List<TransactionModel> _generateRandomTransactions(Random random) {
  final count = random.nextInt(5) + 1;
  return List.generate(count, (_) => _generateRandomTransaction(random));
}

TransactionModel _generateRandomTransaction(Random random) {
  final hasPaidAt = random.nextBool();

  return TransactionModel(
    id: random.nextInt(100000),
    shareId: random.nextInt(10000),
    userId: random.nextInt(10000),
    amount: (random.nextDouble() * 10000 + 1).roundToDouble(),
    paymentMethod: random.nextBool()
        ? PaymentMethod.gcash
        : PaymentMethod.paymaya,
    paymongoTransactionId: 'pay_${random.nextInt(1000000)}',
    status: random.nextBool()
        ? TransactionStatus.paid
        : TransactionStatus.pending,
    paidAt: hasPaidAt
        ? DateTime.now().subtract(Duration(days: random.nextInt(30)))
        : null,
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
  );
}

ShareModel _generateRandomShare(Random random) {
  return ShareModel(
    id: random.nextInt(100000),
    billId: random.nextInt(10000),
    userId: random.nextInt(10000),
    amount: (random.nextDouble() * 1000 + 1).roundToDouble(),
    status: random.nextBool() ? ShareStatus.paid : ShareStatus.unpaid,
    user: _generateRandomUser(random),
  );
}

UserModel _generateRandomUser(Random random) {
  return UserModel(
    id: random.nextInt(100000),
    username: 'user_${random.nextInt(10000)}',
    email: 'user${random.nextInt(10000)}@example.com',
    createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
  );
}
