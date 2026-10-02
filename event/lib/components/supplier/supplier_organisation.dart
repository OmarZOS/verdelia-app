import 'package:verdelia_core/business/Organisation.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'supplier_state.dart';
import 'supplier_persistence.dart';
import 'supplier_cache.dart';

class SupplierOrganisation {
  final SupplierService _service;
  final StorageService _storage;
  final SupplierState _state;
  final SupplierPersistence _persistence;
  final SupplierCache _cache;

  SupplierOrganisation({
    required SupplierService service,
    required StorageService storage,
    required SupplierState state,
    required SupplierPersistence persistence,
    required SupplierCache cache,
  })  : _service = service,
        _storage = storage,
        _state = state,
        _persistence = persistence,
        _cache = cache;

  static const _perPage = 30;

  Future<void> fetch({bool reset = false}) async {
    if (_state.isLoading || (!reset && !_state.hasMoreOrganisations)) return;

    if (reset) {
      _state.organisations.clear();
      _state.organisationsPage = 0;
      _state.hasMoreOrganisations = true;
    }

    _state.isLoading = true;

    try {
      final results = await _service.getAllOrganisations(
        0,
        0,
        _state.organisationsPage * _perPage,
        _perPage,
      );

      for (final org in results) {
        _state.organisations[org.id_provider_organisation] = org;
      }

      _state.hasMoreOrganisations = results.length >= _perPage;
      if (_state.hasMoreOrganisations) _state.organisationsPage++;
    } finally {
      _state.isLoading = false;
    }
  }

  Future<Organisation?> getById(int id) async {
    final cached = _state.getOrganisation(id);
    if (cached != null) return cached;

    _state.isLoading = true;
    try {
      final org = await _service.getOrganisation(id.toString());
      if (org != null) {
        _state.organisations[org.id_provider_organisation] = org;
      }
      return org;
    } finally {
      _state.isLoading = false;
    }
  }

  Future<Organisation?> create(Organisation org, String token) async {
    _state.isLoading = true;
    try {
      final result = await _service.addOrganisation(org, token: token);
      if (result != null) {
        _state.organisations[result.id_provider_organisation] = result;
        await _persistence.addOrganisation(
            _persistence.currentUserId, result.id_provider_organisation);
      }
      return result;
    } finally {
      _state.isLoading = false;
    }
  }

  Future<Organisation?> update(Organisation org, String token) async {
    _state.isLoading = true;
    try {
      final result = await _service.updateOrganisation(org, token: token);
      if (result != null) {
        _state.organisations[result.id_provider_organisation] = result;
      }
      return result;
    } finally {
      _state.isLoading = false;
    }
  }

  Future<bool> delete(int id, String token) async {
    _state.isLoading = true;
    try {
      final status =
          await _service.deleteOrganisation(id.toString(), token: token);
      final success = status != null && (status == 200 || status == 204);
      if (success) {
        _state.organisations.remove(id);
        await _persistence.removeOrganisation(_persistence.currentUserId, id);
      }
      return success;
    } finally {
      _state.isLoading = false;
    }
  }
}
