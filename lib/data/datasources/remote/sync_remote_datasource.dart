import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/core/constants/api_constants.dart';

/// Sync operation to be sent to the server
class SyncOperation {
  final String type;
  final String endpoint;
  final Map<String, dynamic> payload;
  final String? localId;

  SyncOperation({
    required this.type,
    required this.endpoint,
    required this.payload,
    this.localId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'endpoint': endpoint,
      'payload': payload,
      if (localId != null) 'local_id': localId,
    };
  }
}

/// Result of a single sync operation
class SyncOperationResult {
  final bool success;
  final String? localId;
  final int? serverId;
  final String? error;

  SyncOperationResult({
    required this.success,
    this.localId,
    this.serverId,
    this.error,
  });

  factory SyncOperationResult.fromJson(Map<String, dynamic> json) {
    return SyncOperationResult(
      success: json['success'] ?? false,
      localId: json['local_id'],
      serverId: json['server_id'],
      error: json['error'],
    );
  }
}

/// Batch sync response from server
class BatchSyncResponse {
  final List<SyncOperationResult> results;

  BatchSyncResponse({required this.results});

  factory BatchSyncResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> resultsData = json['results'] ?? [];
    final results = resultsData
        .map((json) => SyncOperationResult.fromJson(json))
        .toList();

    return BatchSyncResponse(results: results);
  }
}

/// Remote data source for sync operations
class SyncRemoteDataSource {
  final ApiClient apiClient;

  SyncRemoteDataSource({required this.apiClient});

  /// Send batch sync operations to server
  /// POST /api/sync
  Future<BatchSyncResponse> batchSync({
    required List<SyncOperation> operations,
  }) async {
    final response = await apiClient.post(ApiConstants.sync, {
      'operations': operations.map((op) => op.toJson()).toList(),
    });

    return BatchSyncResponse.fromJson(response);
  }

  /// Get the last sync timestamp from server
  /// GET /api/sync/timestamp
  Future<DateTime> getLastSyncTimestamp() async {
    final response = await apiClient.get(ApiConstants.syncTimestamp);

    return DateTime.parse(response['timestamp']);
  }
}
