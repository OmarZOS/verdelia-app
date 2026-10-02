import 'dart:typed_data';

import 'package:verdelia_core/app/TraceableService.dart';
import 'package:verdelia_core/business/Delivery.dart';

// DeliveryService.dart
abstract class DeliveryService extends TraceableService {
  Future<List<Delivery>> getAllDeliveries(int offset, int limit,
      {int providerId = 0,
      int orderId = 0,
      int brokerId = 0,
      String? callerKey}) async {
    throw UnimplementedError();
  }

  Future<Delivery?> getDelivery(String idDelivery, {String? callerKey}) async {
    return null;
  }

  Future<Delivery?> addDelivery(dynamic Delivery, {String? callerKey}) async {
    return null;
  }

  Future<int?> deleteDelivery(String productId, {String? callerKey}) async {
    return null;
  }

  // ── Lifecycle ops ──────────────────────────────────────────────
  // Each corresponds to a POST /delivery/{id}/<action>. The body, when
  // supplied, is a Delivery_API-shaped map: real fields patch the
  // delivery, signal fields (delivery_confirmed, proof_captured, …)
  // flow into the policy.

  Future<Delivery?> acceptDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> confirmDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> shipDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> markInTransit(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> markOutForDelivery(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> deliverDelivery(
    int deliveryId, {
    bool? proofCaptured,
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> cancelDelivery(
    int deliveryId, {
    String? reason,
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> failDelivery(
    int deliveryId, {
    bool? failureReported,
    String? reason,
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> returnDelivery(
    int deliveryId, {
    bool? returnConfirmed,
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> refundDelivery(
    int deliveryId, {
    bool? refundCompleted,
    Map<String, dynamic>? body,
    String? callerKey,
  });

  Future<Delivery?> archiveDelivery(
    int deliveryId, {
    String? callerKey,
  });

  // ── Non-state ops ──────────────────────────────────────────────

  Future<Delivery?> recordTrackingPing(
    int deliveryId,
    int currentAddressId, {
    String? callerKey,
  });

  Future<Delivery?> rerouteDelivery(
    int deliveryId,
    int addressId, {
    String? callerKey,
  });

  Future<List<String>?> nextStates(
    int deliveryId, {
    String? callerKey,
  });

  Future<Delivery?> updateDetails(
    int deliveryId, {
    Map<String, dynamic>? body,
    String? callerKey,
  }) {
    throw UnimplementedError();
  }

  // ── Cache control ──────────────────────────────────────────────
  // Optional: impls that don't cache can leave the default no-op.

  void clearCache() {}
}
