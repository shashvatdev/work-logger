/// All API endpoint constants — single source of truth
class ApiEndpoints {
  ApiEndpoints._();

  // ── AUTH ────────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';

  // ── USERS ───────────────────────────────────────────────────────────────────
  static const String users = '/users';
  static const String usersMe = '/users/me';
  static const String usersMeUpdate = '/users/me/update';
  static String userById(String id) => '/users/$id';
  static String userUpdate(String id) => '/users/$id/update';
  static String userDelete(String id) => '/users/$id/delete';
  static String userTodayStatus(String id) => '/users/$id/today-status';
  static String userLogs(String id) => '/users/$id/logs';

  // ── PROJECTS ─────────────────────────────────────────────────────────────────
  static const String projects = '/projects';
  static String projectById(String id) => '/projects/$id';
  static String projectUpdate(String id) => '/projects/$id/update';
  static String projectDelete(String id) => '/projects/$id/delete';
  static String projectArchive(String id) => '/projects/$id/archive';
  static String projectMembers(String id) => '/projects/$id/members';
  static String projectMemberById(String id, String uid) =>
      '/projects/$id/members/$uid';
  static String projectMemberRemove(String id, String uid) =>
      '/projects/$id/members/$uid/remove';
  static String projectTimeline(String id) => '/projects/$id/timeline';

  // ── LOGS ─────────────────────────────────────────────────────────────────────
  static const String logs = '/logs';
  static const String logsToday = '/logs/today';
  static String logByDate(String date) => '/logs/$date';
  static String logById(String id) => '/logs/$id';
  static String logUpdate(String id) => '/logs/$id/update';
  static String logsByUser(String uid) => '/logs/user/$uid';
  static String logByUserAndDate(String uid, String date) =>
      '/logs/user/$uid/$date';

  // ── ATTACHMENTS ───────────────────────────────────────────────────────────────
  static const String attachments = '/attachments';
  static String attachmentById(String id) => '/attachments/$id';
  static String attachmentDelete(String id) => '/attachments/$id/delete';
  static String attachmentDownload(String id) => '/attachments/$id/download';

  // ── SEARCH ───────────────────────────────────────────────────────────────────
  static const String search = '/search';
}
