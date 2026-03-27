import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';
import 'package:divvy/data/models/models.dart';

/// Repository for transaction history operations
/// Implements offline-first pattern with background sync
class TransactionRepository {
  final remote.TransactionRemoteDataSource remoteDataSource;
  final local.TransactionLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TransactionRepository({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  /// Get all transactions for current user
  /// Returns from cache, syncs in background if online
  /// Supports filtering by date range and group_id
  Future<Map<String, dynamic>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    int? groupId,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Fetch from remote
        final response = await remoteDataSource.getTransactions(
          fromDate: fromDate,
          toDate: toDate,
          groupId: groupId,
        );

        // Update local cache
        for (final transaction in response.transactions) {
          await localDataSource.saveTransaction(transaction);
        }

        return {
          'transactions': response.transactions,
          'summary': response.summary,
        };
      } catch (e) {
        // If remote fails, return cached data with calculated summary
        final transactions = await localDataSource.getTransactions(
          fromDate: fromDate,
          toDate: toDate,
        );

        final summary = _calculateSummary(transactions);

        return {'transactions': transactions, 'summary': summary};
      }
    } else {
      // Offline: return cached data with calculated summary
      final transactions = await localDataSource.getTransactions(
        fromDate: fromDate,
        toDate: toDate,
      );

      final summary = _calculateSummary(transactions);

      return {'transactions': transactions, 'summary': summary};
    }
  }

  /// Calculate transaction summary
  /// Calculates total_paid from paid transactions
  /// Note: total_owed calculation requires share data which is not available here
  Map<String, double> _calculateSummary(List<TransactionModel> transactions) {
    double totalPaid = 0.0;

    for (final transaction in transactions) {
      if (transaction.status == TransactionStatus.paid) {
        totalPaid += transaction.amount;
      }
    }

    return {
      'total_paid': totalPaid,
      'total_owed': 0.0, // Will be calculated by backend with share data
    };
  }
}
