import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/presentation/viewmodels/auth_viewmodel.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/services/services.dart';

import 'viewmodels_test.mocks.dart';

@GenerateMocks([AuthRepository, NotificationService])
void main() {
  group('AuthViewModel Tests', () {
    late AuthViewModel viewModel;
    late MockAuthRepository mockRepository;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockRepository = MockAuthRepository();
      mockNotificationService = MockNotificationService();
      viewModel = AuthViewModel(
        repository: mockRepository,
        notificationService: mockNotificationService,
      );
    });

    test('initial state is correct', () {
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.isAuthenticated, isFalse);
    });

    test('initialize loads current user when authenticated', () async {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockRepository.isAuthenticated()).thenAnswer((_) async => true);
      when(mockRepository.getCurrentUser()).thenAnswer((_) async => user);

      await viewModel.initialize();

      expect(viewModel.currentUser, equals(user));
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.isAuthenticated, isTrue);
    });

    test('initialize sets loading state correctly', () async {
      when(mockRepository.isAuthenticated()).thenAnswer((_) async => false);

      bool loadingDuringOperation = false;
      viewModel.addListener(() {
        if (viewModel.isLoading) {
          loadingDuringOperation = true;
        }
      });

      await viewModel.initialize();

      expect(loadingDuringOperation, isTrue);
      expect(viewModel.isLoading, isFalse);
    });

    test('initialize handles errors correctly', () async {
      when(
        mockRepository.isAuthenticated(),
      ).thenThrow(Exception('Network error'));

      await viewModel.initialize();

      expect(viewModel.error, contains('Network error'));
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.currentUser, isNull);
    });

    test('register succeeds with valid credentials', () async {
      final user = UserModel(
        id: 1,
        username: 'newuser',
        email: 'new@example.com',
        createdAt: DateTime.now(),
      );

      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn('device_id_123');
      when(
        mockRepository.register(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          passwordConfirmation: anyNamed('passwordConfirmation'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenAnswer((_) async => user);

      final result = await viewModel.register(
        username: 'newuser',
        email: 'new@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(result, isTrue);
      expect(viewModel.currentUser, equals(user));
      expect(viewModel.error, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('register notifies listeners during operation', () async {
      final user = UserModel(
        id: 1,
        username: 'newuser',
        email: 'new@example.com',
        createdAt: DateTime.now(),
      );

      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn('device_id_123');
      when(
        mockRepository.register(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          passwordConfirmation: anyNamed('passwordConfirmation'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenAnswer((_) async => user);

      int notifyCount = 0;
      viewModel.addListener(() {
        notifyCount++;
      });

      await viewModel.register(
        username: 'newuser',
        email: 'new@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('register fails when FCM token is null', () async {
      when(mockNotificationService.fcmToken).thenReturn(null);
      when(mockNotificationService.deviceId).thenReturn('device_id_123');

      final result = await viewModel.register(
        username: 'newuser',
        email: 'new@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(result, isFalse);
      expect(viewModel.error, contains('FCM token'));
      expect(viewModel.currentUser, isNull);
    });

    test('register handles repository errors', () async {
      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn('device_id_123');
      when(
        mockRepository.register(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          passwordConfirmation: anyNamed('passwordConfirmation'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenThrow(Exception('Registration failed'));

      final result = await viewModel.register(
        username: 'newuser',
        email: 'new@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(result, isFalse);
      expect(viewModel.error, contains('Registration failed'));
      expect(viewModel.isLoading, isFalse);
    });

    test('login succeeds with valid credentials', () async {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn('device_id_123');
      when(
        mockRepository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenAnswer((_) async => user);

      final result = await viewModel.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(viewModel.currentUser, equals(user));
      expect(viewModel.error, isNull);
      expect(viewModel.isAuthenticated, isTrue);
    });

    test('login fails when device ID is null', () async {
      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn(null);

      final result = await viewModel.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isFalse);
      expect(viewModel.error, contains('device ID'));
      expect(viewModel.currentUser, isNull);
    });

    test('login handles repository errors', () async {
      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn('device_id_123');
      when(
        mockRepository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenThrow(Exception('Invalid credentials'));

      final result = await viewModel.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(result, isFalse);
      expect(viewModel.error, contains('Invalid credentials'));
    });

    test('logout clears current user', () async {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn('device_id_123');
      when(
        mockRepository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenAnswer((_) async => user);
      when(mockRepository.logout()).thenAnswer((_) async {});

      await viewModel.login(email: 'test@example.com', password: 'password123');

      final result = await viewModel.logout();

      expect(result, isTrue);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.error, isNull);
    });

    test('logout handles errors', () async {
      when(mockRepository.logout()).thenThrow(Exception('Logout failed'));

      final result = await viewModel.logout();

      expect(result, isFalse);
      expect(viewModel.error, contains('Logout failed'));
    });

    test('clearError removes error message', () async {
      when(mockNotificationService.fcmToken).thenReturn('fcm_token_123');
      when(mockNotificationService.deviceId).thenReturn('device_id_123');
      when(
        mockRepository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenThrow(Exception('Login failed'));

      await viewModel.login(email: 'test@example.com', password: 'password123');

      viewModel.clearError();

      expect(viewModel.error, isNull);
    });
  });
}
