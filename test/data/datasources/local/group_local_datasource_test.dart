import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart';
import 'package:divvy/data/models/models.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late TestDatabaseHelper databaseHelper;
  late GroupLocalDataSource dataSource;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await createTestDatabase();
    databaseHelper = TestDatabaseHelper(db);
    dataSource = GroupLocalDataSource(databaseHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('GroupLocalDataSource - Save Operations', () {
    test('saveGroup inserts group and members into database', () async {
      final members = [
        UserModel(
          id: 1,
          username: 'user1',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 2,
          username: 'user2',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final group = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: members,
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group);

      final groups = await databaseHelper.query('groups');
      expect(groups.length, 1);
      expect(groups[0]['name'], 'Test Group');

      final groupMembers = await databaseHelper.query('group_members');
      expect(groupMembers.length, 2);
    });

    test('saveGroup replaces existing group with same ID', () async {
      final members1 = [
        UserModel(
          id: 1,
          username: 'user1',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final group1 = GroupModel(
        id: 1,
        name: 'Original Group',
        creatorId: 1,
        members: members1,
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group1);

      final members2 = [
        UserModel(
          id: 2,
          username: 'user2',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final group2 = GroupModel(
        id: 1,
        name: 'Updated Group',
        creatorId: 1,
        members: members2,
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group2);

      final groups = await databaseHelper.query('groups');
      expect(groups.length, 1);
      expect(groups[0]['name'], 'Updated Group');
    });
  });

  group('GroupLocalDataSource - Get Operations', () {
    test('getGroups returns all groups with members', () async {
      final members1 = [
        UserModel(
          id: 1,
          username: 'user1',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final members2 = [
        UserModel(
          id: 2,
          username: 'user2',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      await dataSource.saveGroup(
        GroupModel(
          id: 1,
          name: 'Group 1',
          creatorId: 1,
          members: members1,
          createdAt: DateTime.now(),
          isSynced: true,
        ),
      );

      await dataSource.saveGroup(
        GroupModel(
          id: 2,
          name: 'Group 2',
          creatorId: 2,
          members: members2,
          createdAt: DateTime.now(),
          isSynced: true,
        ),
      );

      final groups = await dataSource.getGroups();

      expect(groups.length, 2);
      expect(groups[0].members.length, 1);
      expect(groups[1].members.length, 1);
    });

    test('getGroups returns empty list when no groups exist', () async {
      final groups = await dataSource.getGroups();

      expect(groups, isEmpty);
    });

    test('getGroupById returns group with members when exists', () async {
      final members = [
        UserModel(
          id: 1,
          username: 'user1',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 2,
          username: 'user2',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final group = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: members,
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group);

      final retrieved = await dataSource.getGroupById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 1);
      expect(retrieved.name, 'Test Group');
      expect(retrieved.members.length, 2);
      expect(retrieved.members[0].username, 'user1');
    });

    test('getGroupById returns null when group does not exist', () async {
      final retrieved = await dataSource.getGroupById(999);

      expect(retrieved, isNull);
    });
  });

  group('GroupLocalDataSource - Delete Operations', () {
    test('deleteGroup removes group from database', () async {
      final members = [
        UserModel(
          id: 1,
          username: 'user1',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final group = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: members,
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group);
      await dataSource.deleteGroup(1);

      final groups = await databaseHelper.query('groups');
      expect(groups, isEmpty);
    });

    test('deleteGroup does not affect other groups', () async {
      for (int i = 1; i <= 3; i++) {
        await dataSource.saveGroup(
          GroupModel(
            id: i,
            name: 'Group $i',
            creatorId: 1,
            members: [],
            createdAt: DateTime.now(),
            isSynced: true,
          ),
        );
      }

      await dataSource.deleteGroup(2);

      final groups = await databaseHelper.query('groups');
      expect(groups.length, 2);
    });
  });

  group('GroupLocalDataSource - Upsert Operations', () {
    test('upsertGroups inserts new groups', () async {
      final groups = [
        GroupModel(
          id: 1,
          name: 'Group 1',
          creatorId: 1,
          members: [],
          createdAt: DateTime.now(),
          isSynced: true,
        ),
        GroupModel(
          id: 2,
          name: 'Group 2',
          creatorId: 1,
          members: [],
          createdAt: DateTime.now(),
          isSynced: true,
        ),
      ];

      await dataSource.upsertGroups(groups);

      final savedGroups = await databaseHelper.query('groups');
      expect(savedGroups.length, 2);
    });

    test('upsertGroups updates existing groups', () async {
      final group1 = GroupModel(
        id: 1,
        name: 'Original Name',
        creatorId: 1,
        members: [],
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group1);

      final group2 = GroupModel(
        id: 1,
        name: 'Updated Name',
        creatorId: 1,
        members: [],
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.upsertGroups([group2]);

      final groups = await databaseHelper.query('groups');
      expect(groups.length, 1);
      expect(groups[0]['name'], 'Updated Name');
    });

    test('upsertGroups updates group members correctly', () async {
      final members1 = [
        UserModel(
          id: 1,
          username: 'user1',
          email: 'user1@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final group1 = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: members1,
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group1);

      final members2 = [
        UserModel(
          id: 2,
          username: 'user2',
          email: 'user2@example.com',
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 3,
          username: 'user3',
          email: 'user3@example.com',
          createdAt: DateTime.now(),
        ),
      ];

      final group2 = GroupModel(
        id: 1,
        name: 'Test Group',
        creatorId: 1,
        members: members2,
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.upsertGroups([group2]);

      final groupMembers = await databaseHelper.query('group_members');
      expect(groupMembers.length, 2);
    });
  });

  group('GroupLocalDataSource - Edge Cases', () {
    test('saveGroup handles group with no members', () async {
      final group = GroupModel(
        id: 1,
        name: 'Empty Group',
        creatorId: 1,
        members: [],
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group);

      final retrieved = await dataSource.getGroupById(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.members, isEmpty);
    });

    test('saveGroup handles special characters in group name', () async {
      final group = GroupModel(
        id: 1,
        name: "Group with 'quotes' and \"double quotes\"",
        creatorId: 1,
        members: [],
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await dataSource.saveGroup(group);

      final retrieved = await dataSource.getGroupById(1);
      expect(retrieved!.name, "Group with 'quotes' and \"double quotes\"");
    });
  });
}
