import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:divvy/presentation/viewmodels/payment_viewmodel.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';

import 'payment_blocking_when_offline_test.mocks.dart';

@GenerateMocks([remote.PaymentRemoteDataSource, BillRepository, NetworkInfo])
void main() {
  late PaymentViewModel viewModel;
  late PaymentRepository paymentRepository;
  late MockPaymentRemoteDataSource mockRemoteDataSource;
  late MockBillRepository mockBillRepository;
  late MockNetworkInfo mockNetworkInfo;
  late Random random;

  setUp(() {
    mockRemoteDataSource = MockPaymentRemoteDataSource();
    mockBillRepository = MockBillRepository();
    mockNetworkInfo = MockNetworkInfo();
    random = Random();

    paymentRepository = PaymentRepository(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );

    viewModel = PaymentViewModel(
      paymentRepository: paymentRepository,
      billRepository: mockBillRepository,
    );
  });

  group('Property 23: Payment Blocking When Offline', () {
    test(
      'payment initiation is blocked when offline with appropriate error message',
      () async {
        // Property: When offline, payment initiation should:
        // 1. Check network connectivity first
        // 2. Throw exception with clear error message
        // 3. NOT call remote data source
        // 4. NOT create payment intent

        for (int i = 0; i < 100; i++) {
          // Reset mocks for each iteration
          reset(mockNetworkInfo);
          reset(mockRemoteDataSource);

          // Generate random payment data
          final shareId = random.nextInt(10000) + 1;
          final paymentMethod = random.nextBool() ? 'gcash' : 'paymaya';

          // Simulate offline state
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Attempt to initiate payment while offline
          try {
            await paymentRepository.initiatePayment(
              shareId: shareId,
              paymentMethod: paymentMethod,
            );

            // Should not reach here - expect exception
            fail('Expected exception when initiating payment offline');
          } catch (e) {
            // Verify exception message indicates offline status
            expect(
              e.toString(),
              contains('Cannot process payment while offline'),
            );
            expect(
              e.toString(),
              contains('Please check your internet connection'),
            );
          }

          // Verify network connectivity was checked
          verify(mockNetworkInfo.isConnected).called(1);

          // Verify remote data source was NOT called
          verifyNever(
            mockRemoteDataSource.initiatePayment(
              shareId: anyNamed('shareId'),
              paymentMethod: anyNamed('paymentMethod'),
            ),
          );
        }
      },
    );

    test(
      'payment initiation through ViewModel is blocked when offline',
      () async {
        // Property: ViewModel should propagate offline error to UI layer

        for (int i = 0; i < 100; i++) {
          // Reset mocks and viewModel state
          reset(mockNetworkInfo);
          reset(mockRemoteDataSource);
          viewModel.clearError();

          // Generate random payment data
          final shareId = random.nextInt(10000) + 1;
          final paymentMethod = random.nextBool() ? 'gcash' : 'paymaya';

          // Simulate offline state
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Attempt to initiate payment through ViewModel
          final result = await viewModel.initiatePayment(
            shareId: shareId,
            paymentMethod: paymentMethod,
          );

          // Verify payment initiation failed
          expect(result, isFalse);

          // Verify error message is set in ViewModel
          expect(viewModel.error, isNotNull);
          expect(
            viewModel.error,
            contains('Cannot process payment while offline'),
          );

          // Verify payment URL was not set
          expect(viewModel.paymentUrl, isNull);

          // Verify processing state is false
          expect(viewModel.isProcessing, isFalse);

          // Verify network connectivity was checked
          verify(mockNetworkInfo.isConnected).called(1);

          // Verify remote data source was NOT called
          verifyNever(
            mockRemoteDataSource.initiatePayment(
              shareId: anyNamed('shareId'),
              paymentMethod: anyNamed('paymentMethod'),
            ),
          );
        }
      },
    );

    test(
      'payment blocking works consistently for both GCash and PayMaya',
      () async {
        // Property: Offline blocking should work for all payment methods

        for (int i = 0; i < 100; i++) {
          // Reset mocks
          reset(mockNetworkInfo);
          reset(mockRemoteDataSource);

          // Generate random payment data
          final shareId = random.nextInt(10000) + 1;
          // Alternate between payment methods
          final paymentMethod = i % 2 == 0 ? 'gcash' : 'paymaya';

          // Simulate offline state
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Attempt to initiate payment
          try {
            await paymentRepository.initiatePayment(
              shareId: shareId,
              paymentMethod: paymentMethod,
            );

            fail('Expected exception for $paymentMethod payment when offline');
          } catch (e) {
            // Verify exception is thrown regardless of payment method
            expect(
              e.toString(),
              contains('Cannot process payment while offline'),
            );
          }

          // Verify network check happened
          verify(mockNetworkInfo.isConnected).called(1);

          // Verify remote was not called for either payment method
          verifyNever(
            mockRemoteDataSource.initiatePayment(
              shareId: anyNamed('shareId'),
              paymentMethod: anyNamed('paymentMethod'),
            ),
          );
        }
      },
    );

    test(
      'multiple payment attempts while offline all fail consistently',
      () async {
        // Property: Multiple offline payment attempts should all be blocked

        // Simulate offline state
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final attemptCount = random.nextInt(5) + 3; // 3-7 attempts
        final failedAttempts = <int>[];

        for (int i = 0; i < attemptCount; i++) {
          final shareId = random.nextInt(10000) + 1;
          final paymentMethod = random.nextBool() ? 'gcash' : 'paymaya';

          try {
            await paymentRepository.initiatePayment(
              shareId: shareId,
              paymentMethod: paymentMethod,
            );

            fail('Expected exception for attempt $i');
          } catch (e) {
            // Track failed attempts
            failedAttempts.add(i);

            // Verify error message
            expect(
              e.toString(),
              contains('Cannot process payment while offline'),
            );
          }
        }

        // Verify all attempts failed
        expect(failedAttempts.length, equals(attemptCount));

        // Verify network was checked for each attempt
        verify(mockNetworkInfo.isConnected).called(attemptCount);

        // Verify remote was never called
        verifyNever(
          mockRemoteDataSource.initiatePayment(
            shareId: anyNamed('shareId'),
            paymentMethod: anyNamed('paymentMethod'),
          ),
        );
      },
    );

    test(
      'payment blocking prevents any payment intent creation when offline',
      () async {
        // Property: No payment intent should be created when offline

        for (int i = 0; i < 100; i++) {
          // Reset mocks
          reset(mockNetworkInfo);
          reset(mockRemoteDataSource);

          // Generate random payment data
          final shareId = random.nextInt(10000) + 1;
          final paymentMethod = random.nextBool() ? 'gcash' : 'paymaya';

          // Simulate offline state
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Attempt payment
          Map<String, dynamic>? paymentIntent;
          try {
            paymentIntent = await paymentRepository.initiatePayment(
              shareId: shareId,
              paymentMethod: paymentMethod,
            );
          } catch (e) {
            // Expected exception
          }

          // Verify no payment intent was created
          expect(paymentIntent, isNull);

          // Verify remote data source was never called
          verifyNever(
            mockRemoteDataSource.initiatePayment(
              shareId: anyNamed('shareId'),
              paymentMethod: anyNamed('paymentMethod'),
            ),
          );
        }
      },
    );

    test(
      'offline payment blocking works with random share IDs and amounts',
      () async {
        // Property: Blocking should work regardless of share ID or amount

        for (int i = 0; i < 100; i++) {
          // Reset mocks
          reset(mockNetworkInfo);
          reset(mockRemoteDataSource);

          // Generate random share ID (including edge cases)
          final shareId = i % 10 == 0
              ? 1 // Minimum valid ID
              : i % 10 == 1
              ? 999999 // Large ID
              : random.nextInt(10000) + 1; // Random ID

          final paymentMethod = random.nextBool() ? 'gcash' : 'paymaya';

          // Simulate offline state
          when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

          // Attempt payment
          try {
            await paymentRepository.initiatePayment(
              shareId: shareId,
              paymentMethod: paymentMethod,
            );

            fail('Expected exception for shareId $shareId');
          } catch (e) {
            // Verify exception regardless of share ID
            expect(
              e.toString(),
              contains('Cannot process payment while offline'),
            );
          }

          // Verify network check happened
          verify(mockNetworkInfo.isConnected).called(1);

          // Verify remote was not called
          verifyNever(
            mockRemoteDataSource.initiatePayment(
              shareId: anyNamed('shareId'),
              paymentMethod: anyNamed('paymentMethod'),
            ),
          );
        }
      },
    );
  });
}
