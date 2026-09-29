import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/regularization_repository.dart';
import '../models/regularization_request.dart';

final myRequestsProvider = FutureProvider.autoDispose<List<RegularizationRequest>>((ref) {
  return ref.watch(regularizationRepoProvider).getMyRequests();
});

final allRequestsProvider = FutureProvider.autoDispose<List<RegularizationRequest>>((ref) {
  return ref.watch(regularizationRepoProvider).getAllRequests();
});
