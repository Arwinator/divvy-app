import 'user_model.dart';

/// Share status enum
enum ShareStatus {
  unpaid,
  paid;

  String toJson() => name;

  static ShareStatus fromJson(String value) {
    return ShareStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShareStatus.unpaid,
    );
  }
}

/// Share model for API communication and local storage
class ShareModel {
  final int id;
  final int billId;
  final int userId;
  final double amount;
  final ShareStatus status;
  final UserModel user;

  ShareModel({
    required this.id,
    required this.billId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.user,
  });

  /// Create Share from API JSON response
  factory ShareModel.fromJson(Map<String, dynamic> json) {
    return ShareModel(
      id: json['id'],
      billId: json['bill_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] == 'paid' ? ShareStatus.paid : ShareStatus.unpaid,
      user: UserModel.fromJson(json['user']),
    );
  }

  /// Convert Share to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'user_id': userId,
      'amount': amount,
      'status': status.toJson(),
      'user': user.toJson(),
    };
  }

  /// Create Share from SQLite Map
  factory ShareModel.fromMap(Map<String, dynamic> map, UserModel user) {
    return ShareModel(
      id: map['id'],
      billId: map['bill_id'],
      userId: map['user_id'],
      amount: map['amount'],
      status: ShareStatus.fromJson(map['status']),
      user: user,
    );
  }

  /// Convert Share to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'user_id': userId,
      'amount': amount,
      'status': status.toJson(),
    };
  }
}
