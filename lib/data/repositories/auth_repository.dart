import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/core/storage/secure_storage.dart';
import 'package:divvy/data/models/models.dart';

/// Repository for authentication operations
/// Coordinates between remote API and local storage
class AuthRepository {
  final remote.AuthRemoteDataSource remoteDataSource;
  final local.UserLocalDataSource localDataSource;
  final SecureStorage secureStorage;

  AuthRepository({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.secureStorage,
  });

  /// Register a new user
  /// Saves user data and token locally after successful registration
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String fcmToken,
    required String deviceId,
  }) async {
    final response = await remoteDataSource.register(
      username: username,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      fcmToken: fcmToken,
      deviceId: deviceId,
    );

    // Save user locally
    await localDataSource.saveUser(response.user);

    // Save authentication token
    await secureStorage.saveToken(response.token);
    await secureStorage.saveUserId(response.user.id.toString());

    return response.user;
  }

  /// Login existing user
  /// Saves user data and token locally after successful login
  Future<UserModel> login({
    required String email,
    required String password,
    required String fcmToken,
    required String deviceId,
  }) async {
    final response = await remoteDataSource.login(
      email: email,
      password: password,
      fcmToken: fcmToken,
      deviceId: deviceId,
    );

    // Save user locally
    await localDataSource.saveUser(response.user);

    // Save authentication token
    await secureStorage.saveToken(response.token);
    await secureStorage.saveUserId(response.user.id.toString());

    return response.user;
  }

  /// Logout current user
  /// Clears local user data and token after successful logout
  Future<void> logout() async {
    // Call remote logout first
    await remoteDataSource.logout();

    // Clear local data
    final userId = await secureStorage.getUserId();
    if (userId != null) {
      await localDataSource.deleteUser(int.parse(userId));
    }

    // Clear secure storage
    await secureStorage.clearAll();
  }

  /// Get currently logged in user from local storage
  Future<UserModel?> getCurrentUser() async {
    final userId = await secureStorage.getUserId();
    if (userId == null) return null;

    return await localDataSource.getUser(int.parse(userId));
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
