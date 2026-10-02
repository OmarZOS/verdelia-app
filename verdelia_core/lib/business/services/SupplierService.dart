// SupplierService.dart

import 'package:verdelia_core/app/TraceableService.dart';
import 'package:verdelia_core/business/Organisation.dart';

import '../Supplier.dart';

abstract class SupplierService extends TraceableService {
  Future<List<SupplierCategory>> getCategories() async {
    throw UnimplementedError();
  }

  Future<List<Supplier>?> getSuppliersByIds(List<int> ids) async {
    throw UnimplementedError();
  }

  Future<List<Supplier>> searchSuppliersByToken(
      String token, int offset, int itemsPerPage) {
    throw UnimplementedError();
  }

  Future<List<Supplier>> searchSuppliersByGeo(double longitude, double latitude,
      int offset, int itemsPerPage, double distance) {
    throw UnimplementedError();
  }

  Future<SupplierCategory?> getCategoryById(int categoryId) {
    throw UnimplementedError();
    // throw UnimplementedError();
  }

  Future<Supplier?> getSupplier(String id) async {
    throw UnimplementedError();
  }

  Future<List<Supplier>> getAllSuppliers(
      int ownerId, int orgId, int offset, int itemsPerPage) async {
    throw UnimplementedError();
  }

  Future<List<Organisation>> getAllOrganisations(
      int ownerId, int orgId, int offset, int itemsPerPage) async {
    throw UnimplementedError();
  }

  Future<Supplier?> addSupplier(Supplier supplier,
      {String? callerKey, String? token}) async {
    throw UnimplementedError();
  }

  Future<Supplier?> updateSupplier(Supplier updatedSupplier,
      {String? callerKey, String? token}) async {
    throw UnimplementedError();
  }

  Future<int?> deleteSupplier(String supplierId,
      {String? callerKey, String? token}) async {
    throw UnimplementedError();
  }

  Future<Organisation?> getOrganisation(String id) async {
    throw UnimplementedError();
  }

  Future<Organisation?> addOrganisation(Organisation supplier,
      {String? callerKey, String? token}) async {
    throw UnimplementedError();
  }

  Future<Organisation?> updateOrganisation(Organisation updatedOrganisation,
      {String? callerKey, String? token}) async {
    throw UnimplementedError();
  }

  Future<int?> deleteOrganisation(String id,
      {String? callerKey, String? token}) async {
    throw UnimplementedError();
  }
}
