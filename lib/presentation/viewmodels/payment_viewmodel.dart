import 'package:flutter/foundation.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/models/models.dart';

/// ViewModel for payment operations
/// Manages payment state and coordinates with PaymentRepository
class PaymentViewModel extends ChangeNotifier {
  final PaymentRepository _paymentRepository;
  final BillRepository _billRepository;

  PaymentViewModel({
    required PaymentRepository paymentRepository,
    required BillRepository billRepository,
  }) : _paymentRepository = paymentRepository,
       _billRepository = billRepository;

  // State
  List<ShareModel> _unpaidShares = [];
  bool _isProcessing = false;
  String? _error;
  String? _paymentUrl;

  // Getters
  List<ShareModel> get unpaidShares => _unpaidShares;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get paymentUrl => _paymentUrl;

  /// Get unpaid shares for the current user
  /// Fetches all bills and extracts unpaid shares
  Future<void> getUnpaidShares() async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Get all bills
      final bills = await _billRepository.getBills();

      // Extract unpaid shares from all bills
      _unpaidShares = [];
      for (final bill in bills) {
        final unpaid = bill.shares
            .where((share) => share.status == ShareStatus.unpaid)
            .toList();
        _unpaidShares.addAll(unpaid);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Initiate payment for a share
  /// Returns the checkout URL for the payment
  Future<bool> initiatePayment({
    required int shareId,
    required String paymentMethod,
  }) async {
    _isProcessing = true;
    _error = null;
    _paymentUrl = null;
    notifyListeners();

    try {
      final response = await _paymentRepository.initiatePayment(
        shareId: shareId,
        paymentMethod: paymentMethod,
      );

      _paymentUrl = response['checkout_url'] as String;
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark a share as paid locally (after successful payment)
  /// This updates the local state before sync
  void markShareAsPaid(int shareId) {
    final index = _unpaidShares.indexWhere((s) => s.id == shareId);
    if (index != -1) {
      _unpaidShares.removeAt(index);
      notifyListeners();
    }
  }

  /// Get total amount owed (sum of unpaid shares)
  double get totalOwed {
    return _unpaidShares.fold<double>(0.0, (sum, share) => sum + share.amount);
  }

  /// Clear payment URL after navigation
  void clearPaymentUrl() {
    _paymentUrl = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
