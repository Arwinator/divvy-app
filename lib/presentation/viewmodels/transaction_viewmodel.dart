import 'package:flutter/foundation.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/models/models.dart';

/// ViewModel for transaction history operations
/// Manages transaction state and coordinates with TransactionRepository
class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _repository;

  TransactionViewModel({required TransactionRepository repository})
    : _repository = repository;

  // State
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  double _totalPaid = 0.0;
  double _totalOwed = 0.0;

  // Filter state
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _groupId;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalPaid => _totalPaid;
  double get totalOwed => _totalOwed;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  int? get groupId => _groupId;

  /// Load transactions with optional filters
  Future<void> loadTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    int? groupId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.getTransactions(
        fromDate: fromDate,
        toDate: toDate,
        groupId: groupId,
      );

      _transactions = response['transactions'] as List<TransactionModel>;
      final summary = response['summary'] as Map<String, double>;
      _totalPaid = summary['total_paid'] ?? 0.0;
      _totalOwed = summary['total_owed'] ?? 0.0;

      // Update filter state
      _fromDate = fromDate;
      _toDate = toDate;
      _groupId = groupId;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter transactions by date range
  Future<void> filterByDateRange({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    await loadTransactions(
      fromDate: fromDate,
      toDate: toDate,
      groupId: _groupId,
    );
  }

  /// Filter transactions by group
  Future<void> filterByGroup({required int groupId}) async {
    await loadTransactions(
      fromDate: _fromDate,
      toDate: _toDate,
      groupId: groupId,
    );
  }

  /// Clear all filters and reload
  Future<void> clearFilters() async {
    _fromDate = null;
    _toDate = null;
    _groupId = null;
    await loadTransactions();
  }

  /// Get transactions for a specific payment method
  List<TransactionModel> getTransactionsByPaymentMethod(
    PaymentMethod paymentMethod,
  ) {
    return _transactions
        .where((t) => t.paymentMethod == paymentMethod)
        .toList();
  }

  /// Get transactions by status
  List<TransactionModel> getTransactionsByStatus(TransactionStatus status) {
    return _transactions.where((t) => t.status == status).toList();
  }

  /// Get paid transactions
  List<TransactionModel> getPaidTransactions() {
    return getTransactionsByStatus(TransactionStatus.paid);
  }

  /// Get pending transactions
  List<TransactionModel> getPendingTransactions() {
    return getTransactionsByStatus(TransactionStatus.pending);
  }

  /// Get failed transactions
  List<TransactionModel> getFailedTransactions() {
    return getTransactionsByStatus(TransactionStatus.failed);
  }

  /// Calculate total for a specific payment method
  double getTotalByPaymentMethod(PaymentMethod paymentMethod) {
    return getTransactionsByPaymentMethod(paymentMethod)
        .where((t) => t.status == TransactionStatus.paid)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get a specific transaction by ID
  TransactionModel? getTransactionById(int transactionId) {
    try {
      return _transactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
