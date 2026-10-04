// AppUserService.dart
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:verdelia_core/app/TraceableService.dart';
import 'package:verdelia_core/app/finance/Plan.dart';
import 'package:verdelia_core/app/finance/Subscription.dart';

import '../AppUser.dart';

// AppUserService.dart
abstract class AppUserService extends TraceableService {
  // ==================== Categories ====================

  Future<List<AppUserCategory>?>? getCategories({String? callerKey}) async {
    return null;
  }

  // ==================== User CRUD ====================

  Future<AppUser?> getAppUser(String idAppUser, {String? callerKey}) async {
    return null;
  }

  Future<Person?> getPerson(String idPerson, {String? callerKey}) async {
    return null;
  }

  Future<List<ManagementRule>?>? getManagementRules(
      int orgId, int supplierId, int userId, int offset, int limit,
      {String? callerKey}) async {
    return null;
  }

  Future<List<AppUser>?> searchAppUsers(String query, int offset, int limit,
      {String? callerKey}) async {
    return null;
  }

  Future<List<Person>?> searchPeople(String query, int offset, int limit,
      {String? callerKey}) async {
    return null;
  }

  Future<AppUser?> updateAppUser(AppUser appUser, {String? callerKey}) async {
    return null;
  }

  Future<int?> addAppUser(AppUser appUser, {String? callerKey}) async {
    return null;
  }

  Future<int?> updateAppUserImage(AppUser updatedAppUser,
      {String? callerKey}) async {
    return null;
  }

  Future<int?> deleteAppUser(String appUserId, {String? callerKey}) async {
    return null;
  }

  // ==================== Management Rules ====================

  Future<ManagementRule?> addUserToSupplier(
      int appUserId, int supplierId, int orgId, int privilege,
      {bool fromQR = false, String? callerKey}) async {
    return null;
  }

  Future<ManagementRule?> updateManagementRule(
      int ruleId, int appUserId, int supplierId, int orgId, int privilege,
      {String? callerKey}) async {
    return null;
  }

  Future<bool> deleteManagementRule(int ruleId, {String? callerKey}) async {
    return false;
  }

  // ==================== Plans ====================

  /// List every plan, optionally filtered.
  ///
  /// [planType] is `'individual'` or `'organization'`. [billingCycle]
  /// is `'monthly'`, `'semestrial'`, `'yearly'`, or `'lifetime'`. Both
  /// are optional — omitting them returns the full catalogue.
  ///
  /// Returns null on network / parse failure so callers can fall back
  /// to a cached catalogue. Empty list means the backend returned no
  /// plans, which is different from an error.
  Future<List<Plan>?> getPlans({
    String? planType,
    String? billingCycle,
    String? callerKey,
  }) async {
    return null;
  }

  /// Fetch a single plan by its id.
  ///
  /// Null means either a network failure or a 404. The caller can't
  /// distinguish without inspecting the trace — acceptable for a
  /// lookup that's almost always prefixed by a list call.
  Future<Plan?> getPlan(int planId, {String? callerKey}) async {
    return null;
  }

  // ==================== Subscription reads ====================

  /// Fetch the subscription a user currently points at.
  ///
  /// Null means the user has no subscription on file — a normal
  /// free-tier state, not an error. The backend returns 404 for this
  /// case; the client service translates that into null rather than
  /// throwing, because "no subscription" is not exceptional.
  Future<Subscription?> getSubscription(int userId, {String? callerKey}) async {
    return null;
  }

  /// Lightweight status check.
  ///
  /// Returns `true` when the user has an active, unexpired
  /// subscription. `false` covers both "no subscription" and "expired"
  /// — the backend collapses those into a single boolean.
  Future<bool> isSubscriptionActive(int userId, {String? callerKey}) async {
    return false;
  }

  // ==================== Subscription writes ====================

  /// Purchase a paid subscription in a single call.
  ///
  /// The backend creates the invoice, creates the payment, confirms it
  /// with the finance service, and finalizes the subscription. The
  /// result is a live subscription, not a pending payment — there's no
  /// separate finalize step for the client.
  ///
  /// Returns a [SubscriptionPurchaseResult] carrying the subscription,
  /// invoice, plan, and payment ids so the caller can show a receipt
  /// or navigate to a confirmation screen.
  ///
  /// Null on failure. Free plans should not use this method — call
  /// [linkFreePlan] instead.
  Future<SubscriptionPurchaseResult?> initiateSubscription({
    required int userId,
    required int planId,
    required String paymentMethod,
    String? notes,
    String? callerKey,
  }) async {
    return null;
  }

  /// Attach a zero-priced plan without going through the payment flow.
  ///
  /// Used for the default free tier and for comped plans issued by
  /// support. Any plan with a non-zero price returns null — the backend
  /// rejects it with 400, and the client service translates that into
  /// null rather than throwing.
  Future<Subscription?> linkFreePlan({
    required int userId,
    required int planId,
    String? callerKey,
  }) async {
    return null;
  }

  /// Cancel a user's subscription, optionally refunding.
  ///
  /// [refundPaymentId] is the payment to refund, if any. When null,
  /// the cancellation proceeds without a refund. Returns the updated
  /// user on success — the workflow returns the user row so the
  /// caller can refresh the local state in one step.
  ///
  /// Null on failure or when the user has no subscription to cancel.
  Future<AppUser?> cancelSubscription({
    required int userId,
    int? refundPaymentId,
    String? callerKey,
  }) async {
    return null;
  }
}
