library business;

import 'dart:developer' as developer;
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/ApiResponse.dart';
import 'package:verdelia_core/business/finance/FinancialDocument.dart';
import 'package:verdelia_core/business/finance/services/InvoiceService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

// Import the TraceableService

class InvoiceServiceImpl extends InvoiceService {
  // ==================== Constants ====================

  static const String _tag = 'InvoiceServiceImpl';

  // Caller key constants for traceability
  static const String ADD_DOCUMENT = 'add_financial_document';
  static const String DELETE_DOCUMENT = 'delete_financial_document';
  static const String GET_ALL_DOCS = 'get_all_financial_docs';
  static const String GET_DOCUMENT = 'get_financial_document';
  static const String UPDATE_DOCUMENT = 'update_financial_document';
  static const String GET_PAYMENTS = 'get_payments';
  static const String GET_DEPOSITS = 'get_deposits';
  static const String GET_FEES = 'get_fees';

  // ==================== Helper Methods ====================

  String _generateCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null && id.isNotEmpty) parts.add(id);
    if (suffix != null && suffix.isNotEmpty) parts.add(suffix);
    return parts.join('_');
  }

  void _log(String message,
      {String level = 'info', dynamic error, StackTrace? stacktrace}) {
    if (error != null) {
      developer.log('[$level] $message',
          name: _tag, error: error, stackTrace: stacktrace);
    } else {
      developer.log('[$level] $message', name: _tag);
    }
  }

  // ==================== Core Methods ====================

  @override
  Future<FinancialDocument?> addFinancialDocument(
      dynamic financialDocument) async {
    final callerKey = _generateCallerKey(ADD_DOCUMENT,
        suffix: DateTime.now().millisecondsSinceEpoch.toString());

    try {
      final storageService = AppLocator.get<StorageService>();
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.postPaymentEndpoint}';

      _log('Adding financial document at: $url');
      _log('Financial document data: $financialDocument');

      final result = await storageService.insert(url, financialDocument);

      if (result == null) {
        _log('Failed to add financial document: null response');
        setFailureResponse(callerKey, null,
            statusCode: 500, responseCode: 'NULL_RESPONSE');
        return null;
      }

      final document =
          FinancialDocument.fromJson(result as Map<String, dynamic>);
      _log('Financial document added successfully: ${document.documentId}');

      setSuccessResponse(callerKey, document,
          statusCode: 201, responseCode: 'SUCCESS');
      return document;
    } catch (e, stacktrace) {
      _log('Error adding financial document: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return null;
    }
  }

  @override
  Future<int?> deleteFinancialDocument(String financialDocumentId) async {
    final callerKey =
        _generateCallerKey(DELETE_DOCUMENT, id: financialDocumentId);

    try {
      final storageService = AppLocator.get<StorageService>();
      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getPaymentsEndpoint}/$financialDocumentId';

      _log('Deleting financial document at: $url');

      final result = await storageService.delete(url, financialDocumentId);

      if (result != null && result > 0) {
        _log('Financial document $financialDocumentId deleted successfully');
        setSuccessResponse(callerKey, result,
            statusCode: 200, responseCode: 'SUCCESS');
      } else {
        _log('Failed to delete financial document $financialDocumentId');
        setFailureResponse(callerKey, result,
            statusCode: 404, responseCode: 'NOT_FOUND');
      }

      return result;
    } catch (e, stacktrace) {
      _log('Error deleting financial document: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return null;
    }
  }

  @override
  Future<List<FinancialDocument>?> getAllFinanceDocs(
    int offset,
    int limit, {
    int supplierId = 0,
    int personId = 0,
    int clientId = 0,
    int sellerId = 0,
    int cartId = 0,
    int orderId = 0,
    int depositId = 0,
    int invoiceId = 0,
  }) async {
    final callerKey = _generateCallerKey(
      GET_ALL_DOCS,
      suffix: 'offset_${offset}_limit_${limit}',
    );

    try {
      final storageService = AppLocator.get<StorageService>();

      // Build URL with query parameters
      final queryParams = <String, dynamic>{
        'offset': offset,
        'limit': limit,
      };

      if (supplierId > 0) queryParams['provider_id'] = supplierId;
      if (personId > 0) queryParams['person_id'] = personId;
      if (clientId > 0) queryParams['client_id'] = clientId;
      if (sellerId > 0) queryParams['seller_id'] = sellerId;
      if (cartId > 0) queryParams['cart_id'] = cartId;
      if (orderId > 0) queryParams['order_id'] = orderId;
      if (depositId > 0) queryParams['deposit_id'] = depositId;
      if (invoiceId > 0) queryParams['invoice_id'] = invoiceId;

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getFinancialDocsEndpoint}';
      _log('Getting financial documents from: $url');
      _log('Query params: $queryParams');

      final responseData =
          await storageService.getAll(url, params: queryParams);

      if (responseData == null) {
        _log('No financial documents found');
        setSuccessResponse(callerKey, [],
            statusCode: 200, responseCode: 'EMPTY');
        return [];
      }

      final documents = _parseFinancialDocuments(responseData);
      _log('Found ${documents.length} financial documents');

      setSuccessResponse(callerKey, documents,
          statusCode: 200, responseCode: 'SUCCESS');
      return documents;
    } catch (e, stacktrace) {
      _log('Error getting financial documents: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return [];
    }
  }

  @override
  Future<FinancialDocument?> getFinancialDocument(
      String idFinancialDocument) async {
    final callerKey = _generateCallerKey(GET_DOCUMENT, id: idFinancialDocument);

    try {
      final storageService = AppLocator.get<StorageService>();

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getPaymentsEndpoint}/$idFinancialDocument';
      _log('Getting financial document from: $url');

      final responseData = await storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.getPaymentsEndpoint}',
        idFinancialDocument,
      );

      if (responseData == null) {
        _log('Financial document not found: $idFinancialDocument');
        setFailureResponse(callerKey, null,
            statusCode: 404, responseCode: 'NOT_FOUND');
        return null;
      }

      FinancialDocument? document;

      // Handle different response formats
      if (responseData is Map) {
        document =
            FinancialDocument.fromJson(responseData as Map<String, dynamic>);
      } else if (responseData is List && responseData.isNotEmpty) {
        document =
            FinancialDocument.fromJson(responseData[0] as Map<String, dynamic>);
      }

      if (document != null) {
        _log('Financial document found: ${document.documentId}');
        setSuccessResponse(callerKey, document,
            statusCode: 200, responseCode: 'SUCCESS');
      } else {
        _log('Unexpected response format: ${responseData.runtimeType}');
        setFailureResponse(callerKey, null,
            statusCode: 500, responseCode: 'INVALID_FORMAT');
      }

      return document;
    } catch (e, stacktrace) {
      _log('Error getting financial document: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return null;
    }
  }

  @override
  Future<FinancialDocument?> updateFinancialDocument(
      FinancialDocument updatedFinancialDocument) async {
    final callerKey = _generateCallerKey(UPDATE_DOCUMENT,
        id: updatedFinancialDocument.documentId.toString());

    try {
      final storageService = AppLocator.get<StorageService>();

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getPaymentsEndpoint}/${updatedFinancialDocument.documentId}';
      _log('Updating financial document at: $url');
      _log('Update data: ${updatedFinancialDocument.toJson()}');

      final result = await storageService.update(
        url,
        updatedFinancialDocument.documentId.toString(),
        {},
        updatedFinancialDocument.toJson(),
      );

      if (result == null) {
        _log('Failed to update financial document: null response');
        setFailureResponse(callerKey, null,
            statusCode: 500, responseCode: 'NULL_RESPONSE');
        return null;
      }

      final document =
          FinancialDocument.fromJson(result as Map<String, dynamic>);
      _log('Financial document updated successfully: ${document.documentId}');

      setSuccessResponse(callerKey, document,
          statusCode: 200, responseCode: 'SUCCESS');
      return document;
    } catch (e, stacktrace) {
      _log('Error updating financial document: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return null;
    }
  }

  // ==================== Additional Helper Methods ====================

  /// Get payments only
  Future<List<FinancialDocument>?> getPayments({
    int offset = 0,
    int limit = 100,
    int? invoiceId,
  }) async {
    final callerKey = _generateCallerKey(
      GET_PAYMENTS,
      suffix: 'offset_${offset}_limit_${limit}',
    );

    try {
      final storageService = AppLocator.get<StorageService>();

      final queryParams = <String, dynamic>{
        'offset': offset,
        'limit': limit,
      };
      if (invoiceId != null) queryParams['invoice_id'] = invoiceId;

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getPaymentsEndpoint}';
      _log('Getting payments from: $url');

      final responseData =
          await storageService.getAll(url, params: queryParams);

      if (responseData == null) {
        _log('No payments found');
        setSuccessResponse(callerKey, [],
            statusCode: 200, responseCode: 'EMPTY');
        return [];
      }

      final documents = _parseFinancialDocuments(responseData);
      _log('Found ${documents.length} payments');

      setSuccessResponse(callerKey, documents,
          statusCode: 200, responseCode: 'SUCCESS');
      return documents;
    } catch (e, stacktrace) {
      _log('Error getting payments: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return [];
    }
  }

  /// Get deposits only
  Future<List<FinancialDocument>?> getDeposits({
    int offset = 0,
    int limit = 100,
    int? cartId,
  }) async {
    final callerKey = _generateCallerKey(
      GET_DEPOSITS,
      suffix: 'offset_${offset}_limit_${limit}',
    );

    try {
      final storageService = AppLocator.get<StorageService>();

      final queryParams = <String, dynamic>{
        'offset': offset,
        'limit': limit,
      };
      if (cartId != null) queryParams['cart_id'] = cartId;

      final url =
          '${AppConstants.apiBaseUrl}${AppConstants.getDepositsEndpoint}';
      _log('Getting deposits from: $url');

      final responseData =
          await storageService.getAll(url, params: queryParams);

      if (responseData == null) {
        _log('No deposits found');
        setSuccessResponse(callerKey, [],
            statusCode: 200, responseCode: 'EMPTY');
        return [];
      }

      final documents = _parseFinancialDocuments(responseData);
      _log('Found ${documents.length} deposits');

      setSuccessResponse(callerKey, documents,
          statusCode: 200, responseCode: 'SUCCESS');
      return documents;
    } catch (e, stacktrace) {
      _log('Error getting deposits: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return [];
    }
  }

  /// Get fees only
  Future<List<FinancialDocument>?> getFees({
    int offset = 0,
    int limit = 100,
    int? providerId,
    int? userId,
  }) async {
    final callerKey = _generateCallerKey(
      GET_FEES,
      suffix: 'offset_${offset}_limit_${limit}',
    );

    try {
      final storageService = AppLocator.get<StorageService>();

      final queryParams = <String, dynamic>{
        'offset': offset,
        'limit': limit,
      };
      if (providerId != null) queryParams['provider_id'] = providerId;
      if (userId != null) queryParams['user_id'] = userId;

      final url = '${AppConstants.apiBaseUrl}${AppConstants.getFeesEndpoint}';
      _log('Getting fees from: $url');

      final responseData =
          await storageService.getAll(url, params: queryParams);

      if (responseData == null) {
        _log('No fees found');
        setSuccessResponse(callerKey, [],
            statusCode: 200, responseCode: 'EMPTY');
        return [];
      }

      final documents = _parseFinancialDocuments(responseData);
      _log('Found ${documents.length} fees');

      setSuccessResponse(callerKey, documents,
          statusCode: 200, responseCode: 'SUCCESS');
      return documents;
    } catch (e, stacktrace) {
      _log('Error getting fees: $e',
          level: 'error', error: e, stacktrace: stacktrace);
      setFailureResponse(callerKey, null,
          statusCode: 500, responseCode: 'EXCEPTION');
      return [];
    }
  }

  // ==================== Helper Methods ====================

  /// Helper method to parse financial documents from response
  List<FinancialDocument> _parseFinancialDocuments(dynamic responseData) {
    List<FinancialDocument> documents = [];

    try {
      if (responseData is List) {
        documents = responseData
            .map((data) {
              try {
                return FinancialDocument.fromJson(data as Map<String, dynamic>);
              } catch (e) {
                _log('Error parsing financial document: $e', level: 'warning');
                return null;
              }
            })
            .where((doc) => doc != null)
            .cast<FinancialDocument>()
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          documents = dataList
              .map((data) {
                try {
                  return FinancialDocument.fromJson(
                      data as Map<String, dynamic>);
                } catch (e) {
                  _log('Error parsing financial document: $e',
                      level: 'warning');
                  return null;
                }
              })
              .where((doc) => doc != null)
              .cast<FinancialDocument>()
              .toList();
        }
      } else if (responseData is Map) {
        // Single document
        try {
          final doc =
              FinancialDocument.fromJson(responseData as Map<String, dynamic>);
          documents = [doc];
        } catch (e) {
          _log('Error parsing financial document: $e', level: 'warning');
        }
      }
    } catch (e) {
      _log('Error parsing financial documents: $e', level: 'error');
    }

    return documents;
  }

  // ==================== Traceability Helper Methods ====================

  /// Get the response for the last add operation
  TraceableResponse? getLastAddResponse() {
    return getResponse(ADD_DOCUMENT);
  }

  /// Get the response for a specific delete operation
  TraceableResponse? getDeleteResponse(String documentId) {
    final key = _generateCallerKey(DELETE_DOCUMENT, id: documentId);
    return getResponse(key);
  }

  /// Get the response for a specific get operation
  TraceableResponse? getDocumentResponse(String documentId) {
    final key = _generateCallerKey(GET_DOCUMENT, id: documentId);
    return getResponse(key);
  }

  /// Check if the last add was successful
  bool wasLastAddSuccessful() {
    return isSuccess(ADD_DOCUMENT);
  }
}
