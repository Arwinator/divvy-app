import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:divvy/core/storage/database_helper.dart';

/// Creates a new in-memory database for testing.
/// Each call returns a fresh database instance, preventing lock conflicts.
Future<Database> createTestDatabase() async {
  return await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        // Users table
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Groups table
        await db.execute('''
          CREATE TABLE groups (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            creator_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 1
          )
        ''');

        // Group members table
        await db.execute('''
          CREATE TABLE group_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
          )
        ''');

        // Bills table
        await db.execute('''
          CREATE TABLE bills (
            id INTEGER PRIMARY KEY,
            group_id INTEGER NOT NULL,
            creator_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            total_amount REAL NOT NULL,
            bill_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
          )
        ''');

        // Shares table
        await db.execute('''
          CREATE TABLE shares (
            id INTEGER PRIMARY KEY,
            bill_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            status TEXT NOT NULL,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
          )
        ''');

        // Transactions table
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY,
            share_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            paymongo_transaction_id TEXT,
            status TEXT NOT NULL,
            paid_at TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (share_id) REFERENCES shares (id) ON DELETE CASCADE
          )
        ''');

        // Sync queue table
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            payload TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        // Create indexes for better query performance
        await db.execute(
          'CREATE INDEX idx_group_members_group_id ON group_members(group_id)',
        );
        await db.execute('CREATE INDEX idx_bills_group_id ON bills(group_id)');
        await db.execute('CREATE INDEX idx_shares_bill_id ON shares(bill_id)');
        await db.execute(
          'CREATE INDEX idx_transactions_user_id ON transactions(user_id)',
        );
      },
    ),
  );
}

/// Test-specific DatabaseHelper that uses in-memory databases.
/// This prevents database lock conflicts when running tests in parallel.
class TestDatabaseHelper implements DatabaseHelper {
  final Database _db;

  TestDatabaseHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    return await _db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    return await _db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    return await _db.update(table, data, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    return await _db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<void> close() async {
    await _db.close();
  }

  @override
  Future<void> clearAllTables() async {
    await _db.delete('users');
    await _db.delete('groups');
    await _db.delete('group_members');
    await _db.delete('bills');
    await _db.delete('shares');
    await _db.delete('transactions');
    await _db.delete('sync_queue');
  }
}
