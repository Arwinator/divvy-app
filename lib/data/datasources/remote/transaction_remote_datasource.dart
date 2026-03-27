import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/core/constants/api_constants.dart';
import 'package:divvy/data/models/models.dart';

/// Transaction summary from API
class TransactionSummary {
  final double totalPaid;
  final double totalOwed;

  TransactionSummary({required this.totalPaid, required this.totalOwed});

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalPaid: (json['total_paid'] as num).toDouble(),
      totalOwed: (json['total_owed'] as num).toDouble(),
    );
  }
}

/// Transaction response containing transactions and summary
class TransactionResponse {
  final List<TransactionModel> transactions;
  final TransactionSummary summary;

  TransactionResponse({required this.transactions, required this.summary});

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> transactionsData = json['data'];
    final transactions = transactionsData
        .map((json) => TransactionModel.fromJson(json))
        .toList();

    return TransactionResponse(
      transactions: transactions,
      summary: TransactionSummary.fromJson(json['summary']),
    );
  }
}

/// Remote data source for transaction history operations
class TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSource({required this.apiClient});

  /// Get all transactions with optional filters
  /// GET /api/transactions?from_date=X&to_date=Y&group_id=Z
  Future<TransactionResponse> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    int? groupId,
  }) async {
    String endpoint = ApiConstants.transactions;
    final queryParams = <String>[];

    if (fromDate != null) {
      queryParams.add('from_date=${fromDate.toIso8601String().split('T')[0]}');
    }
    if (toDate != null) {
      queryParams.add('to_date=${toDate.toIso8601String().split('T')[0]}');
    }
    if (groupId != null) {
      queryParams.add('group_id=$groupId');
    }

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await apiClient.get(endpoint);

    return TransactionResponse.fromJson(response);
  }
}
