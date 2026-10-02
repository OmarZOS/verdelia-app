/// This abstraction is used to store the
/// data that is required during the start
/// of the application and for recurrent use
library;

abstract class PersistenceService {
  Future<dynamic> getAll(String destination) async {
    return null;
  }

  Future<int?> insert(String destination, Map<String, dynamic> data) async {
    return null;
  }

  Future<dynamic> get(String destination, String id) async {
    return null;
  }

  Future<int?> delete(String destination, String id) async {
    return null;
  }

  Future<int?> update(
      String destination, String id, Map<String, dynamic> data) async {
    return null;
  }
}
