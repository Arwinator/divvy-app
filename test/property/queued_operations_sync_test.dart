import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:divvy/core/services/sync_service.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/network/network_info.dart';
import 'dart:math';

import 'queued_operations_sync_test.mocks.dart';

@GenerateMocks([
  local.SyncQueueLocalDataSource,
  remote.SyncRemoteDataSource,
  GroupRepository,
  BillRepository,
  TransactionRepository,
  NetworkInfo,
])
void main() {
  late SyncService syncService;
  late MockSyncQueueLocalDataSource mockSyncQueueDataSource;
  late MockSyncRemoteDataSource mockSyncRemoteDataSource;
  late MockGroupRepository mockGroupRepository;
  late MockBillRepository mockBillRepository;
  late MockTransactionRepository mockTransactionRepository;
  late MockNetworkInfo mockNetworkInfo;
  late Random random;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    mockSyncQueueDataSource = MockSyncQueueLocalDataSource();
    mockSyncRemoteDataSource = MockSyncRemoteDataSource();
    mockGroupRepository = MockGroupRepository();
    mockBillRepository = MockBillRepository();
    mockTransactionRepository = MockTransactionRepository();
    mockNetworkInfo = MockNetworkInfo();
    random = Random();

    syncService = SyncService(
      syncQueueDataSource: mockSyncQueueDataSource,
      syncRemoteDataSource: mockSyncRemoteDataSource,
      groupRepository: mockGroupRepository,
      billRepository: mockBillRepository,
      transactionRepository: mockTransactionRepository,
      networkInfo: mockNetworkInfo,
    );
  });

  group('Queued Operations Sync on Reconnection', () {
    test('queued operations are sent when connectivity is restored', () async {
      for (int i = 0; i < 50; i++) {
        reset(mockNetworkInfo);
        reset(mockSyncQueueDataSource);
        reset(mockSyncRemoteDataSource);
        reset(mockGroupRepository);
        reset(mockBillRepository);
        reset(mockTransactionRepository);

        final operationCount = random.nextInt(10) + 1;
        final queuedOperations = <local.SyncOperation>[];

        for (int j = 0; j < operationCount; j++) {
          final operationType = random.nextBool()
              ? 'create_group'
              : 'create_bill';
          final endpoint = operationType == 'create_group'
              ? '/api/groups'
              : '/api/bills';

          final Map<String, dynamic> payload;
          if (operationType == 'create_group') {
            payload = {'name': 'Group ${random.nextInt(1000)}'};
          } else {
            payload = {
              'group_id': random.nextInt(100) + 1,
              'title': 'Bill ${random.nextInt(1000)}',
              'total_amount': (random.nextDouble() * 10000) + 1,
              'bill_date': DateTime.now().toIso8601String(),
              'split_type': 'equal',
            };
          }

          queuedOperations.add(
            local.SyncOperation(
              id: j + 1,
              operationType: operationType,
              endpoint: endpoint,
              payload: payload,
              retryCount: 0,
              createdAt: DateTime.now().subtract(
                Duration(minutes: random.nextInt(60)),
              ),
            ),
          );
        }

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockSyncQueueDataSource.getAll(),
        ).thenAnswer((_) async => queuedOperations);

        final successResults = queuedOperations.map((op) {
          return remote.SyncOperationResult(
            success: true,
            localId: op.id.toString(),
            serverId: random.nextInt(1000) + 1,
            error: null,
          );
        }).toList();

        when(
          mockSyncRemoteDataSource.batchSync(
            operations: anyNamed('operations'),
          ),
        ).thenAnswer(
          (_) async => remote.BatchSyncResponse(results: successResults),
        );

        for (final op in queuedOperations) {
          when(mockSyncQueueDataSource.remove(op.id!)).thenAnswer((_) async {});
        }

        when(
          mockGroupRepository.getGroups(),
        ).thenAnswer((_) async => <GroupModel>[]);
        when(mockTransactionRepository.getTransactions()).thenAnswer(
          (_) async => {
            'transactions': <TransactionModel>[],
            'summary': {'total_paid': 0.0, 'total_owed': 0.0},
          },
        );

        await syncService.sync();

        verify(mockSyncQueueDataSource.getAll()).called(1);

        final capturedOperations =
            verify(
                  mockSyncRemoteDataSource.batchSync(
                    operations: captureAnyNamed('operations'),
                  ),
                ).captured.single
                as List<remote.SyncOperation>;

        expect(capturedOperations.length, equals(operationCount));

        for (int j = 0; j < operationCount; j++) {
          final queuedOp = queuedOperations[j];
          final sentOp = capturedOperations[j];

          expect(sentOp.type, equals(queuedOp.operationType));
          expect(sentOp.endpoint, equals(queuedOp.endpoint));
          expect(sentOp.payload, equals(queuedOp.payload));
          expect(sentOp.localId, equals(queuedOp.id.toString()));
        }

        for (final op in queuedOperations) {
          verify(mockSyncQueueDataSource.remove(op.id!)).called(1);
        }
      }
    });

    test(
      'failed operations remain in queue with incremented retry count',
      () async {
        for (int i = 0; i < 50; i++) {
          reset(mockNetworkInfo);
          reset(mockSyncQueueDataSource);
          reset(mockSyncRemoteDataSource);
          reset(mockGroupRepository);
          reset(mockBillRepository);
          reset(mockTransactionRepository);

          final operationCount = random.nextInt(5) + 1;
          final queuedOperations = <local.SyncOperation>[];

          for (int j = 0; j < operationCount; j++) {
            queuedOperations.add(
              local.SyncOperation(
                id: j + 1,
                operationType: 'create_group',
                endpoint: '/api/groups',
                payload: {'name': 'Group $j'},
                retryCount: random.nextInt(2),
                createdAt: DateTime.now(),
              ),
            );
          }

          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            mockSyncQueueDataSource.getAll(),
          ).thenAnswer((_) async => queuedOperations);

          final failedResults = queuedOperations.map((op) {
            return remote.SyncOperationResult(
              success: false,
              localId: op.id.toString(),
              serverId: null,
              error: 'Server error',
            );
          }).toList();

          when(
            mockSyncRemoteDataSource.batchSync(
              operations: anyNamed('operations'),
            ),
          ).thenAnswer(
            (_) async => remote.BatchSyncResponse(results: failedResults),
          );

          for (final op in queuedOperations) {
            when(
              mockSyncQueueDataSource.incrementRetry(op.id!),
            ).thenAnswer((_) async {});
          }

          when(
            mockGroupRepository.getGroups(),
          ).thenAnswer((_) async => <GroupModel>[]);
          when(mockTransactionRepository.getTransactions()).thenAnswer(
            (_) async => {
              'transactions': <TransactionModel>[],
              'summary': {'total_paid': 0.0, 'total_owed': 0.0},
            },
          );

          await syncService.sync();

          for (final op in queuedOperations) {
            verifyNever(mockSyncQueueDataSource.remove(op.id!));
          }

          for (final op in queuedOperations) {
            verify(mockSyncQueueDataSource.incrementRetry(op.id!)).called(1);
          }
        }
      },
    );

    test('operations exceeding max retries are removed from queue', () async {
      for (int i = 0; i < 50; i++) {
        reset(mockNetworkInfo);
        reset(mockSyncQueueDataSource);
        reset(mockSyncRemoteDataSource);
        reset(mockGroupRepository);
        reset(mockBillRepository);
        reset(mockTransactionRepository);

        final operation = local.SyncOperation(
          id: 1,
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Group ${random.nextInt(1000)}'},
          retryCount: 3,
          createdAt: DateTime.now(),
        );

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockSyncQueueDataSource.getAll(),
        ).thenAnswer((_) async => [operation]);

        when(
          mockSyncRemoteDataSource.batchSync(
            operations: anyNamed('operations'),
          ),
        ).thenAnswer(
          (_) async => remote.BatchSyncResponse(
            results: [
              remote.SyncOperationResult(
                success: false,
                localId: operation.id.toString(),
                serverId: null,
                error: 'Persistent server error',
              ),
            ],
          ),
        );

        when(
          mockSyncQueueDataSource.remove(operation.id!),
        ).thenAnswer((_) async {});

        when(
          mockGroupRepository.getGroups(),
        ).thenAnswer((_) async => <GroupModel>[]);
        when(mockTransactionRepository.getTransactions()).thenAnswer(
          (_) async => {
            'transactions': <TransactionModel>[],
            'summary': {'total_paid': 0.0, 'total_owed': 0.0},
          },
        );

        await syncService.sync();

        verify(mockSyncQueueDataSource.remove(operation.id!)).called(1);
        verifyNever(mockSyncQueueDataSource.incrementRetry(operation.id!));
      }
    });

    test(
      'mixed success and failure operations are handled correctly',
      () async {
        for (int i = 0; i < 50; i++) {
          reset(mockNetworkInfo);
          reset(mockSyncQueueDataSource);
          reset(mockSyncRemoteDataSource);
          reset(mockGroupRepository);
          reset(mockBillRepository);
          reset(mockTransactionRepository);

          final operationCount = random.nextInt(6) + 3;
          final queuedOperations = <local.SyncOperation>[];

          for (int j = 0; j < operationCount; j++) {
            queuedOperations.add(
              local.SyncOperation(
                id: j + 1,
                operationType: 'create_group',
                endpoint: '/api/groups',
                payload: {'name': 'Group $j'},
                retryCount: 0,
                createdAt: DateTime.now(),
              ),
            );
          }

          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(
            mockSyncQueueDataSource.getAll(),
          ).thenAnswer((_) async => queuedOperations);

          final results = <remote.SyncOperationResult>[];
          final successfulOps = <local.SyncOperation>[];
          final failedOps = <local.SyncOperation>[];

          for (int j = 0; j < operationCount; j++) {
            final isSuccess = random.nextBool();
            final op = queuedOperations[j];

            if (isSuccess) {
              results.add(
                remote.SyncOperationResult(
                  success: true,
                  localId: op.id.toString(),
                  serverId: random.nextInt(1000) + 1,
                  error: null,
                ),
              );
              successfulOps.add(op);
            } else {
              results.add(
                remote.SyncOperationResult(
                  success: false,
                  localId: op.id.toString(),
                  serverId: null,
                  error: 'Validation error',
                ),
              );
              failedOps.add(op);
            }
          }

          when(
            mockSyncRemoteDataSource.batchSync(
              operations: anyNamed('operations'),
            ),
          ).thenAnswer((_) async => remote.BatchSyncResponse(results: results));

          for (final op in queuedOperations) {
            when(
              mockSyncQueueDataSource.remove(op.id!),
            ).thenAnswer((_) async {});
            when(
              mockSyncQueueDataSource.incrementRetry(op.id!),
            ).thenAnswer((_) async {});
          }

          when(
            mockGroupRepository.getGroups(),
          ).thenAnswer((_) async => <GroupModel>[]);
          when(mockTransactionRepository.getTransactions()).thenAnswer(
            (_) async => {
              'transactions': <TransactionModel>[],
              'summary': {'total_paid': 0.0, 'total_owed': 0.0},
            },
          );

          await syncService.sync();

          for (final op in successfulOps) {
            verify(mockSyncQueueDataSource.remove(op.id!)).called(1);
            verifyNever(mockSyncQueueDataSource.incrementRetry(op.id!));
          }

          for (final op in failedOps) {
            verifyNever(mockSyncQueueDataSource.remove(op.id!));
            verify(mockSyncQueueDataSource.incrementRetry(op.id!)).called(1);
          }
        }
      },
    );

    test('sync does not run when offline', () async {
      for (int i = 0; i < 50; i++) {
        reset(mockNetworkInfo);
        reset(mockSyncQueueDataSource);
        reset(mockSyncRemoteDataSource);
        reset(mockGroupRepository);
        reset(mockBillRepository);
        reset(mockTransactionRepository);

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        await syncService.sync();

        verifyNever(mockSyncQueueDataSource.getAll());
        verifyNever(
          mockSyncRemoteDataSource.batchSync(
            operations: anyNamed('operations'),
          ),
        );
        verifyNever(mockGroupRepository.getGroups());
        verifyNever(mockTransactionRepository.getTransactions());
      }
    });

    test(
      'empty queue does not trigger batch sync but still pulls server data',
      () async {
        for (int i = 0; i < 50; i++) {
          reset(mockNetworkInfo);
          reset(mockSyncQueueDataSource);
          reset(mockSyncRemoteDataSource);
          reset(mockGroupRepository);
          reset(mockBillRepository);
          reset(mockTransactionRepository);

          when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
          when(mockSyncQueueDataSource.getAll()).thenAnswer((_) async => []);
          when(
            mockGroupRepository.getGroups(),
          ).thenAnswer((_) async => <GroupModel>[]);
          when(mockTransactionRepository.getTransactions()).thenAnswer(
            (_) async => {
              'transactions': <TransactionModel>[],
              'summary': {'total_paid': 0.0, 'total_owed': 0.0},
            },
          );

          await syncService.sync();

          verify(mockSyncQueueDataSource.getAll()).called(1);
          verifyNever(
            mockSyncRemoteDataSource.batchSync(
              operations: anyNamed('operations'),
            ),
          );
          verify(mockGroupRepository.getGroups()).called(2);
          verify(mockTransactionRepository.getTransactions()).called(1);
        }
      },
    );
  });
}
