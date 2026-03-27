import 'package:flutter/foundation.dart';
import 'package:divvy/core/services/sync_service.dart';
import 'package:divvy/core/network/network_info.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart';

/// ViewModel for synchronization operations
/// Manages sync state and coordinates with SyncService
class SyncViewModel extends ChangeNotifier {
  final SyncService _syncService;
  final NetworkInfo _networkInfo;
  final SyncQueueLocalDataSource _syncQueueDataSource;

  SyncViewModel({
    required SyncService syncService,
    required NetworkInfo networkInfo,
    required SyncQueueLocalDataSource syncQueueDataSource,
  }) : _syncService = syncService,
       _networkInfo = networkInfo,
       _syncQueueDataSource = syncQueueDataSource {
    _initialize();
  }

  // State
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingOperationsCount = 0;
  bool _isOnline = false;

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingOperationsCount => _pendingOperationsCount;
  bool get isOnline => _isOnline;
  bool get hasPendingOperations => _pendingOperationsCount > 0;

  /// Initialize the ViewModel
  /// Sets up network connectivity listener
  void _initialize() {
    // Listen to network connectivity changes
    _networkInfo.onConnectivityChanged.listen((isConnected) {
      _isOnline = isConnected;
      notifyListeners();
    });

    // Get initial connectivity status
    _checkConnectivity();

    // Get initial sync state
    _updateSyncState();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    _isOnline = await _networkInfo.isConnected;
    notifyListeners();
  }

  /// Update sync state from SyncService
  Future<void> _updateSyncState() async {
    _lastSyncTime = await _syncService.getLastSyncTimestamp();
    _pendingOperationsCount = await getPendingCount();
    notifyListeners();
  }

  /// Trigger manual synchronization
  Future<bool> triggerSync() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      await _syncService.sync();
      await _updateSyncState();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Get pending operations count
  Future<int> getPendingCount() async {
    final operations = await _syncQueueDataSource.getAll();
    return operations.length;
  }

  /// Get time since last sync in human-readable format
  String getTimeSinceLastSync() {
    if (_lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Check if sync is needed
  /// Returns true if there are pending operations or last sync was > 5 minutes ago
  bool isSyncNeeded() {
    if (_pendingOperationsCount > 0) return true;

    if (_lastSyncTime == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    return difference.inMinutes > 5;
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
