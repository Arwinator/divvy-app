import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/data/datasources/remote/bill_remote_datasource.dart';
import 'package:divvy/data/models/models.dart';

@GenerateMocks([ApiClient])
import 'bill_remote_datasource_test.mocks.dart';

void main() {
  late BillRemoteDataSource dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = BillRemoteDataSource(apiClient: mockApiClient);
  });

  group('BillRemoteDataSource - createBill', () {
    test('should call POST /api/bills with equal split', () async {
      // Arrange
      final mockResponse = {
        'id': 1,
        'group_id': 1,
        'creator_id': 1,
        'title': 'Dinner',
        'total_amount': 1500.0,
        'bill_date': '2024-01-01',
        'split_type': 'equal',
        'created_at': '2024-01-01T00:00:00.000000Z',
        'shares': [],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.createBill(
        groupId: 1,
        title: 'Dinner',
        totalAmount: 1500.0,
        billDate: DateTime(2024, 1, 1),
        splitType: 'equal',
      );

      // Assert
      verify(
        mockApiClient.post('/api/bills', {
          'group_id': 1,
          'title': 'Dinner',
          'total_amount': 1500.0,
          'bill_date': '2024-01-01',
          'split_type': 'equal',
        }),
      ).called(1);
      expect(result.id, 1);
      expect(result.title, 'Dinner');
    });

    test('should call POST /api/bills with custom split', () async {
      // Arrange
      final mockResponse = {
        'id': 2,
        'group_id': 1,
        'creator_id': 1,
        'title': 'Groceries',
        'total_amount': 2000.0,
        'bill_date': '2024-01-02',
        'split_type': 'custom',
        'created_at': '2024-01-02T00:00:00.000000Z',
        'shares': [],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      final shares = [
        {'user_id': 1, 'amount': 1000.0},
        {'user_id': 2, 'amount': 1000.0},
      ];

      // Act
      final result = await dataSource.createBill(
        groupId: 1,
        title: 'Groceries',
        totalAmount: 2000.0,
        billDate: DateTime(2024, 1, 2),
        splitType: 'custom',
        shares: shares,
      );

      // Assert
      verify(
        mockApiClient.post('/api/bills', {
          'group_id': 1,
          'title': 'Groceries',
          'total_amount': 2000.0,
          'bill_date': '2024-01-02',
          'split_type': 'custom',
          'shares': shares,
        }),
      ).called(1);
      expect(result.id, 2);
      expect(result.title, 'Groceries');
    });

    test('should parse response correctly', () async {
      // Arrange
      final mockResponse = {
        'id': 10,
        'group_id': 5,
        'creator_id': 3,
        'title': 'Movie Night',
        'total_amount': 800.0,
        'bill_date': '2024-03-15',
        'split_type': 'equal',
        'created_at': '2024-03-15T10:30:00.000000Z',
        'shares': [],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.createBill(
        groupId: 5,
        title: 'Movie Night',
        totalAmount: 800.0,
        billDate: DateTime(2024, 3, 15),
        splitType: 'equal',
      );

      // Assert
      expect(result.id, 10);
      expect(result.groupId, 5);
      expect(result.totalAmount, 800.0);
    });

    test('should throw ApiException on validation error', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Validation error', statusCode: 422));

      // Act & Assert
      expect(
        () => dataSource.createBill(
          groupId: 1,
          title: '',
          totalAmount: -100.0,
          billDate: DateTime(2024, 1, 1),
          splitType: 'equal',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });
  });

  group('BillRemoteDataSource - getBills', () {
    test('should call GET /api/bills without filters', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'group_id': 1,
            'creator_id': 1,
            'title': 'Bill 1',
            'total_amount': 1000.0,
            'bill_date': '2024-01-01',
            'split_type': 'equal',
            'created_at': '2024-01-01T00:00:00.000000Z',
            'shares': [],
          },
        ],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getBills();

      // Assert
      verify(mockApiClient.get('/api/bills')).called(1);
      expect(result.length, 1);
      expect(result[0].title, 'Bill 1');
    });

    test('should call GET /api/bills with group filter', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'group_id': 5,
            'creator_id': 1,
            'title': 'Filtered Bill',
            'total_amount': 1500.0,
            'bill_date': '2024-01-01',
            'split_type': 'equal',
            'created_at': '2024-01-01T00:00:00.000000Z',
            'shares': [],
          },
        ],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getBills(groupId: 5);

      // Assert
      verify(mockApiClient.get('/api/bills?group_id=5')).called(1);
      expect(result[0].groupId, 5);
    });

    test('should call GET /api/bills with date range filters', () async {
      // Arrange
      final mockResponse = {'data': []};

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getBills(
        fromDate: DateTime(2024, 1, 1),
        toDate: DateTime(2024, 1, 31),
      );

      // Assert
      verify(
        mockApiClient.get('/api/bills?from_date=2024-01-01&to_date=2024-01-31'),
      ).called(1);
    });

    test('should call GET /api/bills with all filters', () async {
      // Arrange
      final mockResponse = {'data': []};

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getBills(
        groupId: 3,
        fromDate: DateTime(2024, 2, 1),
        toDate: DateTime(2024, 2, 28),
      );

      // Assert
      verify(
        mockApiClient.get(
          '/api/bills?group_id=3&from_date=2024-02-01&to_date=2024-02-28',
        ),
      ).called(1);
    });
  });

  group('BillRemoteDataSource - getBillById', () {
    test('should call GET /api/bills/{id}', () async {
      // Arrange
      final mockResponse = {
        'id': 1,
        'group_id': 1,
        'creator_id': 1,
        'title': 'Specific Bill',
        'total_amount': 2000.0,
        'bill_date': '2024-01-01',
        'split_type': 'equal',
        'created_at': '2024-01-01T00:00:00.000000Z',
        'shares': [],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getBillById(billId: 1);

      // Assert
      verify(mockApiClient.get('/api/bills/1')).called(1);
      expect(result.id, 1);
      expect(result.title, 'Specific Bill');
    });

    test('should parse bill with shares correctly', () async {
      // Arrange
      final mockResponse = {
        'id': 5,
        'group_id': 2,
        'creator_id': 1,
        'title': 'Bill with Shares',
        'total_amount': 3000.0,
        'bill_date': '2024-03-15',
        'split_type': 'custom',
        'created_at': '2024-03-15T10:30:00.000000Z',
        'shares': [
          {
            'id': 1,
            'bill_id': 5,
            'user_id': 1,
            'amount': 1500.0,
            'status': 'unpaid',
            'user': {
              'id': 1,
              'username': 'user1',
              'email': 'user1@example.com',
              'created_at': '2024-01-01T00:00:00.000000Z',
            },
          },
          {
            'id': 2,
            'bill_id': 5,
            'user_id': 2,
            'amount': 1500.0,
            'status': 'paid',
            'user': {
              'id': 2,
              'username': 'user2',
              'email': 'user2@example.com',
              'created_at': '2024-01-01T00:00:00.000000Z',
            },
          },
        ],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getBillById(billId: 5);

      // Assert
      expect(result.id, 5);
      expect(result.shares.length, 2);
      expect(result.shares[0].amount, 1500.0);
      expect(result.shares[1].status, ShareStatus.paid);
    });

    test('should throw ApiException on not found', () async {
      // Arrange
      when(
        mockApiClient.get(any),
      ).thenThrow(ApiException('Bill not found', statusCode: 404));

      // Act & Assert
      expect(
        () => dataSource.getBillById(billId: 999),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('BillRemoteDataSource - error handling', () {
    test('should throw NetworkException on network error', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(NetworkException('Connection failed'));

      // Act & Assert
      expect(
        () => dataSource.createBill(
          groupId: 1,
          title: 'Test',
          totalAmount: 100.0,
          billDate: DateTime(2024, 1, 1),
          splitType: 'equal',
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw ApiException on 403 forbidden', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Forbidden', statusCode: 403));

      // Act & Assert
      expect(
        () => dataSource.createBill(
          groupId: 1,
          title: 'Test',
          totalAmount: 100.0,
          billDate: DateTime(2024, 1, 1),
          splitType: 'equal',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });
}
