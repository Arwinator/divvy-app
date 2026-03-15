import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/bill_model.dart';

/// Remote data source for bill management operations
class BillRemoteDataSource {
  final ApiClient apiClient;

  BillRemoteDataSource({required this.apiClient});

  /// Create a new bill with equal or custom split
  /// POST /api/bills
  Future<BillModel> createBill({
    required int groupId,
    required String title,
    required double totalAmount,
    required DateTime billDate,
    required String splitType,
    List<Map<String, dynamic>>? shares,
  }) async {
    final body = {
      'group_id': groupId,
      'title': title,
      'total_amount': totalAmount,
      'bill_date': billDate.toIso8601String().split('T')[0],
      'split_type': splitType,
    };

    if (shares != null && shares.isNotEmpty) {
      body['shares'] = shares;
    }

    final response = await apiClient.post(ApiConstants.bills, body);

    return BillModel.fromJson(response);
  }

  /// Get all bills with optional filters
  /// GET /api/bills?group_id=X&from_date=Y&to_date=Z
  Future<List<BillModel>> getBills({
    int? groupId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    String endpoint = ApiConstants.bills;
    final queryParams = <String>[];

    if (groupId != null) {
      queryParams.add('group_id=$groupId');
    }
    if (fromDate != null) {
      queryParams.add('from_date=${fromDate.toIso8601String().split('T')[0]}');
    }
    if (toDate != null) {
      queryParams.add('to_date=${toDate.toIso8601String().split('T')[0]}');
    }

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await apiClient.get(endpoint);

    final List<dynamic> billsData = response['data'];
    return billsData.map((json) => BillModel.fromJson(json)).toList();
  }

  /// Get a specific bill by ID
  /// GET /api/bills/{id}
  Future<BillModel> getBillById({required int billId}) async {
    final response = await apiClient.get(ApiConstants.billDetails(billId));

    return BillModel.fromJson(response);
  }
}
