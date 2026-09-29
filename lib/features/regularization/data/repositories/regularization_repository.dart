import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/regularization_request.dart';

final regularizationRepoProvider = Provider((ref) => RegularizationRepository(ApiClient.instance));

class RegularizationRepository {
  final Dio _api;
  RegularizationRepository(this._api);

  Future<List<RegularizationRequest>> getMyRequests() async {
    final res = await _api.get('/attendance-requests/my');
    final data = res.data;
    List raw = [];
    if (data is Map) {
      raw = data['records'] ?? data['items'] ?? data['data'] ?? data['requests'] ?? [];
    } else if (data is List) {
      raw = data;
    }
    return raw.map((e) => RegularizationRequest.fromJson(e)).toList();
  }

  Future<List<RegularizationRequest>> getAllRequests() async {
    final res = await _api.get('/attendance-requests/all');
    final data = res.data;
    List raw = [];
    if (data is Map) {
      raw = data['records'] ?? data['items'] ?? data['data'] ?? data['requests'] ?? [];
    } else if (data is List) {
      raw = data;
    }
    return raw.map((e) => RegularizationRequest.fromJson(e)).toList();
  }

  Future<void> submitRequest({
    required String date,
    String? punchIn,
    String? punchOut,
    required String reason,
  }) async {
    await _api.post('/attendance-requests', data: {
      'date': date,
      if (punchIn != null) 'requestedPunchInTime': punchIn,
      if (punchOut != null) 'requestedPunchOutTime': punchOut,
      'reason': reason,
    });
  }

  Future<void> approveRequest(String id, String? notes) async {
    await _api.post('/attendance-requests/$id/approve', data: {
      if (notes != null && notes.isNotEmpty) 'adminNotes': notes,
    });
  }

  Future<void> rejectRequest(String id, String? notes) async {
    await _api.post('/attendance-requests/$id/reject', data: {
      if (notes != null && notes.isNotEmpty) 'adminNotes': notes,
    });
  }
}
