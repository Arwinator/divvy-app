import 'dart:convert';
import '../../../core/storage/database_helper.dart';

/// Model for sync queue operations
class SyncOperation {
  final int? id;
  final String operationType;
  final String endpoint;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime createdAt;

  SyncOperation({
    this.id,
    required this.operationType,
    required this.endpoint,
    required this.payload,
    this.retryCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'operation_type': operationType,
      'endpoint': endpoint,
      'payload': jsonEncode(payload),
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as int,
      operationType: map['operation_type'] as String,
      endpoint: map['endpoint'] as String,
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      retryCount: map['retry_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Local data source for Sync Queue operations using SQLite
class SyncQueueLocalDataSource {
  final DatabaseHelper _dbHelper;

  SyncQueueLocalDataSource(this._dbHelper);

  /// Add operation to sync queue
  Future<int> addOperation(SyncOperation operation) async {
    return await _dbHelper.insert('sync_queue', operation.toMap());
  }

  /// Get all operations from sync queue
  /// Returns operations ordered by creation time (oldest first)
  Future<List<SyncOperation>> getAll() async {
    final maps = await _dbHelper.query('sync_queue', orderBy: 'created_at ASC');

    return maps.map((map) => SyncOperation.fromMap(map)).toList();
  }

  /// Remove operation from sync queue
  Future<void> remove(int operationId) async {
    await _dbHelper.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  /// Increment retry count for an operation
  Future<void> incrementRetry(int operationId) async {
    final results = await _dbHelper.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [operationId],
    );

    if (results.isEmpty) return;

    final operation = SyncOperation.fromMap(results.first);
    await _dbHelper.update(
      'sync_queue',
      {'retry_count': operation.retryCount + 1},
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }
}
