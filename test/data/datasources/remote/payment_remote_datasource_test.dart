import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/data/datasources/remote/payment_remote_datasource.dart';

@GenerateMocks([ApiClient])
import 'payment_remote_datasource_test.mocks.dart';

void main() {
  late PaymentRemoteDataSource dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = PaymentRemoteDataSource(apiClient: mockApiClient);
  });

  group('PaymentRemoteDataSource - initiatePayment', () {
    test('should call POST /api/shares/{id}/pay with GCash', () async {
      // Arrange
      final mockResponse = {
        'payment_intent': {
          'id': 'pi_test_123',
          'client_key': 'client_key_123',
          'status': 'awaiting_payment_method',
        },
        'checkout_url': 'https://checkout.paymongo.com/test',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.initiatePayment(
        shareId: 1,
        paymentMethod: 'gcash',
      );

      // Assert
      verify(
        mockApiClient.post('/api/shares/1/pay', {'payment_method': 'gcash'}),
      ).called(1);
      expect(result.paymentIntent.id, 'pi_test_123');
      expect(result.checkoutUrl, 'https://checkout.paymongo.com/test');
    });

    test('should call POST /api/shares/{id}/pay with PayMaya', () async {
      // Arrange
      final mockResponse = {
        'payment_intent': {
          'id': 'pi_test_456',
          'client_key': 'client_key_456',
          'status': 'awaiting_payment_method',
        },
        'checkout_url': 'https://checkout.paymongo.com/test2',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.initiatePayment(
        shareId: 2,
        paymentMethod: 'paymaya',
      );

      // Assert
      verify(
        mockApiClient.post('/api/shares/2/pay', {'payment_method': 'paymaya'}),
      ).called(1);
      expect(result.paymentIntent.id, 'pi_test_456');
      expect(result.checkoutUrl, 'https://checkout.paymongo.com/test2');
    });

    test('should parse payment intent correctly', () async {
      // Arrange
      final mockResponse = {
        'payment_intent': {
          'id': 'pi_abc123',
          'client_key': 'ck_xyz789',
          'status': 'awaiting_payment_method',
        },
        'checkout_url': 'https://checkout.paymongo.com/abc',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.initiatePayment(
        shareId: 5,
        paymentMethod: 'gcash',
      );

      // Assert
      expect(result.paymentIntent.id, 'pi_abc123');
      expect(result.paymentIntent.clientKey, 'ck_xyz789');
      expect(result.paymentIntent.status, 'awaiting_payment_method');
    });

    test('should parse checkout URL correctly', () async {
      // Arrange
      final mockResponse = {
        'payment_intent': {
          'id': 'pi_test',
          'client_key': 'ck_test',
          'status': 'awaiting_payment_method',
        },
        'checkout_url': 'https://checkout.paymongo.com/custom-url',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.initiatePayment(
        shareId: 10,
        paymentMethod: 'paymaya',
      );

      // Assert
      expect(result.checkoutUrl, 'https://checkout.paymongo.com/custom-url');
    });
  });

  group('PaymentRemoteDataSource - error handling', () {
    test('should throw ApiException on 401 unauthenticated', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Unauthenticated', statusCode: 401));

      // Act & Assert
      expect(
        () => dataSource.initiatePayment(shareId: 1, paymentMethod: 'gcash'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('should throw ApiException on 403 forbidden', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Forbidden', statusCode: 403));

      // Act & Assert
      expect(
        () => dataSource.initiatePayment(shareId: 1, paymentMethod: 'gcash'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('should throw ApiException on 404 share not found', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Share not found', statusCode: 404));

      // Act & Assert
      expect(
        () => dataSource.initiatePayment(shareId: 999, paymentMethod: 'gcash'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('should throw ApiException on 422 validation error', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Validation error', statusCode: 422));

      // Act & Assert
      expect(
        () => dataSource.initiatePayment(
          shareId: 1,
          paymentMethod: 'invalid_method',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('should throw ApiException on 500 server error', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Server error', statusCode: 500));

      // Act & Assert
      expect(
        () => dataSource.initiatePayment(shareId: 1, paymentMethod: 'gcash'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('should throw NetworkException on network error', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(NetworkException('Connection failed'));

      // Act & Assert
      expect(
        () => dataSource.initiatePayment(shareId: 1, paymentMethod: 'gcash'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw ApiException on PayMongo API error', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('PayMongo API error', statusCode: 502));

      // Act & Assert
      expect(
        () => dataSource.initiatePayment(shareId: 1, paymentMethod: 'gcash'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });
  });

  group('PaymentRemoteDataSource - payment methods', () {
    test('should support GCash payment method', () async {
      // Arrange
      final mockResponse = {
        'payment_intent': {
          'id': 'pi_gcash',
          'client_key': 'ck_gcash',
          'status': 'awaiting_payment_method',
        },
        'checkout_url': 'https://checkout.paymongo.com/gcash',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.initiatePayment(
        shareId: 1,
        paymentMethod: 'gcash',
      );

      // Assert
      expect(result.paymentIntent.id, 'pi_gcash');
      verify(
        mockApiClient.post('/api/shares/1/pay', {'payment_method': 'gcash'}),
      ).called(1);
    });

    test('should support PayMaya payment method', () async {
      // Arrange
      final mockResponse = {
        'payment_intent': {
          'id': 'pi_paymaya',
          'client_key': 'ck_paymaya',
          'status': 'awaiting_payment_method',
        },
        'checkout_url': 'https://checkout.paymongo.com/paymaya',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.initiatePayment(
        shareId: 1,
        paymentMethod: 'paymaya',
      );

      // Assert
      expect(result.paymentIntent.id, 'pi_paymaya');
      verify(
        mockApiClient.post('/api/shares/1/pay', {'payment_method': 'paymaya'}),
      ).called(1);
    });
  });
}
