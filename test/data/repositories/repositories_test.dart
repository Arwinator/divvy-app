import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';
import 'package:divvy/core/storage/secure_storage.dart';
import 'package:divvy/data/models/models.dart';

import 'repositories_test.mocks.dart';

@GenerateMocks([
  remote.AuthRemoteDataSource,
  remote.GroupRemoteDataSource,
  remote.BillRemoteDataSource,
  remote.PaymentRemoteDataSource,
  remote.TransactionRemoteDataSource,
  local.UserLocalDataSource,
  local.GroupLocalDataSource,
  local.BillLocalDataSource,
  local.TransactionLocalDataSource,
  local.SyncQueueLocalDataSource,
  NetworkInfo,
  SecureStorage,
])
void main() {
  group('AuthRepository Tests', () {
    late AuthRepository repository;
    late MockAuthRemoteDataSource mockRemoteDataSource;
    late MockUserLocalDataSource mockLocalDataSource;
    late MockSecureStorage mockSecureStorage;

    setUp(() {
      mockRemoteDataSource = MockAuthRemoteDataSource();
      mockLocalDataSource = MockUserLocalDataSource();
      mockSecureStorage = MockSecureStorage();

      repository = AuthRepository(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        secureStorage: mockSecureStorage,
      );
    });

    test(
      'register saves user and token locally after successful registration',
      () async {
        // Arrange
        final user = UserModel(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );
        final response = remote.AuthResponse(user: user, token: 'test_token');

        when(
          mockRemoteDataSource.register(
            username: anyNamed('username'),
            email: anyNamed('email'),
            password: anyNamed('password'),
            passwordConfirmation: anyNamed('passwordConfirmation'),
            fcmToken: anyNamed('fcmToken'),
            deviceId: anyNamed('deviceId'),
          ),
        ).thenAnswer((_) async => response);

        when(mockLocalDataSource.saveUser(any)).thenAnswer((_) async => 1);
        when(mockSecureStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockSecureStorage.saveUserId(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123',
          passwordConfirmation: 'password123',
          fcmToken: 'fcm_token',
          deviceId: 'device_id',
        );

        // Assert
        expect(result, equals(user));
        verify(mockLocalDataSource.saveUser(user)).called(1);
        verify(mockSecureStorage.saveToken('test_token')).called(1);
        verify(mockSecureStorage.saveUserId('1')).called(1);
      },
    );

    test('login saves user and token locally after successful login', () async {
      // Arrange
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );
      final response = remote.AuthResponse(user: user, token: 'test_token');

      when(
        mockRemoteDataSource.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fcmToken: anyNamed('fcmToken'),
          deviceId: anyNamed('deviceId'),
        ),
      ).thenAnswer((_) async => response);

      when(mockLocalDataSource.saveUser(any)).thenAnswer((_) async => 1);
      when(mockSecureStorage.saveToken(any)).thenAnswer((_) async {});
      when(mockSecureStorage.saveUserId(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
        fcmToken: 'fcm_token',
        deviceId: 'device_id',
      );

      // Assert
      expect(result, equals(user));
      verify(mockLocalDataSource.saveUser(user)).called(1);
      verify(mockSecureStorage.saveToken('test_token')).called(1);
      verify(mockSecureStorage.saveUserId('1')).called(1);
    });

    test('logout clears local data and secure storage', () async {
      // Arrange
      when(mockRemoteDataSource.logout()).thenAnswer((_) async {});
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => '1');
      when(mockLocalDataSource.deleteUser(any)).thenAnswer((_) async => 1);
      when(mockSecureStorage.clearAll()).thenAnswer((_) async {});

      // Act
      await repository.logout();

      // Assert
      verify(mockRemoteDataSource.logout()).called(1);
      verify(mockLocalDataSource.deleteUser(1)).called(1);
      verify(mockSecureStorage.clearAll()).called(1);
    });

    test('getCurrentUser returns user from local storage', () async {
      // Arrange
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockSecureStorage.getUserId()).thenAnswer((_) async => '1');
      when(mockLocalDataSource.getUser(any)).thenAnswer((_) async => user);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, equals(user));
      verify(mockLocalDataSource.getUser(1)).called(1);
    });

    test('isAuthenticated returns true when token exists', () async {
      // Arrange
      when(mockSecureStorage.getToken()).thenAnswer((_) async => 'test_token');

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isTrue);
    });

    test('isAuthenticated returns false when token is null', () async {
      // Arrange
      when(mockSecureStorage.getToken()).thenAnswer((_) async => null);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isFalse);
    });
  });

  group('GroupRepository Tests - Online/Offline Behavior', () {
    late GroupRepository repository;
    late MockGroupRemoteDataSource mockRemoteDataSource;
    late MockGroupLocalDataSource mockLocalDataSource;
    late MockSyncQueueLocalDataSource mockSyncQueueDataSource;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockRemoteDataSource = MockGroupRemoteDataSource();
      mockLocalDataSource = MockGroupLocalDataSource();
      mockSyncQueueDataSource = MockSyncQueueLocalDataSource();
      mockNetworkInfo = MockNetworkInfo();

      repository = GroupRepository(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        syncQueueDataSource: mockSyncQueueDataSource,
        networkInfo: mockNetworkInfo,
      );
    });

    test('createGroup calls remote and saves locally when online', () async {
      // Arrange
      final group = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: [],
        createdAt: DateTime.now(),
        isSynced: true,
      );

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.createGroup(name: anyNamed('name')),
      ).thenAnswer((_) async => group);
      when(mockLocalDataSource.saveGroup(any)).thenAnswer((_) async => 1);

      // Act
      final result = await repository.createGroup(name: 'Test Group');

      // Assert
      expect(result, equals(group));
      verify(mockRemoteDataSource.createGroup(name: 'Test Group')).called(1);
      verify(mockLocalDataSource.saveGroup(group)).called(1);
      verifyNever(mockSyncQueueDataSource.addOperation(any));
    });

    test('createGroup queues operation when offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        mockSyncQueueDataSource.addOperation(any),
      ).thenAnswer((_) async => 1);

      // Act & Assert
      await expectLater(
        repository.createGroup(name: 'Test Group'),
        throwsA(isA<Exception>()),
      );

      verify(mockSyncQueueDataSource.addOperation(any)).called(1);
      verifyNever(mockRemoteDataSource.createGroup(name: anyNamed('name')));
    });

    test(
      'getGroups returns remote data and updates cache when online',
      () async {
        // Arrange
        final groups = [
          GroupModel(
            id: 1,
            name: 'Group 1',
            creatorId: 1,
            members: [],
            createdAt: DateTime.now(),
            isSynced: true,
          ),
          GroupModel(
            id: 2,
            name: 'Group 2',
            creatorId: 1,
            members: [],
            createdAt: DateTime.now(),
            isSynced: true,
          ),
        ];

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getGroups()).thenAnswer((_) async => groups);
        when(mockLocalDataSource.saveGroup(any)).thenAnswer((_) async => 1);

        // Act
        final result = await repository.getGroups();

        // Assert
        expect(result, equals(groups));
        verify(mockRemoteDataSource.getGroups()).called(1);
        verify(mockLocalDataSource.saveGroup(any)).called(2);
      },
    );

    test('getGroups returns cached data when offline', () async {
      // Arrange
      final cachedGroups = [
        GroupModel(
          id: 1,
          name: 'Cached Group',
          creatorId: 1,
          members: [],
          createdAt: DateTime.now(),
          isSynced: false,
        ),
      ];

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        mockLocalDataSource.getGroups(),
      ).thenAnswer((_) async => cachedGroups);

      // Act
      final result = await repository.getGroups();

      // Assert
      expect(result, equals(cachedGroups));
      verify(mockLocalDataSource.getGroups()).called(1);
      verifyNever(mockRemoteDataSource.getGroups());
    });

    test('getGroups returns cached data when remote fails', () async {
      // Arrange
      final cachedGroups = [
        GroupModel(
          id: 1,
          name: 'Cached Group',
          creatorId: 1,
          members: [],
          createdAt: DateTime.now(),
          isSynced: false,
        ),
      ];

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.getGroups(),
      ).thenThrow(Exception('Network error'));
      when(
        mockLocalDataSource.getGroups(),
      ).thenAnswer((_) async => cachedGroups);

      // Act
      final result = await repository.getGroups();

      // Assert
      expect(result, equals(cachedGroups));
      verify(mockRemoteDataSource.getGroups()).called(1);
      verify(mockLocalDataSource.getGroups()).called(1);
    });

    test('sendInvitation throws exception when offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act & Assert
      expect(
        () => repository.sendInvitation(
          groupId: 1,
          identifier: 'user@example.com',
        ),
        throwsA(isA<Exception>()),
      );

      verifyNever(
        mockRemoteDataSource.sendInvitation(
          groupId: anyNamed('groupId'),
          identifier: anyNamed('identifier'),
        ),
      );
    });

    test('sendInvitation calls remote when online', () async {
      // Arrange
      final invitationResponse = remote.InvitationResponse(
        id: 1,
        groupId: 1,
        inviterId: 1,
        inviteeId: 2,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.sendInvitation(
          groupId: anyNamed('groupId'),
          identifier: anyNamed('identifier'),
        ),
      ).thenAnswer((_) async => invitationResponse);

      // Act
      await repository.sendInvitation(
        groupId: 1,
        identifier: 'user@example.com',
      );

      // Assert
      verify(
        mockRemoteDataSource.sendInvitation(
          groupId: 1,
          identifier: 'user@example.com',
        ),
      ).called(1);
    });
  });

  group('BillRepository Tests - Cache-First Strategy', () {
    late BillRepository repository;
    late MockBillRemoteDataSource mockRemoteDataSource;
    late MockBillLocalDataSource mockLocalDataSource;
    late MockSyncQueueLocalDataSource mockSyncQueueDataSource;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockRemoteDataSource = MockBillRemoteDataSource();
      mockLocalDataSource = MockBillLocalDataSource();
      mockSyncQueueDataSource = MockSyncQueueLocalDataSource();
      mockNetworkInfo = MockNetworkInfo();

      repository = BillRepository(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        syncQueueDataSource: mockSyncQueueDataSource,
        networkInfo: mockNetworkInfo,
      );
    });

    test('createBill calls remote and saves locally when online', () async {
      // Arrange
      final bill = BillModel(
        id: 1,
        groupId: 1,
        creatorId: 1,
        title: 'Test Bill',
        totalAmount: 100.0,
        billDate: DateTime.now(),
        shares: [],
        createdAt: DateTime.now(),
        isSynced: true,
      );

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.createBill(
          groupId: anyNamed('groupId'),
          title: anyNamed('title'),
          totalAmount: anyNamed('totalAmount'),
          billDate: anyNamed('billDate'),
          splitType: anyNamed('splitType'),
          shares: anyNamed('shares'),
        ),
      ).thenAnswer((_) async => bill);
      when(mockLocalDataSource.saveBill(any)).thenAnswer((_) async => 1);

      // Act
      final result = await repository.createBill(
        groupId: 1,
        title: 'Test Bill',
        totalAmount: 100.0,
        billDate: DateTime.now(),
        splitType: 'equal',
      );

      // Assert
      expect(result, equals(bill));
      verify(
        mockRemoteDataSource.createBill(
          groupId: 1,
          title: 'Test Bill',
          totalAmount: 100.0,
          billDate: anyNamed('billDate'),
          splitType: 'equal',
          shares: null,
        ),
      ).called(1);
      verify(mockLocalDataSource.saveBill(bill)).called(1);
    });

    test('createBill queues operation when offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        mockSyncQueueDataSource.addOperation(any),
      ).thenAnswer((_) async => 1);

      // Act & Assert
      await expectLater(
        repository.createBill(
          groupId: 1,
          title: 'Test Bill',
          totalAmount: 100.0,
          billDate: DateTime.now(),
          splitType: 'equal',
        ),
        throwsA(isA<Exception>()),
      );

      verify(mockSyncQueueDataSource.addOperation(any)).called(1);
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
    });

    test(
      'getBills returns remote data and updates cache when online',
      () async {
        // Arrange
        final bills = [
          BillModel(
            id: 1,
            groupId: 1,
            creatorId: 1,
            title: 'Bill 1',
            totalAmount: 100.0,
            billDate: DateTime.now(),
            shares: [],
            createdAt: DateTime.now(),
            isSynced: true,
          ),
        ];

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockRemoteDataSource.getBills(
            groupId: anyNamed('groupId'),
            fromDate: anyNamed('fromDate'),
            toDate: anyNamed('toDate'),
          ),
        ).thenAnswer((_) async => bills);
        when(mockLocalDataSource.saveBill(any)).thenAnswer((_) async => 1);

        // Act
        final result = await repository.getBills();

        // Assert
        expect(result, equals(bills));
        verify(
          mockRemoteDataSource.getBills(
            groupId: null,
            fromDate: null,
            toDate: null,
          ),
        ).called(1);
        verify(mockLocalDataSource.saveBill(any)).called(1);
      },
    );

    test('getBills returns cached data when offline', () async {
      // Arrange
      final cachedBills = [
        BillModel(
          id: 1,
          groupId: 1,
          creatorId: 1,
          title: 'Cached Bill',
          totalAmount: 100.0,
          billDate: DateTime.now(),
          shares: [],
          createdAt: DateTime.now(),
          isSynced: false,
        ),
      ];

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        mockLocalDataSource.getBills(
          groupId: anyNamed('groupId'),
          fromDate: anyNamed('fromDate'),
          toDate: anyNamed('toDate'),
        ),
      ).thenAnswer((_) async => cachedBills);

      // Act
      final result = await repository.getBills();

      // Assert
      expect(result, equals(cachedBills));
      verify(
        mockLocalDataSource.getBills(
          groupId: null,
          fromDate: null,
          toDate: null,
        ),
      ).called(1);
      verifyNever(
        mockRemoteDataSource.getBills(
          groupId: anyNamed('groupId'),
          fromDate: anyNamed('fromDate'),
          toDate: anyNamed('toDate'),
        ),
      );
    });

    test('getBills with filters passes parameters correctly', () async {
      // Arrange
      final groupId = 1;
      final fromDate = DateTime(2024, 1, 1);
      final toDate = DateTime(2024, 12, 31);
      final bills = <BillModel>[];

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.getBills(
          groupId: anyNamed('groupId'),
          fromDate: anyNamed('fromDate'),
          toDate: anyNamed('toDate'),
        ),
      ).thenAnswer((_) async => bills);

      // Act
      await repository.getBills(
        groupId: groupId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Assert
      verify(
        mockRemoteDataSource.getBills(
          groupId: groupId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ).called(1);
    });
  });

  group('PaymentRepository Tests - Error Propagation', () {
    late PaymentRepository repository;
    late MockPaymentRemoteDataSource mockRemoteDataSource;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockRemoteDataSource = MockPaymentRemoteDataSource();
      mockNetworkInfo = MockNetworkInfo();

      repository = PaymentRepository(
        remoteDataSource: mockRemoteDataSource,
        networkInfo: mockNetworkInfo,
      );
    });

    test('initiatePayment throws exception when offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act & Assert
      expect(
        () => repository.initiatePayment(shareId: 1, paymentMethod: 'gcash'),
        throwsA(isA<Exception>()),
      );

      verifyNever(
        mockRemoteDataSource.initiatePayment(
          shareId: anyNamed('shareId'),
          paymentMethod: anyNamed('paymentMethod'),
        ),
      );
    });

    test('initiatePayment calls remote when online', () async {
      // Arrange
      final paymentIntent = remote.PaymentIntentResponse(
        id: 'pi_123',
        clientKey: 'pi_123_secret',
        status: 'awaiting_payment_method',
      );
      final response = remote.PaymentResponse(
        paymentIntent: paymentIntent,
        checkoutUrl: 'https://checkout.paymongo.com/pi_123',
      );

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.initiatePayment(
          shareId: anyNamed('shareId'),
          paymentMethod: anyNamed('paymentMethod'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      final result = await repository.initiatePayment(
        shareId: 1,
        paymentMethod: 'gcash',
      );

      // Assert
      expect(result['payment_intent'], equals(paymentIntent));
      expect(
        result['checkout_url'],
        equals('https://checkout.paymongo.com/pi_123'),
      );
      verify(
        mockRemoteDataSource.initiatePayment(
          shareId: 1,
          paymentMethod: 'gcash',
        ),
      ).called(1);
    });

    test('initiatePayment propagates remote errors', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.initiatePayment(
          shareId: anyNamed('shareId'),
          paymentMethod: anyNamed('paymentMethod'),
        ),
      ).thenThrow(Exception('Payment gateway error'));

      // Act & Assert
      expect(
        () => repository.initiatePayment(shareId: 1, paymentMethod: 'gcash'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TransactionRepository Tests - Cache-First Strategy', () {
    late TransactionRepository repository;
    late MockTransactionRemoteDataSource mockRemoteDataSource;
    late MockTransactionLocalDataSource mockLocalDataSource;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockRemoteDataSource = MockTransactionRemoteDataSource();
      mockLocalDataSource = MockTransactionLocalDataSource();
      mockNetworkInfo = MockNetworkInfo();

      repository = TransactionRepository(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        networkInfo: mockNetworkInfo,
      );
    });

    test(
      'getTransactions returns remote data and updates cache when online',
      () async {
        // Arrange
        final transactions = [
          TransactionModel(
            id: 1,
            shareId: 1,
            userId: 1,
            amount: 100.0,
            paymentMethod: PaymentMethod.gcash,
            status: TransactionStatus.paid,
            createdAt: DateTime.now(),
          ),
        ];
        final summary = remote.TransactionSummary(
          totalPaid: 100.0,
          totalOwed: 0.0,
        );
        final response = remote.TransactionResponse(
          transactions: transactions,
          summary: summary,
        );

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockRemoteDataSource.getTransactions(
            fromDate: anyNamed('fromDate'),
            toDate: anyNamed('toDate'),
            groupId: anyNamed('groupId'),
          ),
        ).thenAnswer((_) async => response);
        when(
          mockLocalDataSource.saveTransaction(any),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await repository.getTransactions();

        // Assert
        expect(result['transactions'], equals(transactions));
        expect(result['summary'], equals(summary));
        verify(
          mockRemoteDataSource.getTransactions(
            fromDate: null,
            toDate: null,
            groupId: null,
          ),
        ).called(1);
        verify(mockLocalDataSource.saveTransaction(any)).called(1);
      },
    );

    test('getTransactions returns cached data when offline', () async {
      // Arrange
      final cachedTransactions = [
        TransactionModel(
          id: 1,
          shareId: 1,
          userId: 1,
          amount: 100.0,
          paymentMethod: PaymentMethod.gcash,
          status: TransactionStatus.paid,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(
        mockLocalDataSource.getTransactions(
          fromDate: anyNamed('fromDate'),
          toDate: anyNamed('toDate'),
        ),
      ).thenAnswer((_) async => cachedTransactions);

      // Act
      final result = await repository.getTransactions();

      // Assert
      expect(result['transactions'], equals(cachedTransactions));
      expect(result['summary']['total_paid'], equals(100.0));
      verify(
        mockLocalDataSource.getTransactions(fromDate: null, toDate: null),
      ).called(1);
      verifyNever(
        mockRemoteDataSource.getTransactions(
          fromDate: anyNamed('fromDate'),
          toDate: anyNamed('toDate'),
          groupId: anyNamed('groupId'),
        ),
      );
    });

    test(
      'getTransactions calculates summary from cached data when offline',
      () async {
        // Arrange
        final cachedTransactions = [
          TransactionModel(
            id: 1,
            shareId: 1,
            userId: 1,
            amount: 50.0,
            paymentMethod: PaymentMethod.gcash,
            status: TransactionStatus.paid,
            createdAt: DateTime.now(),
          ),
          TransactionModel(
            id: 2,
            shareId: 2,
            userId: 1,
            amount: 75.0,
            paymentMethod: PaymentMethod.paymaya,
            status: TransactionStatus.paid,
            createdAt: DateTime.now(),
          ),
          TransactionModel(
            id: 3,
            shareId: 3,
            userId: 1,
            amount: 25.0,
            paymentMethod: PaymentMethod.gcash,
            status: TransactionStatus.pending,
            createdAt: DateTime.now(),
          ),
        ];

        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(
          mockLocalDataSource.getTransactions(
            fromDate: anyNamed('fromDate'),
            toDate: anyNamed('toDate'),
          ),
        ).thenAnswer((_) async => cachedTransactions);

        // Act
        final result = await repository.getTransactions();

        // Assert
        expect(result['summary']['total_paid'], equals(125.0)); // 50 + 75
        expect(result['summary']['total_owed'], equals(0.0));
      },
    );

    test('getTransactions with filters passes parameters correctly', () async {
      // Arrange
      final groupId = 1;
      final fromDate = DateTime(2024, 1, 1);
      final toDate = DateTime(2024, 12, 31);
      final summary = remote.TransactionSummary(totalPaid: 0.0, totalOwed: 0.0);
      final response = remote.TransactionResponse(
        transactions: [],
        summary: summary,
      );

      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.getTransactions(
          fromDate: anyNamed('fromDate'),
          toDate: anyNamed('toDate'),
          groupId: anyNamed('groupId'),
        ),
      ).thenAnswer((_) async => response);

      // Act
      await repository.getTransactions(
        groupId: groupId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Assert
      verify(
        mockRemoteDataSource.getTransactions(
          fromDate: fromDate,
          toDate: toDate,
          groupId: groupId,
        ),
      ).called(1);
    });
  });
}
