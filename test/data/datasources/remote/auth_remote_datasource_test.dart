import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/data/datasources/remote/auth_remote_datasource.dart';

@GenerateMocks([ApiClient])
import 'auth_remote_datasource_test.mocks.dart';

void main() {
  late AuthRemoteDataSource dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AuthRemoteDataSource(apiClient: mockApiClient);
  });

  group('AuthRemoteDataSource - register', () {
    test('should call POST /api/register with correct parameters', () async {
      // Arrange
      final mockResponse = {
        'user': {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'created_at': '2024-01-01T00:00:00.000000Z',
        },
        'token': 'test_token_123',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.register(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
        fcmToken: 'fcm_token_123',
        deviceId: 'device_123',
      );

      // Assert
      verify(
        mockApiClient.post('/api/register', {
          'username': 'testuser',
          'email': 'test@example.com',
          'password': 'password123',
          'password_confirmation': 'password123',
          'fcm_token': 'fcm_token_123',
          'device_id': 'device_123',
        }),
      ).called(1);

      expect(result.user.id, 1);
      expect(result.user.username, 'testuser');
      expect(result.token, 'test_token_123');
    });

    test('should parse response correctly', () async {
      // Arrange
      final mockResponse = {
        'user': {
          'id': 42,
          'username': 'newuser',
          'email': 'new@example.com',
          'created_at': '2024-03-15T10:30:00.000000Z',
        },
        'token': 'new_token_456',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.register(
        username: 'newuser',
        email: 'new@example.com',
        password: 'pass123',
        passwordConfirmation: 'pass123',
        fcmToken: 'fcm_456',
        deviceId: 'device_456',
      );

      // Assert
      expect(result.user.id, 42);
      expect(result.user.username, 'newuser');
      expect(result.user.email, 'new@example.com');
      expect(result.token, 'new_token_456');
    });

    test('should throw ApiException on 422 validation error', () async {
      // Arrange
      when(mockApiClient.post(any, any)).thenThrow(
        ApiException(
          'Validation error',
          statusCode: 422,
          data: {
            'errors': {
              'email': ['The email has already been taken.'],
            },
          },
        ),
      );

      // Act & Assert
      expect(
        () => dataSource.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123',
          passwordConfirmation: 'password123',
          fcmToken: 'fcm_token',
          deviceId: 'device_id',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
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
        () => dataSource.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123',
          passwordConfirmation: 'password123',
          fcmToken: 'fcm_token',
          deviceId: 'device_id',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('AuthRemoteDataSource - login', () {
    test('should call POST /api/login with correct parameters', () async {
      // Arrange
      final mockResponse = {
        'user': {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'created_at': '2024-01-01T00:00:00.000000Z',
        },
        'token': 'login_token_789',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.login(
        email: 'test@example.com',
        password: 'password123',
        fcmToken: 'fcm_token_789',
        deviceId: 'device_789',
      );

      // Assert
      verify(
        mockApiClient.post('/api/login', {
          'email': 'test@example.com',
          'password': 'password123',
          'fcm_token': 'fcm_token_789',
          'device_id': 'device_789',
        }),
      ).called(1);

      expect(result.user.email, 'test@example.com');
      expect(result.token, 'login_token_789');
    });

    test('should parse response correctly', () async {
      // Arrange
      final mockResponse = {
        'user': {
          'id': 99,
          'username': 'loginuser',
          'email': 'login@example.com',
          'created_at': '2024-02-20T15:45:00.000000Z',
        },
        'token': 'login_token_xyz',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.login(
        email: 'login@example.com',
        password: 'mypassword',
        fcmToken: 'fcm_xyz',
        deviceId: 'device_xyz',
      );

      // Assert
      expect(result.user.id, 99);
      expect(result.user.username, 'loginuser');
      expect(result.token, 'login_token_xyz');
    });

    test('should throw ApiException on 401 invalid credentials', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Invalid credentials', statusCode: 401));

      // Act & Assert
      expect(
        () => dataSource.login(
          email: 'wrong@example.com',
          password: 'wrongpass',
          fcmToken: 'fcm_token',
          deviceId: 'device_id',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('should throw ApiException on 429 rate limit', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Too many requests', statusCode: 429));

      // Act & Assert
      expect(
        () => dataSource.login(
          email: 'test@example.com',
          password: 'password',
          fcmToken: 'fcm_token',
          deviceId: 'device_id',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 429),
        ),
      );
    });
  });

  group('AuthRemoteDataSource - logout', () {
    test('should call POST /api/logout', () async {
      // Arrange
      when(mockApiClient.post(any, any)).thenAnswer((_) async => null);

      // Act
      await dataSource.logout();

      // Assert
      verify(mockApiClient.post('/api/logout', {})).called(1);
    });

    test('should complete successfully on valid response', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenAnswer((_) async => {'message': 'Logged out successfully'});

      // Act & Assert
      expect(() => dataSource.logout(), returnsNormally);
    });

    test('should throw ApiException on 401 unauthenticated', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Unauthenticated', statusCode: 401));

      // Act & Assert
      expect(
        () => dataSource.logout(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('should throw ApiException on 500 server error', () async {
      // Arrange
      when(mockApiClient.post(any, any)).thenThrow(
        ApiException('Server error. Please try again later.', statusCode: 500),
      );

      // Act & Assert
      expect(
        () => dataSource.logout(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
