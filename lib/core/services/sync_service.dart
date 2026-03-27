import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/core/network/network_info.dart';

/// Service for managing background synchronization
/// Coordinates offline-first sync between local cache and server
class SyncService with WidgetsBindingObserver {
  final local.SyncQueueLocalDataSource syncQueueDataSource;
  final remote.SyncRemoteDataSource syncRemoteDataSource;
  final GroupRepository groupRepository;
  final BillRepository billRepository;
  final TransactionRepository transactionRepository;
  final NetworkInfo networkInfo;

  static const String _lastSyncKey = 'last_sync_timestamp';
  static const int _maxRetries = 3;
  static const Duration _initialBackoff = Duration(seconds: 2);

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required this.syncQueueDataSource,
    required this.syncRemoteDataSource,
    required this.groupRepository,
    required this.billRepository,
    required this.transactionRepository,
    required this.networkInfo,
  });

  /// Initialize sync service
  /// Sets up connectivity listener and app lifecycle observer
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      isConnected,
    ) {
      if (isConnected) {
        sync();
      }
    });

    // Register as app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  /// Dispose sync service
  /// Cleans up listeners and observers
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Trigger sync when app resumes
    if (state == AppLifecycleState.resumed) {
      sync();
    }
  }

  /// Main sync method
  /// Orchestrates the complete sync process
  Future<void> sync() async {
    // Prevent concurrent sync operations
    if (_isSyncing) return;

    // Check network connectivity
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) return;

    _isSyncing = true;

    try {
      // Step 1: Process queued operations
      await _processQueuedOperations();

      // Step 2: Pull latest data from server
      await _pullServerData();

      // Step 3: Update last sync timestamp
      await _updateLastSyncTimestamp();
    } catch (e) {
      // Log error but don't throw - sync will retry on next trigger
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Process all queued operations from sync queue
  Future<void> _processQueuedOperations() async {
    final operations = await syncQueueDataSource.getAll();

    if (operations.isEmpty) return;

    // Convert to remote sync operations
    final remoteSyncOps = operations.map((op) {
      return remote.SyncOperation(
        type: op.operationType,
        endpoint: op.endpoint,
        payload: op.payload,
        localId: op.id?.toString(),
      );
    }).toList();

    try {
      // Send batch sync to server
      final response = await syncRemoteDataSource.batchSync(
        operations: remoteSyncOps,
      );

      // Process results
      for (var i = 0; i < response.results.length; i++) {
        final result = response.results[i];
        final operation = operations[i];

        if (result.success) {
          // Remove successful operation from queue
          await syncQueueDataSource.remove(operation.id!);
        } else {
          // Handle failed operation with retry logic
          await _handleFailedOperation(operation, result.error);
        }
      }
    } catch (e) {
      // If batch sync fails, increment retry count for all operations
      for (final operation in operations) {
        await _handleFailedOperation(operation, e.toString());
      }
    }
  }

  /// Handle failed sync operation with exponential backoff
  Future<void> _handleFailedOperation(
    local.SyncOperation operation,
    String? error,
  ) async {
    if (operation.retryCount >= _maxRetries) {
      // Max retries reached, remove from queue
      await syncQueueDataSource.remove(operation.id!);
      debugPrint(
        'Operation ${operation.operationType} failed after $_maxRetries retries: $error',
      );
    } else {
      // Increment retry count
      await syncQueueDataSource.incrementRetry(operation.id!);

      // Calculate backoff delay
      final backoffDelay = _initialBackoff * (1 << operation.retryCount);
      debugPrint(
        'Operation ${operation.operationType} failed (retry ${operation.retryCount + 1}/$_maxRetries), will retry in ${backoffDelay.inSeconds}s',
      );

      // Schedule retry after backoff delay
      Future.delayed(backoffDelay, () => sync());
    }
  }

  /// Pull latest data from server and update local cache
  Future<void> _pullServerData() async {
    try {
      // Pull groups
      await groupRepository.getGroups();

      // Pull bills (this will also pull shares)
      // Note: BillRepository.getBills() requires groupId parameter
      // We'll need to fetch bills for each group
      final groups = await groupRepository.getGroups();
      for (final group in groups) {
        await billRepository.getBills(groupId: group.id);
      }

      // Pull transactions
      await transactionRepository.getTransactions();
    } catch (e) {
      debugPrint('Failed to pull server data: $e');
      rethrow;
    }
  }

  /// Update last sync timestamp in SharedPreferences
  Future<void> _updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);

    if (timestamp == null) return null;

    return DateTime.parse(timestamp);
  }

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;
}
