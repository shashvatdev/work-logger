import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../data/models/models.dart';

/// Project repository — all 10 project endpoints
class ProjectRepository {
  final Dio _dio = ApiClient.instance;

  // ─── GET /projects ─────────────────────────────────────────────────────────
  Future<ApiResult<List<ProjectModel>>> getProjects({
    String archived = 'false',
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.projects,
        queryParameters: {'archived': archived, 'page': page, 'pageSize': pageSize},
      );
      if (resp.statusCode == 200) {
        final list = (resp.data['projects'] as List)
            .map((p) => ProjectModel.fromJson(p))
            .toList();
        return ApiSuccess(list);
      }
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to load projects',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /projects (Admin) ────────────────────────────────────────────────
  Future<ApiResult<ProjectModel>> createProject({
    required String name,
    String? description,
  }) async {
    try {
      final resp = await _dio.post(ApiEndpoints.projects, data: {
        'name': name,
        if (description != null) 'description': description,
      });
      if (resp.statusCode == 201) return ApiSuccess(ProjectModel.fromJson(resp.data));
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to create project',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /projects/{id} ───────────────────────────────────────────────────
  Future<ApiResult<ProjectModel>> getProjectById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.projectById(id));
      if (resp.statusCode == 200) return ApiSuccess(ProjectModel.fromJson(resp.data));
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Project not found',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /projects/{id}/update (Admin) ───────────────────────────────────
  Future<ApiResult<ProjectModel>> updateProject(
    String id, {
    required String name,
    String? description,
  }) async {
    try {
      final resp = await _dio.post(ApiEndpoints.projectUpdate(id), data: {
        'name': name,
        if (description != null) 'description': description,
      });
      if (resp.statusCode == 200) return ApiSuccess(ProjectModel.fromJson(resp.data));
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Update failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /projects/{id}/delete (Admin) ───────────────────────────────────
  Future<ApiResult<void>> deleteProject(String id) async {
    try {
      final resp = await _dio.post(ApiEndpoints.projectDelete(id));
      if (resp.statusCode == 204) return const ApiSuccess(null);
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Delete failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /projects/{id}/archive (Admin) ──────────────────────────────────
  Future<ApiResult<ProjectModel>> archiveProject(
      String id, bool isArchived) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.projectArchive(id),
        data: {'isArchived': isArchived},
      );
      if (resp.statusCode == 200) return ApiSuccess(ProjectModel.fromJson(resp.data));
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Archive failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /projects/{id}/members ───────────────────────────────────────────
  Future<ApiResult<List<Map<String, dynamic>>>> getProjectMembers(
      String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.projectMembers(id));
      if (resp.statusCode == 200) {
        final list =
            (resp.data as List).cast<Map<String, dynamic>>();
        return ApiSuccess(list);
      }
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /projects/{id}/members (Admin) ──────────────────────────────────
  Future<ApiResult<void>> addProjectMember(
      String projectId, String userId) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.projectMembers(projectId),
        data: {'userId': userId},
      );
      if (resp.statusCode == 201) return const ApiSuccess(null);
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to assign member',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /projects/{id}/members/{userId}/remove (Admin) ──────────────────
  Future<ApiResult<void>> removeProjectMember(
      String projectId, String userId) async {
    try {
      final resp =
          await _dio.post(ApiEndpoints.projectMemberRemove(projectId, userId));
      if (resp.statusCode == 204) return const ApiSuccess(null);
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to remove member',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /projects/{id}/timeline ─────────────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> getProjectTimeline(
    String id, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.projectTimeline(id),
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      if (resp.statusCode == 200) return ApiSuccess(resp.data);
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to load timeline',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
