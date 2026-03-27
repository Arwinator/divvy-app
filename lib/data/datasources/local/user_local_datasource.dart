import 'package:divvy/data/models/models.dart';
import 'package:divvy/core/storage/database_helper.dart';

/// Local data source for User operations using SQLite
class UserLocalDataSource {
  final DatabaseHelper _dbHelper;

  UserLocalDataSource(this._dbHelper);

  /// Save user to local database
  Future<void> saveUser(UserModel user) async {
    await _dbHelper.insert('users', user.toMap());
  }

  /// Get user from local database by ID
  Future<UserModel?> getUser(int userId) async {
    final results = await _dbHelper.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Delete user from local database
  Future<void> deleteUser(int userId) async {
    await _dbHelper.delete('users', where: 'id = ?', whereArgs: [userId]);
  }
}
