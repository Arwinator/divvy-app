import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late TestDatabaseHelper databaseHelper;
  late SyncQueueLocalDataSource dataSource;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await createTestDatabase();
    databaseHelper = TestDatabaseHelper(db);
    dataSource = SyncQueueLocalDataSource(databaseHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncQueueLocalDataSource - Add Operations', () {
    test('addOperation inserts operation into queue', () async {
      final operation = SyncOperation(
        operationType: 'create_group',
        endpoint: '/api/groups',
        payload: {'name': 'Test Group'},
        createdAt: DateTime.now(),
      );

      final id = await dataSource.addOperation(operation);

      expect(id, isPositive);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations.length, 1);
      expect(operations[0]['operation_type'], 'create_group');
      expect(operations[0]['endpoint'], '/api/groups');
    });

    test('addOperation stores payload as JSON string', () async {
      final operation = SyncOperation(
        operationType: 'create_bill',
        endpoint: '/api/bills',
        payload: {
          'title': 'Test Bill',
          'amount': 1000.0,
          'shares': [
            {'user_id': 1, 'amount': 500.0},
            {'user_id': 2, 'amount': 500.0},
          ],
        },
        createdAt: DateTime.now(),
      );

      await dataSource.addOperation(operation);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations[0]['payload'], isA<String>());
      expect(operations[0]['payload'], contains('Test Bill'));
    });

    test('addOperation sets default retry count to 0', () async {
      final operation = SyncOperation(
        operationType: 'create_group',
        endpoint: '/api/groups',
        payload: {'name': 'Test Group'},
        createdAt: DateTime.now(),
      );

      await dataSource.addOperation(operation);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations[0]['retry_count'], 0);
    });

    test('addOperation can set custom retry count', () async {
      final operation = SyncOperation(
        operationType: 'create_group',
        endpoint: '/api/groups',
        payload: {'name': 'Test Group'},
        retryCount: 3,
        createdAt: DateTime.now(),
      );

      await dataSource.addOperation(operation);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations[0]['retry_count'], 3);
    });
  });

  group('SyncQueueLocalDataSource - Get Operations', () {
    test('getAll returns all operations in queue', () async {
      for (int i = 1; i <= 3; i++) {
        await dataSource.addOperation(
          SyncOperation(
            operationType: 'create_group',
            endpoint: '/api/groups',
            payload: {'name': 'Group $i'},
            createdAt: DateTime.now(),
          ),
        );
      }

      final operations = await dataSource.getAll();

      expect(operations.length, 3);
    });

    test('getAll returns empty list when queue is empty', () async {
      final operations = await dataSource.getAll();

      expect(operations, isEmpty);
    });

    test(
      'getAll returns operations ordered by creation time (oldest first)',
      () async {
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(hours: 2));
        final latest = now.add(const Duration(hours: 1));

        await dataSource.addOperation(
          SyncOperation(
            operationType: 'create_group',
            endpoint: '/api/groups',
            payload: {'name': 'Group 2'},
            createdAt: now,
          ),
        );

        await dataSource.addOperation(
          SyncOperation(
            operationType: 'create_group',
            endpoint: '/api/groups',
            payload: {'name': 'Group 1'},
            createdAt: earlier,
          ),
        );

        await dataSource.addOperation(
          SyncOperation(
            operationType: 'create_group',
            endpoint: '/api/groups',
            payload: {'name': 'Group 3'},
            createdAt: latest,
          ),
        );

        final operations = await dataSource.getAll();

        expect(operations[0].payload['name'], 'Group 1');
        expect(operations[1].payload['name'], 'Group 2');
        expect(operations[2].payload['name'], 'Group 3');
      },
    );

    test('getAll parses payload JSON correctly', () async {
      final operation = SyncOperation(
        operationType: 'create_bill',
        endpoint: '/api/bills',
        payload: {
          'title': 'Test Bill',
          'amount': 1000.0,
          'shares': [
            {'user_id': 1, 'amount': 500.0},
            {'user_id': 2, 'amount': 500.0},
          ],
        },
        createdAt: DateTime.now(),
      );

      await dataSource.addOperation(operation);

      final operations = await dataSource.getAll();

      expect(operations[0].payload['title'], 'Test Bill');
      expect(operations[0].payload['amount'], 1000.0);
      expect(operations[0].payload['shares'], isA<List>());
      expect(operations[0].payload['shares'].length, 2);
    });
  });

  group('SyncQueueLocalDataSource - Remove Operations', () {
    test('remove deletes operation from queue', () async {
      final id = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test Group'},
          createdAt: DateTime.now(),
        ),
      );

      await dataSource.remove(id);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations, isEmpty);
    });

    test('remove does not affect other operations', () async {
      final id1 = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Group 1'},
          createdAt: DateTime.now(),
        ),
      );

      final id2 = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Group 2'},
          createdAt: DateTime.now(),
        ),
      );

      await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Group 3'},
          createdAt: DateTime.now(),
        ),
      );

      await dataSource.remove(id2);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations.length, 2);
      expect(operations.any((o) => o['id'] == id1), isTrue);
      expect(operations.any((o) => o['id'] == id2), isFalse);
    });

    test('remove succeeds even when operation does not exist', () async {
      await dataSource.remove(999);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations, isEmpty);
    });
  });

  group('SyncQueueLocalDataSource - Increment Retry Operations', () {
    test('incrementRetry increases retry count by 1', () async {
      final id = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test Group'},
          createdAt: DateTime.now(),
        ),
      );

      await dataSource.incrementRetry(id);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations[0]['retry_count'], 1);
    });

    test('incrementRetry can be called multiple times', () async {
      final id = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test Group'},
          createdAt: DateTime.now(),
        ),
      );

      await dataSource.incrementRetry(id);
      await dataSource.incrementRetry(id);
      await dataSource.incrementRetry(id);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations[0]['retry_count'], 3);
    });

    test('incrementRetry does not affect other operations', () async {
      final id1 = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Group 1'},
          createdAt: DateTime.now(),
        ),
      );

      final id2 = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Group 2'},
          createdAt: DateTime.now(),
        ),
      );

      await dataSource.incrementRetry(id1);

      final operations = await databaseHelper.query('sync_queue');
      expect(operations.firstWhere((o) => o['id'] == id1)['retry_count'], 1);
      expect(operations.firstWhere((o) => o['id'] == id2)['retry_count'], 0);
    });

    test(
      'incrementRetry succeeds silently when operation does not exist',
      () async {
        await dataSource.incrementRetry(999);

        final operations = await databaseHelper.query('sync_queue');
        expect(operations, isEmpty);
      },
    );
  });

  group('SyncQueueLocalDataSource - Edge Cases', () {
    test('addOperation handles complex nested payload', () async {
      final operation = SyncOperation(
        operationType: 'create_bill',
        endpoint: '/api/bills',
        payload: {
          'title': 'Complex Bill',
          'metadata': {
            'tags': ['food', 'dinner'],
            'location': {'lat': 14.5995, 'lng': 120.9842},
          },
          'shares': [
            {'user_id': 1, 'amount': 333.33},
            {'user_id': 2, 'amount': 333.33},
            {'user_id': 3, 'amount': 333.34},
          ],
        },
        createdAt: DateTime.now(),
      );

      await dataSource.addOperation(operation);

      final operations = await dataSource.getAll();
      expect(operations[0].payload['metadata']['tags'], isA<List>());
      expect(operations[0].payload['metadata']['location']['lat'], 14.5995);
    });

    test('addOperation handles special characters in payload', () async {
      final operation = SyncOperation(
        operationType: 'create_group',
        endpoint: '/api/groups',
        payload: {
          'name': "Group with 'quotes' and \"double quotes\"",
          'description': 'Special chars: @#\$%^&*()',
        },
        createdAt: DateTime.now(),
      );

      await dataSource.addOperation(operation);

      final operations = await dataSource.getAll();
      expect(
        operations[0].payload['name'],
        "Group with 'quotes' and \"double quotes\"",
      );
      expect(operations[0].payload['description'], 'Special chars: @#\$%^&*()');
    });

    test('getAll handles empty payload', () async {
      final operation = SyncOperation(
        operationType: 'sync',
        endpoint: '/api/sync',
        payload: {},
        createdAt: DateTime.now(),
      );

      await dataSource.addOperation(operation);

      final operations = await dataSource.getAll();
      expect(operations[0].payload, isEmpty);
    });

    test('SyncOperation fromMap and toMap are inverse operations', () async {
      final original = SyncOperation(
        id: 1,
        operationType: 'create_group',
        endpoint: '/api/groups',
        payload: {'name': 'Test Group', 'creator_id': 1},
        retryCount: 2,
        createdAt: DateTime.now(),
      );

      final map = original.toMap();
      final reconstructed = SyncOperation.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.operationType, original.operationType);
      expect(reconstructed.endpoint, original.endpoint);
      expect(reconstructed.payload['name'], original.payload['name']);
      expect(reconstructed.retryCount, original.retryCount);
    });
  });

  group('SyncQueueLocalDataSource - Workflow Scenarios', () {
    test('typical sync workflow: add, get, increment retry, remove', () async {
      final operation = SyncOperation(
        operationType: 'create_group',
        endpoint: '/api/groups',
        payload: {'name': 'Test Group'},
        createdAt: DateTime.now(),
      );

      final id = await dataSource.addOperation(operation);

      var operations = await dataSource.getAll();
      expect(operations.length, 1);
      expect(operations[0].retryCount, 0);

      await dataSource.incrementRetry(id);

      operations = await dataSource.getAll();
      expect(operations[0].retryCount, 1);

      await dataSource.remove(id);

      operations = await dataSource.getAll();
      expect(operations, isEmpty);
    });

    test('multiple operations processed in FIFO order', () async {
      final now = DateTime.now();

      for (int i = 1; i <= 5; i++) {
        await dataSource.addOperation(
          SyncOperation(
            operationType: 'create_group',
            endpoint: '/api/groups',
            payload: {'name': 'Group $i'},
            createdAt: now.add(Duration(seconds: i)),
          ),
        );
      }

      final operations = await dataSource.getAll();

      for (int i = 0; i < 5; i++) {
        expect(operations[i].payload['name'], 'Group ${i + 1}');
      }
    });

    test('failed operations can be retried up to max attempts', () async {
      final id = await dataSource.addOperation(
        SyncOperation(
          operationType: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test Group'},
          createdAt: DateTime.now(),
        ),
      );

      const maxRetries = 3;

      for (int i = 0; i < maxRetries; i++) {
        await dataSource.incrementRetry(id);
      }

      final operations = await dataSource.getAll();
      expect(operations[0].retryCount, maxRetries);

      await dataSource.remove(id);

      final remainingOperations = await dataSource.getAll();
      expect(remainingOperations, isEmpty);
    });
  });
}
