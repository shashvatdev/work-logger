import 'package:intl/intl.dart';
import '../models/models.dart';

// ─── USERS ───────────────────────────────────────────────────────────────────
final mockUsers = <UserModel>[
  UserModel(
    id: 'admin_1',
    name: 'Shashvat',
    email: 'shashvat@worklog.app',
    role: UserRole.admin,
  ),
  UserModel(
    id: 'emp_1',
    name: 'Rahul Sharma',
    email: 'rahul@worklog.app',
    role: UserRole.employee,
  ),
  UserModel(
    id: 'emp_2',
    name: 'Aman Verma',
    email: 'aman@worklog.app',
    role: UserRole.employee,
  ),
  UserModel(
    id: 'emp_3',
    name: 'Priya Singh',
    email: 'priya@worklog.app',
    role: UserRole.employee,
  ),
  UserModel(
    id: 'emp_4',
    name: 'Karan Mehta',
    email: 'karan@worklog.app',
    role: UserRole.employee,
  ),
];

// ─── PROJECTS ────────────────────────────────────────────────────────────────
final mockProjects = <ProjectModel>[
  ProjectModel(
    id: 'proj_1',
    name: 'Credvisor',
    description: 'Credit management & financial analytics platform',
    archived: false,
    createdAt: DateTime(2026, 1, 10),
    memberIds: ['admin_1', 'emp_1', 'emp_2', 'emp_3'],
  ),
  ProjectModel(
    id: 'proj_2',
    name: 'Pharma ERP',
    description: 'Enterprise resource planning for pharmaceutical companies',
    archived: false,
    createdAt: DateTime(2026, 2, 5),
    memberIds: ['admin_1', 'emp_1', 'emp_4'],
  ),
  ProjectModel(
    id: 'proj_3',
    name: 'Inventory App',
    description: 'Real-time inventory management for retail chains',
    archived: false,
    createdAt: DateTime(2026, 3, 15),
    memberIds: ['admin_1', 'emp_2', 'emp_3', 'emp_4'],
  ),
  ProjectModel(
    id: 'proj_4',
    name: 'Legacy Portal',
    description: 'Old customer portal — archived',
    archived: true,
    createdAt: DateTime(2025, 6, 1),
    memberIds: ['admin_1', 'emp_1'],
  ),
];

// ─── LOGS ────────────────────────────────────────────────────────────────────
String _key(String uid, DateTime date) =>
    '${uid}_${DateFormat('yyyy-MM-dd').format(date)}';

String _dateStr(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

final DateTime _today = DateTime.now();

final Map<String, DailyLogModel> mockDailyLogs = {
  // ── Rahul Sharma ────────────────────────────────────────────────────────────
  _key('emp_1', _today.subtract(const Duration(days: 1))): DailyLogModel(
    id: _key('emp_1', _today.subtract(const Duration(days: 1))),
    userId: 'emp_1',
    date: _dateStr(_today.subtract(const Duration(days: 1))),
    updatedAt: _today.subtract(const Duration(days: 1, hours: 2)),
    entries: [
      LogEntryModel(
        id: 'entry_r1',
        logId: _key('emp_1', _today.subtract(const Duration(days: 1))),
        projectId: 'proj_1',
        description:
            'Fixed the OTP timeout issue in the login flow. The session was expiring too early due to a misconfigured timer. Updated the backend call to refresh token on activity.',
      ),
      LogEntryModel(
        id: 'entry_r2',
        logId: _key('emp_1', _today.subtract(const Duration(days: 1))),
        projectId: 'proj_2',
        description:
            'Reviewed the pharmacy module API contracts with the backend team. Mapped out the data flow for purchase orders.',
      ),
    ],
  ),
  _key('emp_1', _today.subtract(const Duration(days: 3))): DailyLogModel(
    id: _key('emp_1', _today.subtract(const Duration(days: 3))),
    userId: 'emp_1',
    date: _dateStr(_today.subtract(const Duration(days: 3))),
    updatedAt: _today.subtract(const Duration(days: 3, hours: 1)),
    entries: [
      LogEntryModel(
        id: 'entry_r3',
        logId: _key('emp_1', _today.subtract(const Duration(days: 3))),
        projectId: 'proj_1',
        description:
            'Implemented the Dashboard screen — line chart for credit utilization. Added filter by date range and export to PDF.',
      ),
    ],
  ),
  _key('emp_1', _today.subtract(const Duration(days: 7))): DailyLogModel(
    id: _key('emp_1', _today.subtract(const Duration(days: 7))),
    userId: 'emp_1',
    date: _dateStr(_today.subtract(const Duration(days: 7))),
    updatedAt: _today.subtract(const Duration(days: 7, hours: 3)),
    entries: [
      LogEntryModel(
        id: 'entry_r4',
        logId: _key('emp_1', _today.subtract(const Duration(days: 7))),
        projectId: 'proj_1',
        description:
            'Resend OTP implementation. Added 30-second cooldown with animated countdown timer.',
      ),
    ],
  ),
  _key('emp_1', _today.subtract(const Duration(days: 10))): DailyLogModel(
    id: _key('emp_1', _today.subtract(const Duration(days: 10))),
    userId: 'emp_1',
    date: _dateStr(_today.subtract(const Duration(days: 10))),
    updatedAt: _today.subtract(const Duration(days: 10, hours: 4)),
    entries: [
      LogEntryModel(
        id: 'entry_r5',
        logId: _key('emp_1', _today.subtract(const Duration(days: 10))),
        projectId: 'proj_2',
        description:
            'Set up project structure for Pharma ERP. Configured routing, state management, and base API service layer.',
      ),
    ],
  ),

  // ── Aman Verma ─────────────────────────────────────────────────────────────
  _key('emp_2', _today): DailyLogModel(
    id: _key('emp_2', _today),
    userId: 'emp_2',
    date: _dateStr(_today),
    updatedAt: _today,
    entries: [
      LogEntryModel(
        id: 'entry_a1',
        logId: _key('emp_2', _today),
        projectId: 'proj_1',
        description:
            'Completed testing of the login module — 23 test cases passed, 2 edge cases flagged. Raised issues on the internal tracker.',
      ),
      LogEntryModel(
        id: 'entry_a2',
        logId: _key('emp_2', _today),
        projectId: 'proj_3',
        description:
            'Worked on inventory sync logic — pull-to-refresh and conflict resolution when two devices update stock simultaneously.',
      ),
    ],
  ),
  _key('emp_2', _today.subtract(const Duration(days: 2))): DailyLogModel(
    id: _key('emp_2', _today.subtract(const Duration(days: 2))),
    userId: 'emp_2',
    date: _dateStr(_today.subtract(const Duration(days: 2))),
    updatedAt: _today.subtract(const Duration(days: 2, hours: 2)),
    entries: [
      LogEntryModel(
        id: 'entry_a3',
        logId: _key('emp_2', _today.subtract(const Duration(days: 2))),
        projectId: 'proj_3',
        description:
            'Built the barcode scanner integration using flutter_barcode_scanner. Tested with 15 different product codes.',
      ),
    ],
  ),

  // ── Priya Singh ─────────────────────────────────────────────────────────────
  _key('emp_3', _today.subtract(const Duration(days: 1))): DailyLogModel(
    id: _key('emp_3', _today.subtract(const Duration(days: 1))),
    userId: 'emp_3',
    date: _dateStr(_today.subtract(const Duration(days: 1))),
    updatedAt: _today.subtract(const Duration(days: 1, hours: 1)),
    entries: [
      LogEntryModel(
        id: 'entry_p1',
        logId: _key('emp_3', _today.subtract(const Duration(days: 1))),
        projectId: 'proj_1',
        description:
            'Designed the onboarding flow screens in Figma and handed off assets. Reviewed UI feedback from the client.',
      ),
    ],
  ),

  // ── Karan Mehta ─────────────────────────────────────────────────────────────
  _key('emp_4', _today): DailyLogModel(
    id: _key('emp_4', _today),
    userId: 'emp_4',
    date: _dateStr(_today),
    updatedAt: _today,
    entries: [
      LogEntryModel(
        id: 'entry_k1',
        logId: _key('emp_4', _today),
        projectId: 'proj_3',
        description:
            'Implemented the low-stock alert system — notifications fire when any SKU drops below the set threshold.',
      ),
    ],
  ),
};
