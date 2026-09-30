import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/organization_model.dart';
import '../../data/repositories/organization_repository.dart';
import '../api/api_exception.dart';

final organizationRepositoryProvider = Provider((ref) => OrganizationRepository());

final organizationsProvider = FutureProvider<List<OrganizationModel>>((ref) async {
  final repo = ref.watch(organizationRepositoryProvider);
  final result = await repo.getOrganizations();
  return switch (result) {
    ApiSuccess(data: final orgs) => orgs,
    ApiError(exception: final ex) => throw ex,
  };
});
