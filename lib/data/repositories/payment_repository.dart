import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';

/// Repository for payment operations
/// Payment operations require online connection for security
class PaymentRepository {
  final remote.PaymentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PaymentRepository({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  /// Initiate payment for a share
  /// Requires online connection - throws error if offline
  /// Returns payment intent with checkout URL
  Future<Map<String, dynamic>> initiatePayment({
    required int shareId,
    required String paymentMethod,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      throw Exception(
        'Cannot process payment while offline. Please check your internet connection.',
      );
    }

    final response = await remoteDataSource.initiatePayment(
      shareId: shareId,
      paymentMethod: paymentMethod,
    );

    return {
      'payment_intent': response.paymentIntent,
      'checkout_url': response.checkoutUrl,
    };
  }
}
