import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_it/core/providers/app_providers.dart';
import '../../data/repositories/geofence_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/office_model.dart';
import '../api/api_exception.dart';

final geofenceRepositoryProvider = Provider((ref) => GeofenceRepository());
final adminRepositoryProvider = Provider((ref) => AdminRepository());

final officesProvider = FutureProvider<List<OfficeModel>>((ref) async {
  final repo = ref.read(geofenceRepositoryProvider);
  final res = await repo.getOffices();
  if (res.isSuccess) return res.data;
  throw res.error;
});

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final res = await repo.getStats();
  if (res.isSuccess) return res.data;
  throw res.error;
});

final allAttendanceDateProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, date) async {
  final repo = ref.read(adminRepositoryProvider);
  final res = await repo.getAllAttendance(date);
  if (!res.isSuccess) throw res.error;

  final records = List<Map<String, dynamic>>.from(res.data);
  final recordUserIds = records.map((r) => r['userId'].toString()).toSet();

  try {
    final allUsers = await ref.read(allUsersProvider.future);
    for (final u in allUsers) {
      if (u.isActive && !recordUserIds.contains(u.id)) {
        records.add({
          'userId': u.id,
          'userName': u.name,
          'status': 'Absent',
          'punchInTime': null,
          'punchOutTime': null,
        });
      }
    }
  } catch (_) {}

  // Sort records
  records.sort((a, b) {
    if (a['status'] == 'Present' && b['status'] != 'Present') return -1;
    if (b['status'] == 'Present' && a['status'] != 'Present') return 1;
    final nameA = (a['userName'] ?? '').toString().toLowerCase();
    final nameB = (b['userName'] ?? '').toString().toLowerCase();
    return nameA.compareTo(nameB);
  });

  return records;
});

final userAttendanceHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final repo = ref.read(adminRepositoryProvider);
  final res = await repo.getUserAttendance(userId);
  if (!res.isSuccess) throw res.error;

  final list = List<Map<String, dynamic>>.from(res.data);
  list.sort((a, b) {
    final dateA = (a['date'] ?? a['createdAt'] ?? '').toString();
    final dateB = (b['date'] ?? b['createdAt'] ?? '').toString();
    return dateB.compareTo(dateA); // Newest date first
  });
  return list;
});
