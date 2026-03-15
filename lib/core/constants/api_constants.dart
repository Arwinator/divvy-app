class ApiConstants {
  // API URL
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Auth endpoints
  static const String register = '/api/register';
  static const String login = '/api/login';
  static const String logout = '/api/logout';

  // Group endpoints
  static const String groups = '/api/groups';
  static String groupMembers(int groupId) => '/api/groups/$groupId/members';
  static String groupInvitations(int groupId) =>
      '/api/groups/$groupId/invitations';
  static String acceptInvitation(int invitationId) =>
      '/api/invitations/$invitationId/accept';
  static String declineInvitation(int invitationId) =>
      '/api/invitations/$invitationId/decline';

  // Bill endpoints
  static const String bills = '/api/bills';
  static String billDetails(int billId) => '/api/bills/$billId';
  static String groupBills(int groupId) => '/api/groups/$groupId/bills';

  // Payment endpoints
  static String payShare(int shareId) => '/api/shares/$shareId/pay';
  static const String transactions = '/api/transactions';

  // Sync endpoints
  static const String sync = '/api/sync';
  static const String syncTimestamp = '/api/sync/timestamp';
}
