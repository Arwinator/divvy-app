import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:divvy/data/repositories/bill_repository.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';
import 'dart:math';

import 'offline_operation_queueing_test.mocks.dart';

@GenerateMocks([
  remote.BillRemoteDataSource,
  local.BillLocalDataSource,
  local.SyncQueueLocalDataSource,
  NetworkInfo,
])
void main() {
  late BillRepository repository;
  late MockBillRemoteDataSource mockRemoteDataSource;
  late MockBillLocalDataSource mockLocalDataSource;
  late MockSyncQueueLocalDataSource mockSyncQueueDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late Random random;

  setUp(() {
    mockRemoteDataSource = MockBillRemoteDataSource();
    mockLocalDataSource = MockBillLocalDataSource();
    mockSyncQueueDataSource = MockSyncQueueLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    random = Random();

    repository = BillRepository(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      syncQueueDataSource: mockSyncQueueDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('Offline Operation Queueing', () {
    test('bill creation is queued when offline and throws exception', () async {
      // Property: When offline, bill creation should:
      // 1. Add operation to sync queue
      // 2. Throw exception indicating offline status
      // 3. NOT call remote data source
      // 4. NOT save to local cache (since creation failed)

      for (int i = 0; i < 50; i++) {
        // Reset mocks for each iteration
        reset(mockNetworkInfo);
        reset(mockSyncQueueDataSource);
        reset(mockRemoteDataSource);
        reset(mockLocalDataSource);

        // Generate random bill data
        final groupId = random.nextInt(100) + 1;
        final title = 'Bill ${random.nextInt(1000)}';
        final totalAmount = (random.nextDouble() * 10000) + 1;
        final billDate = DateTime.now().subtract(
          Duration(days: random.nextInt(30)),
        );
        final splitType = random.nextBool() ? 'equal' : 'custom';

        // Simulate offline state
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Mock sync queue to return operation ID
        when(
          mockSyncQueueDataSource.addOperation(any),
        ).thenAnswer((_) async => i + 1);

        // Attempt to create bill while offline
        try {
          await repository.createBill(
            groupId: groupId,
            title: title,
            totalAmount: totalAmount,
            billDate: billDate,
            splitType: splitType,
          );

          // Should not reach here - expect exception
          fail('Expected exception when creating bill offline');
        } catch (e) {
          // Verify exception message indicates offline status
          expect(e.toString(), contains('Cannot create bill while offline'));
          expect(e.toString(), contains('Will sync when online'));
        }

        // Verify operation was added to sync queue
        final capturedOperation =
            verify(
                  mockSyncQueueDataSource.addOperation(captureAny),
                ).captured.single
                as local.SyncOperation;

        expect(capturedOperation.operationType, equals('create_bill'));
        expect(capturedOperation.endpoint, equals('/api/bills'));
        expect(capturedOperation.payload['group_id'], equals(groupId));
        expect(capturedOperation.payload['title'], equals(title));
        expect(capturedOperation.payload['total_amount'], equals(totalAmount));
        expect(
          capturedOperation.payload['bill_date'],
          equals(billDate.toIso8601String()),
        );
        expect(capturedOperation.payload['split_type'], equals(splitType));
        expect(capturedOperation.retryCount, equals(0));

        // Verify remote data source was NOT called
        verifyNever(
          mockRemoteDataSource.createBill(
            groupId: anyNamed('groupId'),
            title: anyNamed('title'),
            totalAmount: anyNamed('totalAmount'),
            billDate: anyNamed('billDate'),
            splitType: anyNamed('splitType'),
            shares: anyNamed('shares'),
          ),
        );

        // Verify local data source was NOT called (no bill to save)
        verifyNever(mockLocalDataSource.saveBill(any));
      }
    });

    test(
      'bill creation with custom split is queued correctly when offline',
      () async {
        // Property: Custom split bills should queue with shares data

        for (int i = 0; i < 50; i++) {
          // Reset mocks
          reset(mockNetworkInfo);
          reset(mockSyncQueueDataSource);
          reset(mockRemoteDataSource);
          reset(mockLocalDataSource);

          // Generate random bill data with custom split
          final groupId = random.nextInt(100) + 1;
          final title = 'Custom Bill ${random.nextInt(1000)}';
          final totalAmount = (random.nextDouble() * 10000) + 1;
          final billDate = DateTime.now();
          final splitType = 'custom';

          // Generate random shares that sum to total
          final memberCount = random.nextInt(5) + 2; // 2-6 members
          final shares = <Map<String, dynamic>>[];
          double remaining = totalAmount;

          for (int j = 0; j < memberCount - 1; j++) {
            final amount = (random.nextDouble() * remaining * 0.5);
            shares.add({'user_id': j + 1, 'amount': amount});
            remaining -= amount;
          }

          // Last share gets remaining amount
          shares.add({'user_id': memberCount, 'amount': remaining});

          // Simulate offline state
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
          when(
            mockSyncQueueDataSource.addOperation(any),
          ).thenAnswer((_) async => i + 1);

          // Attempt to create bill with custom split while offline
          try {
            await repository.createBill(
              groupId: groupId,
              title: title,
              totalAmount: totalAmount,
              billDate: billDate,
              splitType: splitType,
              shares: shares,
            );

            fail('Expected exception when creating bill offline');
          } catch (e) {
            expect(e.toString(), contains('Cannot create bill while offline'));
          }

          // Verify operation was queued with shares data
          final capturedOperation =
              verify(
                    mockSyncQueueDataSource.addOperation(captureAny),
                  ).captured.single
                  as local.SyncOperation;

          expect(capturedOperation.operationType, equals('create_bill'));
          expect(capturedOperation.payload['split_type'], equals('custom'));
          expect(capturedOperation.payload['shares'], isNotNull);
          expect(capturedOperation.payload['shares'], equals(shares));

          // Verify shares data structure
          final queuedShares =
              capturedOperation.payload['shares'] as List<Map<String, dynamic>>;
          expect(queuedShares.length, equals(memberCount));

          // Verify total of queued shares matches bill total
          final queuedTotal = queuedShares.fold<double>(
            0.0,
            (sum, share) => sum + (share['amount'] as double),
          );
          expect((queuedTotal - totalAmount).abs(), lessThan(0.01));
        }
      },
    );

    test(
      'multiple bill creations while offline queue in correct order',
      () async {
        // Property: Multiple operations should queue in chronological order

        final operations = <local.SyncOperation>[];

        // Simulate offline state
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockSyncQueueDataSource.addOperation(any)).thenAnswer((
          invocation,
        ) {
          final operation =
              invocation.positionalArguments[0] as local.SyncOperation;
          operations.add(operation);
          return Future.value(operations.length);
        });

        // Create multiple bills while offline
        final billCount = random.nextInt(5) + 3; // 3-7 bills
        final creationTimes = <DateTime>[];

        for (int i = 0; i < billCount; i++) {
          final creationTime = DateTime.now();
          creationTimes.add(creationTime);

          try {
            await repository.createBill(
              groupId: i + 1,
              title: 'Bill $i',
              totalAmount: (i + 1) * 100.0,
              billDate: DateTime.now(),
              splitType: 'equal',
            );
          } catch (e) {
            // Expected exception
          }

          // Small delay to ensure different timestamps
          await Future.delayed(Duration(milliseconds: 10));
        }

        // Verify all operations were queued
        expect(operations.length, equals(billCount));

        // Verify operations are in chronological order
        for (int i = 0; i < operations.length - 1; i++) {
          expect(
            operations[i].createdAt.isBefore(operations[i + 1].createdAt) ||
                operations[i].createdAt.isAtSameMomentAs(
                  operations[i + 1].createdAt,
                ),
            isTrue,
            reason: 'Operations should be queued in chronological order',
          );
        }

        // Verify each operation has correct data
        for (int i = 0; i < operations.length; i++) {
          expect(operations[i].operationType, equals('create_bill'));
          expect(operations[i].endpoint, equals('/api/bills'));
          expect(operations[i].payload['group_id'], equals(i + 1));
          expect(operations[i].payload['title'], equals('Bill $i'));
          expect(
            operations[i].payload['total_amount'],
            equals((i + 1) * 100.0),
          );
          expect(operations[i].retryCount, equals(0));
        }
      },
    );
  });
}
