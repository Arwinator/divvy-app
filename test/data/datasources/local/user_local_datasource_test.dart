import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart';
import 'package:divvy/data/models/models.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late TestDatabaseHelper databaseHelper;
  late UserLocalDataSource dataSource;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await createTestDatabase();
    databaseHelper = TestDatabaseHelper(db);
    dataSource = UserLocalDataSource(databaseHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserLocalDataSource - Save Operations', () {
    test('saveUser inserts user into database', () async {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      await dataSource.saveUser(user);

      final users = await databaseHelper.query('users');
      expect(users.length, 1);
      expect(users[0]['username'], 'testuser');
      expect(users[0]['email'], 'test@example.com');
    });

    test('saveUser replaces existing user with same ID', () async {
      final user1 = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      await dataSource.saveUser(user1);

      final user2 = UserModel(
        id: 1,
        username: 'updateduser',
        email: 'updated@example.com',
        createdAt: DateTime.now(),
      );

      await dataSource.saveUser(user2);

      final users = await databaseHelper.query('users');
      expect(users.length, 1);
      expect(users[0]['username'], 'updateduser');
    });
  });

  group('UserLocalDataSource - Get Operations', () {
    test('getUser returns user when exists', () async {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      await dataSource.saveUser(user);

      final retrieved = await dataSource.getUser(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 1);
      expect(retrieved.username, 'testuser');
      expect(retrieved.email, 'test@example.com');
    });

    test('getUser returns null when user does not exist', () async {
      final retrieved = await dataSource.getUser(999);

      expect(retrieved, isNull);
    });

    test('getUser returns correct user when multiple users exist', () async {
      for (int i = 1; i <= 3; i++) {
        await dataSource.saveUser(
          UserModel(
            id: i,
            username: 'user$i',
            email: 'user$i@example.com',
            createdAt: DateTime.now(),
          ),
        );
      }

      final retrieved = await dataSource.getUser(2);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 2);
      expect(retrieved.username, 'user2');
    });
  });

  group('UserLocalDataSource - Delete Operations', () {
    test('deleteUser removes user from database', () async {
      final user = UserModel(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      await dataSource.saveUser(user);
      await dataSource.deleteUser(1);

      final users = await databaseHelper.query('users');
      expect(users, isEmpty);
    });

    test('deleteUser does not affect other users', () async {
      for (int i = 1; i <= 3; i++) {
        await dataSource.saveUser(
          UserModel(
            id: i,
            username: 'user$i',
            email: 'user$i@example.com',
            createdAt: DateTime.now(),
          ),
        );
      }

      await dataSource.deleteUser(2);

      final users = await databaseHelper.query('users');
      expect(users.length, 2);
      expect(users.any((u) => u['id'] == 1), isTrue);
      expect(users.any((u) => u['id'] == 3), isTrue);
    });

    test('deleteUser succeeds even when user does not exist', () async {
      await dataSource.deleteUser(999);

      final users = await databaseHelper.query('users');
      expect(users, isEmpty);
    });
  });

  group('UserLocalDataSource - Edge Cases', () {
    test('saveUser handles special characters in username and email', () async {
      final user = UserModel(
        id: 1,
        username: "user'with\"quotes",
        email: 'test+tag@example.com',
        createdAt: DateTime.now(),
      );

      await dataSource.saveUser(user);

      final retrieved = await dataSource.getUser(1);
      expect(retrieved!.username, "user'with\"quotes");
      expect(retrieved.email, 'test+tag@example.com');
    });
  });
}
