import 'package:flutter/foundation.dart';
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/services/services.dart';

/// ViewModel for authentication operations
/// Manages authentication state and coordinates with AuthRepository
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final NotificationService _notificationService;

  AuthViewModel({
    required AuthRepository repository,
    required NotificationService notificationService,
  }) : _repository = repository,
       _notificationService = notificationService;

  // State
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Initialize authentication state
  /// Loads current user from local storage if authenticated
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isAuth = await _repository.isAuthenticated();
      if (isAuth) {
        _currentUser = await _repository.getCurrentUser();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user
  /// Automatically retrieves FCM token and device ID from NotificationService
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get FCM token and device ID from NotificationService
      final fcmToken = _notificationService.fcmToken;
      final deviceId = _notificationService.deviceId;

      if (fcmToken == null || deviceId == null) {
        throw Exception(
          'Failed to get FCM token or device ID. Please check notification permissions.',
        );
      }

      _currentUser = await _repository.register(
        username: username,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        fcmToken: fcmToken,
        deviceId: deviceId,
      );
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

  /// Login existing user
  /// Automatically retrieves FCM token and device ID from NotificationService
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get FCM token and device ID from NotificationService
      final fcmToken = _notificationService.fcmToken;
      final deviceId = _notificationService.deviceId;

      if (fcmToken == null || deviceId == null) {
        throw Exception(
          'Failed to get FCM token or device ID. Please check notification permissions.',
        );
      }

      _currentUser = await _repository.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
        deviceId: deviceId,
      );
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

  /// Logout current user
  Future<bool> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.logout();
      _currentUser = null;
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

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
