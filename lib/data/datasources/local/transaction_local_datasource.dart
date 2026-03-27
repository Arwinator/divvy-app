import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/storage/database_helper.dart';

/// Local data source for Transaction operations using SQLite
class TransactionLocalDataSource {
  final DatabaseHelper _dbHelper;

  TransactionLocalDataSource(this._dbHelper);

  /// Save transaction to local database
  Future<void> saveTransaction(TransactionModel transaction) async {
    await _dbHelper.insert('transactions', {
      'id': transaction.id,
      'share_id': transaction.shareId,
      'user_id': transaction.userId,
      'amount': transaction.amount,
      'payment_method': transaction.paymentMethod.name,
      'paymongo_transaction_id': transaction.paymongoTransactionId,
      'status': transaction.status.name,
      'paid_at': transaction.paidAt?.toIso8601String(),
      'created_at': transaction.createdAt.toIso8601String(),
    });
  }

  /// Get all transactions from local database
  /// Supports filtering by date range and group_id
  Future<List<TransactionModel>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    int? groupId,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (fromDate != null || toDate != null) {
      final conditions = <String>[];
      whereArgs = [];

      if (fromDate != null) {
        conditions.add('created_at >= ?');
        whereArgs.add(fromDate.toIso8601String());
      }

      if (toDate != null) {
        conditions.add('created_at <= ?');
        whereArgs.add(toDate.toIso8601String());
      }

      where = conditions.join(' AND ');
    }

    // Note: group_id filtering requires joining with shares and bills tables
    // For now, we'll fetch all and filter in repository layer if needed
    final transactionMaps = await _dbHelper.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return transactionMaps
        .map(
          (map) => TransactionModel(
            id: map['id'] as int,
            shareId: map['share_id'] as int,
            userId: map['user_id'] as int,
            amount: map['amount'] as double,
            paymentMethod: PaymentMethod.values.firstWhere(
              (e) => e.name == map['payment_method'],
            ),
            paymongoTransactionId: map['paymongo_transaction_id'] as String?,
            status: TransactionStatus.values.firstWhere(
              (e) => e.name == map['status'],
            ),
            paidAt: map['paid_at'] != null
                ? DateTime.parse(map['paid_at'] as String)
                : null,
            createdAt: DateTime.parse(map['created_at'] as String),
          ),
        )
        .toList();
  }

  /// Upsert multiple transactions (insert or update)
  /// Used during sync to update local cache
  Future<void> upsertTransactions(List<TransactionModel> transactions) async {
    for (final transaction in transactions) {
      await _dbHelper.insert('transactions', {
        'id': transaction.id,
        'share_id': transaction.shareId,
        'user_id': transaction.userId,
        'amount': transaction.amount,
        'payment_method': transaction.paymentMethod.name,
        'paymongo_transaction_id': transaction.paymongoTransactionId,
        'status': transaction.status.name,
        'paid_at': transaction.paidAt?.toIso8601String(),
        'created_at': transaction.createdAt.toIso8601String(),
      });
    }
  }
}
