import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/user_model.dart';

/// Authentication response containing user and token
class AuthResponse {
  final UserModel user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'],
    );
  }
}

/// Remote data source for authentication operations
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  /// Register a new user
  /// POST /api/register
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String fcmToken,
    required String deviceId,
  }) async {
    final response = await apiClient.post(ApiConstants.register, {
      'username': username,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'fcm_token': fcmToken,
      'device_id': deviceId,
    });

    return AuthResponse.fromJson(response);
  }

  /// Login an existing user
  /// POST /api/login
  Future<AuthResponse> login({
    required String email,
    required String password,
    required String fcmToken,
    required String deviceId,
  }) async {
    final response = await apiClient.post(ApiConstants.login, {
      'email': email,
      'password': password,
      'fcm_token': fcmToken,
      'device_id': deviceId,
    });

    return AuthResponse.fromJson(response);
  }

  /// Logout the current user
  /// POST /api/logout
  Future<void> logout() async {
    await apiClient.post(ApiConstants.logout, {});
  }
}
