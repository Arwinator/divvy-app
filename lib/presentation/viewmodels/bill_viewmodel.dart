import 'package:flutter/foundation.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/models/models.dart';

/// Split type for bill creation
enum SplitType { equal, custom }

/// ViewModel for bill management operations
/// Manages bill state and coordinates with BillRepository
class BillViewModel extends ChangeNotifier {
  final BillRepository _repository;

  BillViewModel({required BillRepository repository})
    : _repository = repository;

  // State
  List<BillModel> _bills = [];
  bool _isLoading = false;
  String? _error;
  SplitType _selectedSplitType = SplitType.equal;

  // Getters
  List<BillModel> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SplitType get selectedSplitType => _selectedSplitType;

  /// Set the selected split type
  void setSplitType(SplitType splitType) {
    _selectedSplitType = splitType;
    notifyListeners();
  }

  /// Load all bills for the current user
  Future<void> loadBills({
    int? groupId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bills = await _repository.getBills(
        groupId: groupId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new bill with equal split
  Future<bool> createBillWithEqualSplit({
    required int groupId,
    required String title,
    required double totalAmount,
    required DateTime billDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newBill = await _repository.createBill(
        groupId: groupId,
        title: title,
        totalAmount: totalAmount,
        billDate: billDate,
        splitType: 'equal',
      );

      _bills.insert(0, newBill); // Add to beginning of list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a new bill with custom split
  Future<bool> createBillWithCustomSplit({
    required int groupId,
    required String title,
    required double totalAmount,
    required DateTime billDate,
    required List<Map<String, dynamic>> shares,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate custom split before sending
      if (!validateCustomSplit(totalAmount, shares)) {
        _error = 'Sum of shares must equal total amount';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newBill = await _repository.createBill(
        groupId: groupId,
        title: title,
        totalAmount: totalAmount,
        billDate: billDate,
        splitType: 'custom',
        shares: shares,
      );

      _bills.insert(0, newBill); // Add to beginning of list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Calculate equal split amounts for a given total and member count
  /// Returns a list of amounts that sum to the total
  List<double> calculateEqualSplit(double totalAmount, int memberCount) {
    if (memberCount <= 0) return [];

    final baseAmount = (totalAmount / memberCount).floorToDouble() / 100 * 100;
    final remainder = totalAmount - (baseAmount * memberCount);

    final shares = List<double>.filled(memberCount, baseAmount);

    // Distribute remainder to first member
    if (remainder > 0) {
      shares[0] += remainder;
    }

    return shares;
  }

  /// Validate that custom split shares sum to total amount
  /// Allows for small rounding differences (within 0.01)
  bool validateCustomSplit(
    double totalAmount,
    List<Map<String, dynamic>> shares,
  ) {
    if (shares.isEmpty) return false;

    final sum = shares.fold<double>(
      0.0,
      (sum, share) => sum + (share['amount'] as double),
    );

    return (sum - totalAmount).abs() < 0.01;
  }

  /// Get a specific bill by ID
  BillModel? getBillById(int billId) {
    try {
      return _bills.firstWhere((b) => b.id == billId);
    } catch (e) {
      return null;
    }
  }

  /// Get bills for a specific group
  List<BillModel> getBillsForGroup(int groupId) {
    return _bills.where((b) => b.groupId == groupId).toList();
  }

  /// Get unpaid bills
  List<BillModel> getUnpaidBills() {
    return _bills.where((b) => !b.isFullySettled).toList();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
