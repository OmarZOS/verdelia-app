import '../finance/BusinessOperation.dart';

// BusinessOperationService.dart
abstract class BusinessOperationService {
  Future<BusinessOperationsResponse?> getAllBusinessOperations(
    int page,
    int limit, {
    int supplierId = 0,
    int clientId = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool includeStats = true,
  }) async {
    throw UnimplementedError();
  }

  Future<BusinessOperation?> getBusinessOperation(
      String idBusinessOperation) async {
    return null;
  }
}
