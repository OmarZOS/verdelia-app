// lib/business/finance/Subscription.dart

import 'package:verdelia_core/app/finance/Plan.dart';

/// A subscription row as returned by `GET /app_user/{id}/subscription`.
class Subscription {
  final int? idSubscription;
  final int? subscriptionPlanId;
  final int? subscriptionPaymentId;
  final int? subscriptionQuota;
  final DateTime? subscriptionExpiry;
  final DateTime? subscriptionCreatedAt;
  final DateTime? subscriptionUpdatedAt;

  const Subscription({
    this.idSubscription,
    this.subscriptionPlanId,
    this.subscriptionPaymentId,
    this.subscriptionQuota,
    this.subscriptionExpiry,
    this.subscriptionCreatedAt,
    this.subscriptionUpdatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      idSubscription: _asInt(json['id_subscription']),
      subscriptionPlanId: _asInt(json['subscription_plan_id']),
      subscriptionPaymentId: _asInt(json['subscription_payment_id']),
      subscriptionQuota: _asInt(json['subscription_quota']),
      subscriptionExpiry: _parseDate(json['subscription_expiry']),
      subscriptionCreatedAt: _parseDate(json['subscription_created_at']),
      subscriptionUpdatedAt: _parseDate(json['subscription_updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idSubscription != null) 'id_subscription': idSubscription,
        if (subscriptionPlanId != null)
          'subscription_plan_id': subscriptionPlanId,
        if (subscriptionPaymentId != null)
          'subscription_payment_id': subscriptionPaymentId,
        if (subscriptionQuota != null) 'subscription_quota': subscriptionQuota,
        if (subscriptionExpiry != null)
          'subscription_expiry': subscriptionExpiry!.toIso8601String(),
        if (subscriptionCreatedAt != null)
          'subscription_created_at': subscriptionCreatedAt!.toIso8601String(),
        if (subscriptionUpdatedAt != null)
          'subscription_updated_at': subscriptionUpdatedAt!.toIso8601String(),
      };

  /// True when the subscription hasn't expired. A null expiry means
  /// "never expires" — lifetime plans.
  bool get isActive {
    if (subscriptionExpiry == null) return true;
    return subscriptionExpiry!.isAfter(DateTime.now());
  }

  @override
  String toString() =>
      'Subscription(id: $idSubscription, plan: $subscriptionPlanId, '
      'expiry: $subscriptionExpiry)';
}

/// Result of a paid subscription purchase.
///
/// Carries the subscription, its invoice, the plan it was purchased
/// for, and the payment id — enough for the client to render a
/// receipt without a follow-up call.
class SubscriptionPurchaseResult {
  final Subscription subscription;
  final int? invoiceId;
  final Plan plan;
  final int? paymentId;

  const SubscriptionPurchaseResult({
    required this.subscription,
    required this.plan,
    this.invoiceId,
    this.paymentId,
  });

  factory SubscriptionPurchaseResult.fromJson(Map<String, dynamic> json) {
    final subJson = json['subscription'];
    final planJson = json['plan'];
    final invoiceJson = json['invoice'];
    final paymentJson = json['payment'];

    return SubscriptionPurchaseResult(
      subscription: subJson is Map
          ? Subscription.fromJson(Map<String, dynamic>.from(subJson))
          : const Subscription(),
      plan: planJson is Map
          ? Plan.fromJson(Map<String, dynamic>.from(planJson))
          : const Plan(
              planName: '',
              planPrice: 0,
              billingCycle: BillingCycle.monthly,
              planType: PlanType.individual,
            ),
      invoiceId: invoiceJson is Map ? _asInt(invoiceJson['invoice_id']) : null,
      paymentId: paymentJson is Map ? _asInt(paymentJson['id']) : null,
    );
  }

  @override
  String toString() =>
      'SubscriptionPurchaseResult(subscription: $subscription, '
      'plan: ${plan.planName}, payment: $paymentId)';
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) {
    final ms = v > 1000000000000 ? v : v * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  if (v is String) {
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}
