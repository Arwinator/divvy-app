import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/storage/database_helper.dart';

/// Local data source for Bill operations using SQLite
class BillLocalDataSource {
  final DatabaseHelper _dbHelper;

  BillLocalDataSource(this._dbHelper);

  /// Save bill to local database
  /// Also saves shares to shares table
  Future<void> saveBill(BillModel bill) async {
    await _dbHelper.insert('bills', bill.toMap());

    // Save shares
    for (final share in bill.shares) {
      await _dbHelper.insert('shares', {
        'id': share.id,
        'bill_id': bill.id,
        'user_id': share.userId,
        'amount': share.amount,
        'status': share.status.name,
        'username': share.user.username,
        'email': share.user.email,
      });
    }
  }

  /// Get all bills from local database with shares
  /// Supports filtering by group_id and date range
  Future<List<BillModel>> getBills({
    int? groupId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (groupId != null || fromDate != null || toDate != null) {
      final conditions = <String>[];
      whereArgs = [];

      if (groupId != null) {
        conditions.add('group_id = ?');
        whereArgs.add(groupId);
      }

      if (fromDate != null) {
        conditions.add('bill_date >= ?');
        whereArgs.add(fromDate.toIso8601String().split('T')[0]);
      }

      if (toDate != null) {
        conditions.add('bill_date <= ?');
        whereArgs.add(toDate.toIso8601String().split('T')[0]);
      }

      where = conditions.join(' AND ');
    }

    final billMaps = await _dbHelper.query(
      'bills',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'bill_date DESC',
    );

    final bills = <BillModel>[];
    for (final billMap in billMaps) {
      final shares = await _getBillShares(billMap['id'] as int);
      bills.add(BillModel.fromMap(billMap).copyWith(shares: shares));
    }

    return bills;
  }

  /// Get bill by ID with shares
  Future<BillModel?> getBillById(int billId) async {
    final results = await _dbHelper.query(
      'bills',
      where: 'id = ?',
      whereArgs: [billId],
    );

    if (results.isEmpty) return null;

    final shares = await _getBillShares(billId);
    return BillModel.fromMap(results.first).copyWith(shares: shares);
  }

  /// Delete bill from local database
  /// Cascade deletes shares automatically
  Future<void> deleteBill(int billId) async {
    await _dbHelper.delete('bills', where: 'id = ?', whereArgs: [billId]);
  }

  /// Upsert multiple bills (insert or update)
  /// Used during sync to update local cache
  Future<void> upsertBills(List<BillModel> bills) async {
    for (final bill in bills) {
      await _dbHelper.insert('bills', bill.toMap());

      // Delete existing shares and re-insert
      await _dbHelper.delete(
        'shares',
        where: 'bill_id = ?',
        whereArgs: [bill.id],
      );

      for (final share in bill.shares) {
        await _dbHelper.insert('shares', {
          'id': share.id,
          'bill_id': bill.id,
          'user_id': share.userId,
          'amount': share.amount,
          'status': share.status.name,
          'username': share.user.username,
          'email': share.user.email,
        });
      }
    }
  }

  /// Helper method to get bill shares
  Future<List<ShareModel>> _getBillShares(int billId) async {
    final shareMaps = await _dbHelper.query(
      'shares',
      where: 'bill_id = ?',
      whereArgs: [billId],
    );

    return shareMaps.map((map) {
      final user = UserModel(
        id: map['user_id'] as int,
        username: map['username'] as String,
        email: map['email'] as String,
        createdAt: DateTime.now(), // Not stored in shares
      );

      return ShareModel(
        id: map['id'] as int,
        billId: map['bill_id'] as int,
        userId: map['user_id'] as int,
        amount: map['amount'] as double,
        status: ShareStatus.values.firstWhere((e) => e.name == map['status']),
        user: user,
      );
    }).toList();
  }
}

// Extension to add copyWith method to BillModel
extension BillModelExtension on BillModel {
  BillModel copyWith({
    int? id,
    int? groupId,
    int? creatorId,
    String? title,
    double? totalAmount,
    DateTime? billDate,
    DateTime? createdAt,
    List<ShareModel>? shares,
    bool? isSynced,
  }) {
    return BillModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      billDate: billDate ?? this.billDate,
      createdAt: createdAt ?? this.createdAt,
      shares: shares ?? this.shares,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
