/// Payment method enum
enum PaymentMethod {
  gcash,
  paymaya;

  String toJson() => name;

  static PaymentMethod fromJson(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.gcash,
    );
  }
}

/// Transaction status enum
enum TransactionStatus {
  pending,
  paid,
  failed;

  String toJson() => name;

  static TransactionStatus fromJson(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

/// Transaction model for API communication and local storage
class TransactionModel {
  final int id;
  final int shareId;
  final int userId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? paymongoTransactionId;
  final TransactionStatus status;
  final DateTime? paidAt;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.shareId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.paymongoTransactionId,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  /// Create Transaction from API JSON response
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      shareId: json['share_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] == 'gcash'
          ? PaymentMethod.gcash
          : PaymentMethod.paymaya,
      paymongoTransactionId: json['paymongo_transaction_id'],
      status: _parseStatus(json['status']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Parse transaction status from string
  static TransactionStatus _parseStatus(String status) {
    switch (status) {
      case 'paid':
        return TransactionStatus.paid;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }

  /// Convert Transaction to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'share_id': shareId,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod.toJson(),
      'paymongo_transaction_id': paymongoTransactionId,
      'status': status.toJson(),
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create Transaction from SQLite Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      shareId: map['share_id'],
      userId: map['user_id'],
      amount: map['amount'],
      paymentMethod: PaymentMethod.fromJson(map['payment_method']),
      paymongoTransactionId: map['paymongo_transaction_id'],
      status: TransactionStatus.fromJson(map['status']),
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Convert Transaction to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'share_id': shareId,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod.toJson(),
      'paymongo_transaction_id': paymongoTransactionId,
      'status': status.toJson(),
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
