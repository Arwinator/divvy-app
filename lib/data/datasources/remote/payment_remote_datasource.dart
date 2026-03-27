import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/core/constants/api_constants.dart';

/// Payment intent response from PayMongo
class PaymentIntentResponse {
  final String id;
  final String clientKey;
  final String status;

  PaymentIntentResponse({
    required this.id,
    required this.clientKey,
    required this.status,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      id: json['id'],
      clientKey: json['client_key'],
      status: json['status'],
    );
  }
}

/// Payment response containing payment intent and checkout URL
class PaymentResponse {
  final PaymentIntentResponse paymentIntent;
  final String checkoutUrl;

  PaymentResponse({required this.paymentIntent, required this.checkoutUrl});

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      paymentIntent: PaymentIntentResponse.fromJson(json['payment_intent']),
      checkoutUrl: json['checkout_url'],
    );
  }
}

/// Remote data source for payment operations
class PaymentRemoteDataSource {
  final ApiClient apiClient;

  PaymentRemoteDataSource({required this.apiClient});

  /// Initiate a payment for a share
  /// POST /api/shares/{id}/pay
  Future<PaymentResponse> initiatePayment({
    required int shareId,
    required String paymentMethod,
  }) async {
    final response = await apiClient.post(ApiConstants.payShare(shareId), {
      'payment_method': paymentMethod,
    });

    return PaymentResponse.fromJson(response);
  }
}
