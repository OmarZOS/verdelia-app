// lib/provider_store/components/delivery/DeliveryTransitionSheet.dart
import 'package:event/delivery_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider_store/components/delivery/DeliveryDetailsSheet.dart';

/// Describes one named delivery action the UI can request.
///
/// The `verb` label is localized through [AppLocalizations], so the
/// enum is deliberately locale-agnostic — it only carries structure
/// (which statuses it applies to, what target state it produces, what
/// icon to draw). The label lookup takes a localizations instance.
enum DeliveryAction {
  accept,
  confirm,
  ship,
  inTransit,
  outForDelivery,
  deliver,
  fail,
  cancel,
  returnDelivery,
  refund;

  bool isApplicableTo(Delivery delivery) {
    final status = delivery.delivery_status;
    switch (this) {
      case DeliveryAction.accept:
        return status == DeliveryStatus.pending;
      case DeliveryAction.confirm:
        return status == DeliveryStatus.processing;
      case DeliveryAction.ship:
        return status == DeliveryStatus.confirmed;
      case DeliveryAction.inTransit:
        return status == DeliveryStatus.shipped;
      case DeliveryAction.outForDelivery:
        return status == DeliveryStatus.inTransit;
      case DeliveryAction.deliver:
        return status == DeliveryStatus.outForDelivery;
      case DeliveryAction.fail:
        return status == DeliveryStatus.processing ||
            status == DeliveryStatus.inTransit ||
            status == DeliveryStatus.outForDelivery;
      case DeliveryAction.cancel:
        return status == DeliveryStatus.pending ||
            status == DeliveryStatus.processing ||
            status == DeliveryStatus.confirmed;
      case DeliveryAction.returnDelivery:
        return status == DeliveryStatus.delivered ||
            status == DeliveryStatus.failed;
      case DeliveryAction.refund:
        return status == DeliveryStatus.delivered;
    }
  }

  String? get targetStatus {
    switch (this) {
      case DeliveryAction.accept:
        return 'processing';
      case DeliveryAction.confirm:
        return 'confirmed';
      case DeliveryAction.ship:
        return 'shipped';
      case DeliveryAction.inTransit:
        return 'in_transit';
      case DeliveryAction.outForDelivery:
        return 'out_for_delivery';
      case DeliveryAction.deliver:
        return 'delivered';
      case DeliveryAction.fail:
        return 'failed';
      case DeliveryAction.cancel:
        return 'cancelled';
      case DeliveryAction.returnDelivery:
        return 'returned';
      case DeliveryAction.refund:
        return 'refunded';
    }
  }

  /// Localized verb for the action. Called from the UI with the
  /// current [AppLocalizations] instance.
  String verb(AppLocalizations l10n) {
    switch (this) {
      case DeliveryAction.accept:
        return l10n.deliveryActionAccept;
      case DeliveryAction.confirm:
        return l10n.deliveryActionConfirm;
      case DeliveryAction.ship:
        return l10n.deliveryActionShip;
      case DeliveryAction.inTransit:
        return l10n.deliveryActionInTransit;
      case DeliveryAction.outForDelivery:
        return l10n.deliveryActionOutForDelivery;
      case DeliveryAction.deliver:
        return l10n.deliveryActionDeliver;
      case DeliveryAction.fail:
        return l10n.deliveryActionFail;
      case DeliveryAction.cancel:
        return l10n.deliveryActionCancel;
      case DeliveryAction.returnDelivery:
        return l10n.deliveryActionReturn;
      case DeliveryAction.refund:
        return l10n.deliveryActionRefund;
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryAction.accept:
        return Icons.check_circle_outline_rounded;
      case DeliveryAction.confirm:
        return Icons.verified_outlined;
      case DeliveryAction.ship:
        return Icons.local_shipping_outlined;
      case DeliveryAction.inTransit:
        return Icons.route_rounded;
      case DeliveryAction.outForDelivery:
        return Icons.delivery_dining_outlined;
      case DeliveryAction.deliver:
        return Icons.task_alt_rounded;
      case DeliveryAction.fail:
        return Icons.report_gmailerrorred_rounded;
      case DeliveryAction.cancel:
        return Icons.cancel_outlined;
      case DeliveryAction.returnDelivery:
        return Icons.assignment_return_outlined;
      case DeliveryAction.refund:
        return Icons.replay_rounded;
    }
  }

  bool get isDestructive {
    switch (this) {
      case DeliveryAction.fail:
      case DeliveryAction.cancel:
        return true;
      default:
        return false;
    }
  }
}

/// One required precondition for a transition. When unsatisfied, the
/// transition sheet renders a "Fix" button that opens the edit sheet
/// with the relevant section focused.
///
/// The `label` and `description` are localized keys wrapped in a small
/// resolver function. Building the requirements needs a
/// [AppLocalizations] instance, so `_requirements(l10n)` takes one.
class DeliveryTransitionRequirement {
  final String label;
  final String? description;
  final bool Function(Delivery) satisfied;
  final DeliveryDetailsFocus? fixTarget;

  const DeliveryTransitionRequirement({
    required this.label,
    required this.satisfied,
    this.description,
    this.fixTarget,
  });

  bool get fixable => fixTarget != null;
}

/// The transition sheet. Reads the delivery live from the notifier so
/// the requirements checklist updates the moment a fix is applied. Any
/// unmet requirement exposes a "Fix" affordance that opens the edit
/// sheet scoped to the missing piece.
class DeliveryTransitionSheet extends StatefulWidget {
  final DeliveryChangeNotifier notifier;

  /// Starting delivery. The sheet reads the live value from the
  /// notifier on every build; this is only used for the initial id.
  final Delivery delivery;

  /// Which action to perform. If null, the sheet picks the next legal
  /// forward action.
  final DeliveryAction? action;

  const DeliveryTransitionSheet({
    super.key,
    required this.notifier,
    required this.delivery,
    this.action,
  });

  @override
  State<DeliveryTransitionSheet> createState() =>
      _DeliveryTransitionSheetState();
}

class _DeliveryTransitionSheetState extends State<DeliveryTransitionSheet> {
  late DeliveryAction _action;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _action = widget.action ?? _nextLegalAction(widget.delivery);
  }

  static DeliveryAction _nextLegalAction(Delivery delivery) {
    for (final action in DeliveryAction.values) {
      if (action.isApplicableTo(delivery) && !action.isDestructive) {
        return action;
      }
    }
    return DeliveryAction.accept;
  }

  Delivery get _live =>
      widget.notifier.getDeliveryByIdSync(widget.delivery.id_delivery) ??
      widget.delivery;

  /// Requirements for the current action, with localized labels and
  /// descriptions.
  List<DeliveryTransitionRequirement> _requirements(AppLocalizations l10n) {
    switch (_action) {
      case DeliveryAction.accept:
        return [
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqRecipient,
            description: l10n.deliveryTransitionReqRecipientDesc,
            satisfied: (d) =>
                (d.recipient_person > 0) ||
                (d.recipient_provider > 0) ||
                ((d.delivery_address_id ?? 0) > 0) ||
                ((d.delivery_current_address_id ?? 0) > 0),
            fixTarget: DeliveryDetailsFocus.recipient,
          ),
        ];

      case DeliveryAction.confirm:
        return [
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqRecipient,
            satisfied: (d) =>
                (d.recipient_person > 0) ||
                (d.recipient_provider > 0) ||
                ((d.delivery_address_id ?? 0) > 0),
            fixTarget: DeliveryDetailsFocus.recipient,
          ),
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqPackages,
            description: l10n.deliveryTransitionReqPackagesDesc,
            satisfied: (d) => (d.delivery_package_count ?? 0) > 0,
            fixTarget: DeliveryDetailsFocus.packages,
          ),
        ];

      case DeliveryAction.ship:
        return [
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqProvider,
            satisfied: (d) => (d.delivery_provider_id ?? 0) > 0,
          ),
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqCarrierAccepted,
            description: l10n.deliveryTransitionReqCarrierAcceptedDesc,
            satisfied: (_) => true,
          ),
        ];

      case DeliveryAction.inTransit:
        return [
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqTracking,
            description: l10n.deliveryTransitionReqTrackingDesc,
            satisfied: (_) => true,
          ),
        ];

      case DeliveryAction.outForDelivery:
        return [
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqDestination,
            satisfied: (d) => (d.delivery_address_id ?? 0) > 0,
            fixTarget: DeliveryDetailsFocus.destination,
          ),
        ];

      case DeliveryAction.deliver:
        return [
          DeliveryTransitionRequirement(
            label: l10n.deliveryTransitionReqProof,
            description: l10n.deliveryTransitionReqProofDesc,
            satisfied: (_) => true,
          ),
        ];

      case DeliveryAction.fail:
      case DeliveryAction.cancel:
      case DeliveryAction.returnDelivery:
      case DeliveryAction.refund:
        return const [];
    }
  }

  Future<void> _openFix(DeliveryDetailsFocus focus) async {
    final notifier = widget.notifier;
    final live = _live;

    final providerId = live.delivery_provider_id ?? notifier.currentProviderId;

    final initialProductIds = <int>{};
    for (final item in live.orderItems) {
      final id = item.orderedProductId ?? 0;
      if (id <= 0) continue;
      final embedded = item.orderedProduct;
      if (embedded != null &&
          embedded.idProduct != null &&
          embedded.idProduct! > 0) {
        if (providerId <= 0 || embedded.productProviderId == providerId) {
          initialProductIds.add(embedded.idProduct!);
        }
      } else {
        initialProductIds.add(id);
      }
    }

    if (!mounted) return;

    await DeliveryDetailsSheet.open(
      context,
      notifier: notifier,
      delivery: live,
      providerId: providerId,
      initialProductIds: initialProductIds.toList(),
      focusOn: focus,
    );
  }

  Future<void> _commit(AppLocalizations l10n) async {
    setState(() => _isCommitting = true);
    try {
      final ok = await _run();
      if (!mounted) return;
      Navigator.of(context).pop(ok);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok
              ? l10n.deliveryTransitionSuccess(_action.verb(l10n))
              : l10n.deliveryTransitionFailure(_action.verb(l10n)),
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.deliveryDetailsSaveError(e.toString())),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isCommitting = false);
    }
  }

  Future<bool> _run() async {
    final id = widget.delivery.id_delivery;
    switch (_action) {
      case DeliveryAction.accept:
        return widget.notifier.acceptDelivery(id);
      case DeliveryAction.confirm:
        return widget.notifier.confirmDelivery(id);
      case DeliveryAction.ship:
        return widget.notifier.shipDelivery(
          id,
          body: {'delivery_confirmed': true},
        );
      case DeliveryAction.inTransit:
        return widget.notifier.markInTransit(
          id,
          body: {'in_transit_acknowledged': true},
        );
      case DeliveryAction.outForDelivery:
        return widget.notifier.markOutForDelivery(id);
      case DeliveryAction.deliver:
        return widget.notifier.deliverDelivery(id, proofCaptured: true);
      case DeliveryAction.fail:
        return widget.notifier.failDelivery(id, failureReported: true);
      case DeliveryAction.cancel:
        return widget.notifier.cancelDelivery(id);
      case DeliveryAction.returnDelivery:
        return widget.notifier.returnDelivery(id, returnConfirmed: true);
      case DeliveryAction.refund:
        return widget.notifier.refundDelivery(id, refundCompleted: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<DeliveryChangeNotifier>(
      builder: (context, notifier, _) {
        final live =
            notifier.getDeliveryByIdSync(widget.delivery.id_delivery) ??
                widget.delivery;
        return _buildSheet(context, live, l10n);
      },
    );
  }

  Widget _buildSheet(
    BuildContext context,
    Delivery live,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final requirements = _requirements(l10n);
    final allMet = requirements.every((r) => r.satisfied(live));
    final missing = requirements.where((r) => !r.satisfied(live)).toList();

    final accent = _action.isDestructive ? cs.error : cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(_action.icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _action.verb(l10n),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.deliveryTransitionDeliveryId(live.id_delivery),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StateTransitionPreview(
              from: live.delivery_status,
              to: _action.targetStatus!,
              accent: accent,
              l10n: l10n,
            ),
            const SizedBox(height: 20),
            if (requirements.isNotEmpty) ...[
              Text(
                allMet
                    ? l10n.deliveryTransitionReady
                    : l10n.deliveryTransitionMissing,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: allMet ? cs.primary : cs.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              for (final req in requirements) ...[
                _RequirementRow(
                  requirement: req,
                  satisfied: req.satisfied(live),
                  onFix: req.fixable ? () => _openFix(req.fixTarget!) : null,
                  l10n: l10n,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
            ],
            if (missing.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: cs.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.deliveryTransitionMissingHint(missing.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    (_isCommitting || !allMet) ? null : () => _commit(l10n),
                icon: _isCommitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_action.icon, size: 20),
                label: Text(
                  _isCommitting
                      ? l10n.deliveryTransitionWorking
                      : l10n.deliveryTransitionCommit(_action.verb(l10n)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUB-WIDGETS
// ============================================================================

class _StateTransitionPreview extends StatelessWidget {
  final DeliveryStatus from;
  final String to;
  final Color accent;
  final AppLocalizations l10n;

  const _StateTransitionPreview({
    required this.from,
    required this.to,
    required this.accent,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _statePill(_deliveryStatusLabel(from, l10n), cs, dim: true),
          const SizedBox(width: 10),
          Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          _statePill(
            _targetStatusLabel(to, l10n),
            cs,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _statePill(
    String label,
    ColorScheme cs, {
    Color? accent,
    bool dim = false,
  }) {
    final bg = dim
        ? cs.surfaceContainerHighest
        : (accent ?? cs.primary).withOpacity(0.15);
    final fg = dim ? cs.onSurfaceVariant : (accent ?? cs.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Localized label for a [DeliveryStatus].
  static String _deliveryStatusLabel(
    DeliveryStatus s,
    AppLocalizations l10n,
  ) {
    switch (s) {
      case DeliveryStatus.pending:
        return l10n.deliveryStatusPending;
      case DeliveryStatus.processing:
        return l10n.deliveryStatusProcessing;
      case DeliveryStatus.confirmed:
        return l10n.deliveryStatusConfirmed;
      case DeliveryStatus.shipped:
        return l10n.deliveryStatusShipped;
      case DeliveryStatus.inTransit:
        return l10n.deliveryStatusInTransit;
      case DeliveryStatus.outForDelivery:
        return l10n.deliveryStatusOutForDelivery;
      case DeliveryStatus.delivered:
        return l10n.deliveryStatusDelivered;
      case DeliveryStatus.failed:
        return l10n.deliveryStatusFailed;
      case DeliveryStatus.cancelled:
        return l10n.deliveryStatusCancelled;
      case DeliveryStatus.returned:
        return l10n.deliveryStatusReturned;
      case DeliveryStatus.refunded:
        return l10n.deliveryStatusRefunded;
    }
  }

  /// Localized label for a wire-format target status string.
  static String _targetStatusLabel(String wire, AppLocalizations l10n) {
    return _deliveryStatusLabel(DeliveryStatus.fromWire(wire), l10n);
  }
}

class _RequirementRow extends StatelessWidget {
  final DeliveryTransitionRequirement requirement;
  final bool satisfied;
  final VoidCallback? onFix;
  final AppLocalizations l10n;

  const _RequirementRow({
    required this.requirement,
    required this.satisfied,
    required this.l10n,
    this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: satisfied
            ? cs.primaryContainer.withOpacity(0.25)
            : cs.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: satisfied
              ? cs.primary.withOpacity(0.3)
              : cs.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: satisfied ? cs.primary : cs.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (requirement.description != null && !satisfied) ...[
                  const SizedBox(height: 2),
                  Text(
                    requirement.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!satisfied && onFix != null)
            TextButton(
              onPressed: onFix,
              child: Text(l10n.deliveryTransitionFix),
            ),
        ],
      ),
    );
  }
}
