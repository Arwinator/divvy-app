import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/network/network_info.dart';
import 'package:divvy/data/models/models.dart';

/// Repository for bill management operations
/// Implements offline-first pattern with background sync
class BillRepository {
  final remote.BillRemoteDataSource remoteDataSource;
  final local.BillLocalDataSource localDataSource;
  final local.SyncQueueLocalDataSource syncQueueDataSource;
  final NetworkInfo networkInfo;

  BillRepository({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.syncQueueDataSource,
    required this.networkInfo,
  });

  /// Create a new bill
  /// Tries remote first, queues for sync if offline, saves locally
  Future<BillModel> createBill({
    required int groupId,
    required String title,
    required double totalAmount,
    required DateTime billDate,
    required String splitType,
    List<Map<String, dynamic>>? shares,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Try remote creation
        final bill = await remoteDataSource.createBill(
          groupId: groupId,
          title: title,
          totalAmount: totalAmount,
          billDate: billDate,
          splitType: splitType,
          shares: shares,
        );

        // Save to local cache
        await localDataSource.saveBill(bill);

        return bill;
      } catch (e) {
        // If remote fails, queue for sync
        await _queueBillCreation(
          groupId: groupId,
          title: title,
          totalAmount: totalAmount,
          billDate: billDate,
          splitType: splitType,
          shares: shares,
        );
        rethrow;
      }
    } else {
      // Offline: queue for sync
      await _queueBillCreation(
        groupId: groupId,
        title: title,
        totalAmount: totalAmount,
        billDate: billDate,
        splitType: splitType,
        shares: shares,
      );
      throw Exception(
        'Cannot create bill while offline. Will sync when online.',
      );
    }
  }

  /// Queue bill creation for later sync
  Future<void> _queueBillCreation({
    required int groupId,
    required String title,
    required double totalAmount,
    required DateTime billDate,
    required String splitType,
    List<Map<String, dynamic>>? shares,
  }) async {
    final operation = local.SyncOperation(
      operationType: 'create_bill',
      endpoint: '/api/bills',
      payload: {
        'group_id': groupId,
        'title': title,
        'total_amount': totalAmount,
        'bill_date': billDate.toIso8601String(),
        'split_type': splitType,
        ...?shares != null ? {'shares': shares} : null,
      },
      createdAt: DateTime.now(),
    );
    await syncQueueDataSource.addOperation(operation);
  }

  /// Get all bills for current user
  /// Returns from cache, syncs in background if online
  /// Supports filtering by group_id, from_date, to_date
  Future<List<BillModel>> getBills({
    int? groupId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Fetch from remote
        final bills = await remoteDataSource.getBills(
          groupId: groupId,
          fromDate: fromDate,
          toDate: toDate,
        );

        // Update local cache
        for (final bill in bills) {
          await localDataSource.saveBill(bill);
        }

        return bills;
      } catch (e) {
        // If remote fails, return cached data
        return await localDataSource.getBills(
          groupId: groupId,
          fromDate: fromDate,
          toDate: toDate,
        );
      }
    } else {
      // Offline: return cached data
      return await localDataSource.getBills(
        groupId: groupId,
        fromDate: fromDate,
        toDate: toDate,
      );
    }
  }

  /// Get a specific bill by ID
  /// Returns from cache, syncs in background if online
  Future<BillModel?> getBill(int billId) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Fetch from remote (getBill not implemented in remote datasource yet)
        // For now, return from cache
        return await localDataSource.getBillById(billId);
      } catch (e) {
        // If remote fails, return cached data
        return await localDataSource.getBillById(billId);
      }
    } else {
      // Offline: return cached data
      return await localDataSource.getBillById(billId);
    }
  }

  /// Get bills for a specific group
  /// Returns from cache, syncs in background if online
  Future<List<BillModel>> getBillsByGroup(int groupId) async {
    return await getBills(groupId: groupId);
  }
}
