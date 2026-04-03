import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/data/datasources/remote/group_remote_datasource.dart';

@GenerateMocks([ApiClient])
import 'group_remote_datasource_test.mocks.dart';

void main() {
  late GroupRemoteDataSource dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = GroupRemoteDataSource(apiClient: mockApiClient);
  });

  group('GroupRemoteDataSource - createGroup', () {
    test('should call POST /api/groups with correct parameters', () async {
      // Arrange
      final mockResponse = {
        'id': 1,
        'name': 'Test Group',
        'creator_id': 1,
        'created_at': '2024-01-01T00:00:00.000000Z',
        'members': [],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.createGroup(name: 'Test Group');

      // Assert
      verify(
        mockApiClient.post('/api/groups', {'name': 'Test Group'}),
      ).called(1);
      expect(result.id, 1);
      expect(result.name, 'Test Group');
    });

    test('should parse response correctly', () async {
      // Arrange
      final mockResponse = {
        'id': 42,
        'name': 'My Group',
        'creator_id': 5,
        'created_at': '2024-03-15T10:30:00.000000Z',
        'members': [],
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.createGroup(name: 'My Group');

      // Assert
      expect(result.id, 42);
      expect(result.name, 'My Group');
      expect(result.creatorId, 5);
    });

    test('should throw ApiException on validation error', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Validation error', statusCode: 422));

      // Act & Assert
      expect(
        () => dataSource.createGroup(name: ''),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });
  });

  group('GroupRemoteDataSource - getGroups', () {
    test('should call GET /api/groups', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'name': 'Group 1',
            'creator_id': 1,
            'created_at': '2024-01-01T00:00:00.000000Z',
            'members': [],
          },
        ],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getGroups();

      // Assert
      verify(mockApiClient.get('/api/groups')).called(1);
      expect(result.length, 1);
      expect(result[0].name, 'Group 1');
    });

    test('should parse multiple groups correctly', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'name': 'Group 1',
            'creator_id': 1,
            'created_at': '2024-01-01T00:00:00.000000Z',
            'members': [],
          },
          {
            'id': 2,
            'name': 'Group 2',
            'creator_id': 2,
            'created_at': '2024-01-02T00:00:00.000000Z',
            'members': [],
          },
        ],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getGroups();

      // Assert
      expect(result.length, 2);
      expect(result[0].name, 'Group 1');
      expect(result[1].name, 'Group 2');
    });
  });

  group('GroupRemoteDataSource - getInvitations', () {
    test('should call GET /api/invitations', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'group_id': 1,
            'group_name': 'Test Group',
            'inviter_id': 2,
            'inviter_username': 'inviter',
            'invitee_id': 3,
            'status': 'pending',
            'created_at': '2024-01-01T00:00:00.000000Z',
          },
        ],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getInvitations();

      // Assert
      verify(mockApiClient.get('/api/invitations')).called(1);
      expect(result.length, 1);
      expect(result[0].groupName, 'Test Group');
    });

    test('should parse invitations correctly', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 1,
            'group_id': 1,
            'group_name': 'Group A',
            'inviter_id': 2,
            'inviter_username': 'user2',
            'invitee_id': 3,
            'status': 'pending',
            'created_at': '2024-01-01T00:00:00.000000Z',
          },
        ],
      };

      when(mockApiClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.getInvitations();

      // Assert
      expect(result[0].id, 1);
      expect(result[0].groupId, 1);
      expect(result[0].inviterUsername, 'user2');
    });
  });

  group('GroupRemoteDataSource - sendInvitation', () {
    test(
      'should call POST /api/groups/{id}/invitations with identifier',
      () async {
        // Arrange
        final mockResponse = {
          'id': 1,
          'group_id': 1,
          'inviter_id': 1,
          'invitee_id': 2,
          'status': 'pending',
          'created_at': '2024-01-01T00:00:00.000000Z',
        };

        when(
          mockApiClient.post(any, any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await dataSource.sendInvitation(
          groupId: 1,
          identifier: 'user@example.com',
        );

        // Assert
        verify(
          mockApiClient.post('/api/groups/1/invitations', {
            'identifier': 'user@example.com',
          }),
        ).called(1);
        expect(result.id, 1);
        expect(result.status, 'pending');
      },
    );

    test('should parse invitation response correctly', () async {
      // Arrange
      final mockResponse = {
        'id': 5,
        'group_id': 3,
        'inviter_id': 1,
        'invitee_id': 4,
        'status': 'pending',
        'created_at': '2024-03-15T10:30:00.000000Z',
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.sendInvitation(
        groupId: 3,
        identifier: 'newuser',
      );

      // Assert
      expect(result.id, 5);
      expect(result.groupId, 3);
      expect(result.inviteeId, 4);
    });

    test('should throw ApiException on user not found', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('User not found', statusCode: 404));

      // Act & Assert
      expect(
        () => dataSource.sendInvitation(
          groupId: 1,
          identifier: 'nonexistent@example.com',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('GroupRemoteDataSource - acceptInvitation', () {
    test('should call POST /api/invitations/{id}/accept', () async {
      // Arrange
      final mockResponse = {
        'group': {
          'id': 1,
          'name': 'Test Group',
          'creator_id': 1,
          'created_at': '2024-01-01T00:00:00.000000Z',
          'members': [],
        },
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.acceptInvitation(invitationId: 1);

      // Assert
      verify(mockApiClient.post('/api/invitations/1/accept', {})).called(1);
      expect(result.id, 1);
      expect(result.name, 'Test Group');
    });

    test('should parse group response correctly', () async {
      // Arrange
      final mockResponse = {
        'group': {
          'id': 5,
          'name': 'Accepted Group',
          'creator_id': 2,
          'created_at': '2024-03-15T10:30:00.000000Z',
          'members': [],
        },
      };

      when(mockApiClient.post(any, any)).thenAnswer((_) async => mockResponse);

      // Act
      final result = await dataSource.acceptInvitation(invitationId: 5);

      // Assert
      expect(result.id, 5);
      expect(result.name, 'Accepted Group');
    });
  });

  group('GroupRemoteDataSource - declineInvitation', () {
    test('should call POST /api/invitations/{id}/decline', () async {
      // Arrange
      when(mockApiClient.post(any, any)).thenAnswer((_) async => {});

      // Act
      await dataSource.declineInvitation(invitationId: 1);

      // Assert
      verify(mockApiClient.post('/api/invitations/1/decline', {})).called(1);
    });
  });

  group('GroupRemoteDataSource - removeMember', () {
    test('should call DELETE /api/groups/{id}/members/{userId}', () async {
      // Arrange
      when(mockApiClient.delete(any)).thenAnswer((_) async => {});

      // Act
      await dataSource.removeMember(groupId: 1, userId: 2);

      // Assert
      verify(mockApiClient.delete('/api/groups/1/members/2')).called(1);
    });

    test('should throw ApiException on forbidden', () async {
      // Arrange
      when(
        mockApiClient.delete(any),
      ).thenThrow(ApiException('Forbidden', statusCode: 403));

      // Act & Assert
      expect(
        () => dataSource.removeMember(groupId: 1, userId: 2),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('GroupRemoteDataSource - leaveGroup', () {
    test('should call POST /api/groups/{id}/leave', () async {
      // Arrange
      when(mockApiClient.post(any, any)).thenAnswer((_) async => {});

      // Act
      await dataSource.leaveGroup(groupId: 1);

      // Assert
      verify(mockApiClient.post('/api/groups/1/leave', {})).called(1);
    });

    test('should throw ApiException on forbidden', () async {
      // Arrange
      when(
        mockApiClient.post(any, any),
      ).thenThrow(ApiException('Forbidden', statusCode: 403));

      // Act & Assert
      expect(
        () => dataSource.leaveGroup(groupId: 1),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });
}
