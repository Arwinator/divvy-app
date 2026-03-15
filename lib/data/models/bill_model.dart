import 'share_model.dart';

/// Bill model for API communication and local storage
class BillModel {
  final int id;
  final int groupId;
  final int creatorId;
  final String title;
  final double totalAmount;
  final DateTime billDate;
  final List<ShareModel> shares;
  final bool isSynced;

  BillModel({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.title,
    required this.totalAmount,
    required this.billDate,
    required this.shares,
    this.isSynced = true,
  });

  /// Calculate total amount paid from shares
  double get totalPaid => shares
      .where((s) => s.status == ShareStatus.paid)
      .fold(0.0, (sum, s) => sum + s.amount);

  /// Calculate remaining amount to be paid
  double get totalRemaining => totalAmount - totalPaid;

  /// Check if bill is fully settled
  bool get isFullySettled => totalRemaining == 0;

  /// Create Bill from API JSON response
  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'],
      groupId: json['group_id'],
      creatorId: json['creator_id'],
      title: json['title'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      billDate: DateTime.parse(json['bill_date']),
      shares: (json['shares'] as List)
          .map((s) => ShareModel.fromJson(s))
          .toList(),
    );
  }

  /// Convert Bill to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'creator_id': creatorId,
      'title': title,
      'total_amount': totalAmount,
      'bill_date': billDate.toIso8601String().split('T')[0], // Date only
      'shares': shares.map((s) => s.toJson()).toList(),
    };
  }

  /// Create Bill from SQLite Map
  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'],
      groupId: map['group_id'],
      creatorId: map['creator_id'],
      title: map['title'],
      totalAmount: map['total_amount'],
      billDate: DateTime.parse(map['bill_date']),
      shares: [], // Shares loaded separately via join
      isSynced: map['is_synced'] == 1,
    );
  }

  /// Convert Bill to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'creator_id': creatorId,
      'title': title,
      'total_amount': totalAmount,
      'bill_date': billDate.toIso8601String().split('T')[0], // Date only
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
