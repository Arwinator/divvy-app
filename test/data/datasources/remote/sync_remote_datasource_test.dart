import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/data/datasources/remote/sync_remote_datasource.dart';

@GenerateMocks([ApiClient])
import 'sync_remote_datasource_test.mocks.dart';

void main() {
  late SyncRemoteDataSource dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = SyncRemoteDataSource(apiClient: mockApiClient);
  });

  group('SyncRemoteDataSource - batchSync', () {
    test('should call POST /api/sync with operations', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test Group'},
          localId: 'local_1',
        ),
      ];

      final mockResponse = {
        'results': [
          {'success': true, 'local_id': 'local_1', 'server_id': 1},
        ],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.batchSync(operations: operations);

      // Assert
      verify(
        mockApiClient.post('/api/sync', {
          'operations': [
            {
              'type': 'create_group',
              'endpoint': '/api/groups',
              'payload': {'name': 'Test Group'},
              'local_id': 'local_1',
            },
          ],
        }),
      ).called(1);
      expect(result.results.length, 1);
      expect(result.results[0].success, true);
    });

    test('should handle multiple operations', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Group 1'},
          localId: 'local_1',
        ),
        SyncOperation(
          type: 'create_bill',
          endpoint: '/api/bills',
          payload: {'group_id': 1, 'title': 'Bill 1', 'total_amount': 1000.0},
          localId: 'local_2',
        ),
      ];

      final mockResponse = {
        'results': [
          {'success': true, 'local_id': 'local_1', 'server_id': 1},
          {'success': true, 'local_id': 'local_2', 'server_id': 5},
        ],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.batchSync(operations: operations);

      // Assert
      expect(result.results.length, 2);
      expect(result.results[0].serverId, 1);
      expect(result.results[1].serverId, 5);
    });

    test('should parse successful operation results', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Success Group'},
          localId: 'local_success',
        ),
      ];

      final mockResponse = {
        'results': [
          {'success': true, 'local_id': 'local_success', 'server_id': 42},
        ],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.batchSync(operations: operations);

      // Assert
      expect(result.results[0].success, true);
      expect(result.results[0].localId, 'local_success');
      expect(result.results[0].serverId, 42);
      expect(result.results[0].error, null);
    });

    test('should parse failed operation results', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': ''},
          localId: 'local_fail',
        ),
      ];

      final mockResponse = {
        'results': [
          {
            'success': false,
            'local_id': 'local_fail',
            'error': 'Validation error: name is required',
          },
        ],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.batchSync(operations: operations);

      // Assert
      expect(result.results[0].success, false);
      expect(result.results[0].localId, 'local_fail');
      expect(result.results[0].serverId, null);
      expect(result.results[0].error, 'Validation error: name is required');
    });
  });

  group('SyncRemoteDataSource - operation types', () {
    test('should support create_group operation', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'New Group'},
          localId: 'group_1',
        ),
      ];

      final mockResponse = {
        'results': [
          {'success': true, 'local_id': 'group_1', 'server_id': 10},
        ],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.batchSync(operations: operations);

      // Assert
      expect(result.results[0].success, true);
      verify(
        mockApiClient.post('/api/sync', {
          'operations': [
            {
              'type': 'create_group',
              'endpoint': '/api/groups',
              'payload': {'name': 'New Group'},
              'local_id': 'group_1',
            },
          ],
        }),
      ).called(1);
    });

    test('should support create_bill operation', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_bill',
          endpoint: '/api/bills',
          payload: {
            'group_id': 1,
            'title': 'Dinner',
            'total_amount': 1500.0,
            'split_type': 'equal',
          },
          localId: 'bill_1',
        ),
      ];

      final mockResponse = {
        'results': [
          {'success': true, 'local_id': 'bill_1', 'server_id': 20},
        ],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.batchSync(operations: operations);

      // Assert
      expect(result.results[0].success, true);
      verify(
        mockApiClient.post('/api/sync', {
          'operations': [
            {
              'type': 'create_bill',
              'endpoint': '/api/bills',
              'payload': {
                'group_id': 1,
                'title': 'Dinner',
                'total_amount': 1500.0,
                'split_type': 'equal',
              },
              'local_id': 'bill_1',
            },
          ],
        }),
      ).called(1);
    });

    test('should handle operations without local_id', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'No Local ID'},
        ),
      ];

      final mockResponse = {
        'results': [
          {'success': true, 'server_id': 15},
        ],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.batchSync(operations: operations);

      // Assert
      expect(result.results[0].success, true);
      expect(result.results[0].localId, null);
      expect(result.results[0].serverId, 15);
    });
  });

  group('SyncRemoteDataSource - getLastSyncTimestamp', () {
    test('should call GET /api/sync/timestamp', () async {
      // Arrange
      final mockResponse = {'timestamp': '2024-01-01T12:00:00.000000Z'};

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getLastSyncTimestamp();

      // Assert
      verify(mockApiClient.get('/api/sync/timestamp')).called(1);
      expect(result, DateTime.parse('2024-01-01T12:00:00.000000Z'));
    });

    test('should parse timestamp correctly', () async {
      // Arrange
      final mockResponse = {'timestamp': '2024-03-15T10:30:45.123456Z'};

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getLastSyncTimestamp();

      // Assert
      expect(result.year, 2024);
      expect(result.month, 3);
      expect(result.day, 15);
      expect(result.hour, 10);
      expect(result.minute, 30);
    });
  });

  group('SyncRemoteDataSource - error handling', () {
    test('should throw ApiException on 401 unauthenticated', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test'},
        ),
      ];

      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Unauthenticated', statusCode: 401));

      // Act & Assert
      expect(
        () => dataSource.batchSync(operations: operations),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('should throw ApiException on 422 validation error', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'invalid_type',
          endpoint: '/api/invalid',
          payload: {},
        ),
      ];

      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Validation error', statusCode: 422));

      // Act & Assert
      expect(
        () => dataSource.batchSync(operations: operations),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('should throw ApiException on 500 server error', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test'},
        ),
      ];

      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Server error', statusCode: 500));

      // Act & Assert
      expect(
        () => dataSource.batchSync(operations: operations),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('should throw NetworkException on network error', () async {
      // Arrange
      final operations = [
        SyncOperation(
          type: 'create_group',
          endpoint: '/api/groups',
          payload: {'name': 'Test'},
        ),
      ];

      when(
        mockApiClient.post(any, any),
      ).thenThrow(NetworkException('Connection failed'));

      // Act & Assert
      expect(
        () => dataSource.batchSync(operations: operations),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw ApiException on timestamp fetch error', () async {
      // Arrange
      when(
        mockApiClient.get(any),
      ).thenThrow(ApiException('Server error', statusCode: 500));

      // Act & Assert
      expect(
        () => dataSource.getLastSyncTimestamp(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('should throw NetworkException on timestamp network error', () async {
      // Arrange
      when(
        mockApiClient.get(any),
      ).thenThrow(NetworkException('Connection failed'));

      // Act & Assert
      expect(
        () => dataSource.getLastSyncTimestamp(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
