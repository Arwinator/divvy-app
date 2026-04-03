import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:divvy/data/models/models.dart';

@GenerateMocks([ApiClient])
import 'transaction_remote_datasource_test.mocks.dart';

void main() {
  late TransactionRemoteDataSource dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = TransactionRemoteDataSource(apiClient: mockApiClient);
  });

  group('TransactionRemoteDataSource - getTransactions', () {
    test('should call GET /api/transactions without filters', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'share_id': 1,
            'user_id': 1,
            'amount': 500.0,
            'payment_method': 'gcash',
            'status': 'paid',
            'created_at': '2024-01-01T00:00:00.000000Z',
          },
        ],
        'summary': {'total_paid': 500.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getTransactions();

      // Assert
      verify(mockApiClient.get('/api/transactions')).called(1);
      expect(result.transactions.length, 1);
      expect(result.summary.totalPaid, 500.0);
    });

    test('should call GET /api/transactions with date range', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getTransactions(
        fromDate: DateTime(2024, 1, 1),
        toDate: DateTime(2024, 1, 31),
      );

      // Assert
      verify(
        mockApiClient.get(
          '/api/transactions?from_date=2024-01-01&to_date=2024-01-31',
        ),
      ).called(1);
    });

    test('should call GET /api/transactions with group filter', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getTransactions(groupId: 5);

      // Assert
      verify(mockApiClient.get('/api/transactions?group_id=5')).called(1);
    });

    test('should call GET /api/transactions with all filters', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getTransactions(
        fromDate: DateTime(2024, 2, 1),
        toDate: DateTime(2024, 2, 28),
        groupId: 3,
      );

      // Assert
      verify(
        mockApiClient.get(
          '/api/transactions?from_date=2024-02-01&to_date=2024-02-28&group_id=3',
        ),
      ).called(1);
    });

    test('should parse transactions correctly', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'share_id': 1,
            'user_id': 1,
            'amount': 750.0,
            'payment_method': 'gcash',
            'status': 'paid',
            'created_at': '2024-01-01T00:00:00.000000Z',
          },
          {
            'id': 2,
            'share_id': 2,
            'user_id': 1,
            'amount': 250.0,
            'payment_method': 'paymaya',
            'status': 'pending',
            'created_at': '2024-01-02T00:00:00.000000Z',
          },
        ],
        'summary': {'total_paid': 750.0, 'total_owed': 250.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getTransactions();

      // Assert
      expect(result.transactions.length, 2);
      expect(result.transactions[0].amount, 750.0);
      expect(result.transactions[0].paymentMethod, PaymentMethod.gcash);
      expect(result.transactions[0].status, TransactionStatus.paid);
      expect(result.transactions[1].amount, 250.0);
      expect(result.transactions[1].paymentMethod, PaymentMethod.paymaya);
      expect(result.transactions[1].status, TransactionStatus.pending);
    });
  });

  group('TransactionRemoteDataSource - summary parsing', () {
    test('should parse summary with paid transactions', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 1500.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getTransactions();

      // Assert
      expect(result.summary.totalPaid, 1500.0);
      expect(result.summary.totalOwed, 0.0);
    });

    test('should parse summary with owed transactions', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 500.0, 'total_owed': 1000.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getTransactions();

      // Assert
      expect(result.summary.totalPaid, 500.0);
      expect(result.summary.totalOwed, 1000.0);
    });

    test('should parse summary with zero amounts', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getTransactions();

      // Assert
      expect(result.summary.totalPaid, 0.0);
      expect(result.summary.totalOwed, 0.0);
    });
  });

  group('TransactionRemoteDataSource - filter combinations', () {
    test('should handle from_date only', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getTransactions(fromDate: DateTime(2024, 1, 1));

      // Assert
      verify(
        mockApiClient.get('/api/transactions?from_date=2024-01-01'),
      ).called(1);
    });

    test('should handle to_date only', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getTransactions(toDate: DateTime(2024, 1, 31));

      // Assert
      verify(
        mockApiClient.get('/api/transactions?to_date=2024-01-31'),
      ).called(1);
    });

    test('should handle group_id with from_date', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getTransactions(
        groupId: 2,
        fromDate: DateTime(2024, 3, 1),
      );

      // Assert
      verify(
        mockApiClient.get('/api/transactions?from_date=2024-03-01&group_id=2'),
      ).called(1);
    });

    test('should handle group_id with to_date', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'summary': {'total_paid': 0.0, 'total_owed': 0.0},
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      await dataSource.getTransactions(
        groupId: 4,
        toDate: DateTime(2024, 3, 31),
      );

      // Assert
      verify(
        mockApiClient.get('/api/transactions?to_date=2024-03-31&group_id=4'),
      ).called(1);
    });
  });

  group('TransactionRemoteDataSource - error handling', () {
    test('should throw ApiException on 401 unauthenticated', () async {
      // Arrange
      when(
        mockApiClient.get(any),
      ).thenThrow(ApiException('Unauthenticated', statusCode: 401));

      // Act & Assert
      expect(
        () => dataSource.getTransactions(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('should throw ApiException on 422 validation error', () async {
      // Arrange
      when(
        mockApiClient.get(any),
      ).thenThrow(ApiException('Validation error', statusCode: 422));

      // Act & Assert
      expect(
        () => dataSource.getTransactions(
          fromDate: DateTime(2024, 12, 31),
          toDate: DateTime(2024, 1, 1),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('should throw ApiException on 500 server error', () async {
      // Arrange
      when(
        mockApiClient.get(any),
      ).thenThrow(ApiException('Server error', statusCode: 500));

      // Act & Assert
      expect(
        () => dataSource.getTransactions(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('should throw NetworkException on network error', () async {
      // Arrange
      when(
        mockApiClient.get(any),
      ).thenThrow(NetworkException('Connection failed'));

      // Act & Assert
      expect(
        () => dataSource.getTransactions(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
