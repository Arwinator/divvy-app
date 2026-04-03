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

import 'online_sync_behavior_test.mocks.dart';

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
  group('Online Sync Behavior', () {
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
      'when online, getGroups fetches from remote and updates local cache',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random groups
          final groups = _generateRandomGroups(random);

          // Mock online connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Mock remote data source returning groups
          when(mockGroupRemote.getGroups()).thenAnswer((_) async => groups);

          // Mock local data source save operations
          for (final group in groups) {
            when(mockGroupLocal.saveGroup(group)).thenAnswer((_) async => {});
          }

          // Execute repository method
          final result = await groupRepository.getGroups();

          // Verify remote was called
          verify(mockGroupRemote.getGroups()).called(1);

          // Verify each group was saved to local cache
          for (final group in groups) {
            verify(mockGroupLocal.saveGroup(group)).called(1);
          }

          // Verify result matches remote data
          expect(result.length, groups.length);
          for (int j = 0; j < result.length; j++) {
            expect(result[j].id, groups[j].id);
            expect(result[j].name, groups[j].name);
            expect(result[j].creatorId, groups[j].creatorId);
          }

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockGroupRemote);
          reset(mockGroupLocal);
        }
      },
    );

    test(
      'when online, getBills fetches from remote and updates local cache',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random bills
          final bills = _generateRandomBills(random);

          // Mock online connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Mock remote data source returning bills
          when(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).thenAnswer((_) async => bills);

          // Mock local data source save operations
          for (final bill in bills) {
            when(mockBillLocal.saveBill(bill)).thenAnswer((_) async => {});
          }

          // Execute repository method
          final result = await billRepository.getBills();

          // Verify remote was called
          verify(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).called(1);

          // Verify each bill was saved to local cache
          for (final bill in bills) {
            verify(mockBillLocal.saveBill(bill)).called(1);
          }

          // Verify result matches remote data
          expect(result.length, bills.length);
          for (int j = 0; j < result.length; j++) {
            expect(result[j].id, bills[j].id);
            expect(result[j].title, bills[j].title);
            expect(result[j].totalAmount, bills[j].totalAmount);
          }

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockBillRemote);
          reset(mockBillLocal);
        }
      },
    );

    test(
      'when online, getTransactions fetches from remote and updates local cache',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random transactions
          final transactions = _generateRandomTransactions(random);
          final transactionResponse = remote.TransactionResponse(
            transactions: transactions,
            summary: remote.TransactionSummary(
              totalPaid: transactions
                  .where((t) => t.status == TransactionStatus.paid)
                  .fold(0.0, (sum, t) => sum + t.amount),
              totalOwed: (random.nextDouble() * 5000).roundToDouble(),
            ),
          );

          // Mock online connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Mock remote data source returning transaction response
          when(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).thenAnswer((_) async => transactionResponse);

          // Mock local data source save operations
          for (final transaction in transactions) {
            when(
              mockTransactionLocal.saveTransaction(transaction),
            ).thenAnswer((_) async => {});
          }

          // Execute repository method
          final result = await transactionRepository.getTransactions();

          // Verify remote was called
          verify(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).called(1);

          // Verify each transaction was saved to local cache
          for (final transaction in transactions) {
            verify(mockTransactionLocal.saveTransaction(transaction)).called(1);
          }

          // Verify result matches remote data
          final resultTransactions =
              result['transactions'] as List<TransactionModel>;
          expect(resultTransactions.length, transactions.length);
          for (int j = 0; j < resultTransactions.length; j++) {
            expect(resultTransactions[j].id, transactions[j].id);
            expect(resultTransactions[j].amount, transactions[j].amount);
            expect(resultTransactions[j].status, transactions[j].status);
          }

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockTransactionRemote);
          reset(mockTransactionLocal);
        }
      },
    );

    test(
      'when online, createGroup syncs to remote and saves to local cache',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random group data
          final groupName = 'Group ${random.nextInt(10000)}';
          final createdGroup = _generateRandomGroup(random, groupName);

          // Mock online connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Mock remote data source creating group
          when(
            mockGroupRemote.createGroup(name: groupName),
          ).thenAnswer((_) async => createdGroup);

          // Mock local data source save operation
          when(
            mockGroupLocal.saveGroup(createdGroup),
          ).thenAnswer((_) async => {});

          // Execute repository method
          final result = await groupRepository.createGroup(name: groupName);

          // Verify remote was called
          verify(mockGroupRemote.createGroup(name: groupName)).called(1);

          // Verify group was saved to local cache
          verify(mockGroupLocal.saveGroup(createdGroup)).called(1);

          // Verify result matches created group
          expect(result.id, createdGroup.id);
          expect(result.name, createdGroup.name);
          expect(result.creatorId, createdGroup.creatorId);

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockGroupRemote);
          reset(mockGroupLocal);
        }
      },
    );

    test(
      'when online, createBill syncs to remote and saves to local cache',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random bill data
          final groupId = random.nextInt(1000) + 1;
          final title = 'Bill ${random.nextInt(10000)}';
          final totalAmount = (random.nextDouble() * 10000 + 1).roundToDouble();
          final billDate = DateTime.now().subtract(
            Duration(days: random.nextInt(365)),
          );
          final createdBill = _generateRandomBill(
            random,
            groupId: groupId,
            title: title,
            totalAmount: totalAmount,
          );

          // Mock online connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Mock remote data source creating bill
          when(
            mockBillRemote.createBill(
              groupId: groupId,
              title: title,
              totalAmount: totalAmount,
              billDate: billDate,
              splitType: 'equal',
              shares: null,
            ),
          ).thenAnswer((_) async => createdBill);

          // Mock local data source save operation
          when(mockBillLocal.saveBill(createdBill)).thenAnswer((_) async => {});

          // Execute repository method
          final result = await billRepository.createBill(
            groupId: groupId,
            title: title,
            totalAmount: totalAmount,
            billDate: billDate,
            splitType: 'equal',
          );

          // Verify remote was called
          verify(
            mockBillRemote.createBill(
              groupId: groupId,
              title: title,
              totalAmount: totalAmount,
              billDate: billDate,
              splitType: 'equal',
              shares: null,
            ),
          ).called(1);

          // Verify bill was saved to local cache
          verify(mockBillLocal.saveBill(createdBill)).called(1);

          // Verify result matches created bill
          expect(result.id, createdBill.id);
          expect(result.title, createdBill.title);
          expect(result.totalAmount, createdBill.totalAmount);

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockBillRemote);
          reset(mockBillLocal);
        }
      },
    );

    test(
      'when online but remote fails, read operations fall back to local cache',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random groups for cache
          final cachedGroups = _generateRandomGroups(random);

          // Mock online connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Mock remote data source throwing error
          when(
            mockGroupRemote.getGroups(),
          ).thenThrow(Exception('Network error'));

          // Mock local data source returning cached data
          when(
            mockGroupLocal.getGroups(),
          ).thenAnswer((_) async => cachedGroups);

          // Execute repository method
          final result = await groupRepository.getGroups();

          // Verify remote was attempted
          verify(mockGroupRemote.getGroups()).called(1);

          // Verify local cache was used as fallback
          verify(mockGroupLocal.getGroups()).called(1);

          // Verify result matches cached data
          expect(result.length, cachedGroups.length);
          for (int j = 0; j < result.length; j++) {
            expect(result[j].id, cachedGroups[j].id);
            expect(result[j].name, cachedGroups[j].name);
          }

          // Reset mocks for next iteration
          reset(mockNetworkInfo);
          reset(mockGroupRemote);
          reset(mockGroupLocal);
        }
      },
    );

    test(
      'when online, sync updates local cache with server data for all data types',
      () async {
        for (int i = 0; i < 50; i++) {
          // Generate random data for all types
          final groups = _generateRandomGroups(random);
          final bills = _generateRandomBills(random);
          final transactions = _generateRandomTransactions(random);
          final transactionResponse = remote.TransactionResponse(
            transactions: transactions,
            summary: remote.TransactionSummary(
              totalPaid: transactions
                  .where((t) => t.status == TransactionStatus.paid)
                  .fold(0.0, (sum, t) => sum + t.amount),
              totalOwed: (random.nextDouble() * 5000).roundToDouble(),
            ),
          );

          // Mock online connectivity
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

          // Mock remote data sources
          when(mockGroupRemote.getGroups()).thenAnswer((_) async => groups);
          when(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).thenAnswer((_) async => bills);
          when(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).thenAnswer((_) async => transactionResponse);

          // Mock local data source save operations
          for (final group in groups) {
            when(mockGroupLocal.saveGroup(group)).thenAnswer((_) async => {});
          }
          for (final bill in bills) {
            when(mockBillLocal.saveBill(bill)).thenAnswer((_) async => {});
          }
          for (final transaction in transactions) {
            when(
              mockTransactionLocal.saveTransaction(transaction),
            ).thenAnswer((_) async => {});
          }

          // Execute repository methods (simulating sync)
          await groupRepository.getGroups();
          await billRepository.getBills();
          await transactionRepository.getTransactions();

          // Verify all remote sources were called
          verify(mockGroupRemote.getGroups()).called(1);
          verify(
            mockBillRemote.getBills(
              groupId: anyNamed('groupId'),
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
            ),
          ).called(1);
          verify(
            mockTransactionRemote.getTransactions(
              fromDate: anyNamed('fromDate'),
              toDate: anyNamed('toDate'),
              groupId: anyNamed('groupId'),
            ),
          ).called(1);

          // Verify all data was saved to local cache
          for (final group in groups) {
            verify(mockGroupLocal.saveGroup(group)).called(1);
          }
          for (final bill in bills) {
            verify(mockBillLocal.saveBill(bill)).called(1);
          }
          for (final transaction in transactions) {
            verify(mockTransactionLocal.saveTransaction(transaction)).called(1);
          }

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
  });
}

// Helper functions to generate random test data

List<GroupModel> _generateRandomGroups(Random random) {
  final count = random.nextInt(5) + 1;
  return List.generate(count, (_) => _generateRandomGroup(random));
}

GroupModel _generateRandomGroup(Random random, [String? name]) {
  final memberCount = random.nextInt(5) + 1;
  final members = List.generate(
    memberCount,
    (_) => _generateRandomUser(random),
  );

  return GroupModel(
    id: random.nextInt(100000),
    name: name ?? 'Group ${random.nextInt(10000)}',
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

BillModel _generateRandomBill(
  Random random, {
  int? groupId,
  String? title,
  double? totalAmount,
}) {
  final shareCount = random.nextInt(5) + 1;
  final shares = List.generate(shareCount, (_) => _generateRandomShare(random));
  final calculatedAmount = shares.fold(0.0, (sum, share) => sum + share.amount);
  final amount = totalAmount ?? calculatedAmount;

  return BillModel(
    id: random.nextInt(100000),
    groupId: groupId ?? random.nextInt(10000),
    creatorId: random.nextInt(10000),
    title: title ?? 'Bill ${random.nextInt(10000)}',
    totalAmount: amount,
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
