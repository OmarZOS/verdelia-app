import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:provider_store/components/orders/details/delivery_details_screen.dart';

// ============================================================================
// DELIVERY CARD
// ============================================================================

class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final DeliveryChangeNotifier notifier;
  final VoidCallback? onTap;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.notifier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final status = DeliveryStatusConfig.fromStatus(
      delivery.delivery_status.wireValue,
      l10n,
    );

    final addr = delivery.delivery_address;
    final hasAddress = addr != null;

    // Title = city + country (or street as fallback).
    // Subtitle = postal code (or street when postal is missing).
    final title =
        hasAddress ? _titleFrom(addr) : l10n.deliveryCardNoDestination;
    final subtitle = hasAddress ? _subtitleFrom(addr) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? () => _navigateToDetails(context),
          splashColor: status.color.withOpacity(0.08),
          highlightColor: status.color.withOpacity(0.04),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: status.color.withOpacity(0.22),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left accent stripe ──
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          status.color,
                          status.color.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Row 1: status pill + relative time ──
                          Row(
                            children: [
                              _StatusPill(status: status),
                              const Spacer(),
                              if (delivery.delivery_updated_at != null)
                                _TimestampText(
                                  timestamp: delivery.delivery_updated_at!,
                                  l10n: l10n,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Row 2: destination title + subtitle ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LocationBadge(color: status.color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                        height: 1.2,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Row 3: meta chips (packages, weight, method) ──
                          _MetaRow(
                            delivery: delivery,
                            l10n: l10n,
                            statusColor: status.color,
                          ),

                          // ── Row 4: goods description (optional) ──
                          if (_hasText(
                              delivery.delivery_goods_description)) ...[
                            const SizedBox(height: 10),
                            _GoodsLine(
                              text: delivery.delivery_goods_description!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Fee column on the right ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (delivery.delivery_fee != null)
                          _FeeBlock(amount: delivery.delivery_fee!),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant.withOpacity(0.5),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDetails(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final fetchedDelivery = await notifier.getDeliveryById(
      delivery.id_delivery,
      forceRefresh: true,
    );

    if (!context.mounted) return;

    if (fetchedDelivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deliveryCardLoadFailed),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(
          delivery: fetchedDelivery,
          notifier: notifier,
        ),
      ),
    );
  }

  // ── Title and subtitle extraction ──

  /// Title: city + country, joined. Falls back to street if city missing.
  String _titleFrom(DeliveryAddress addr) {
    final parts = <String>[];
    if (_hasText(addr.addressCity)) parts.add(addr.addressCity!.trim());
    if (_hasText(addr.addressCountry)) parts.add(addr.addressCountry!.trim());
    if (parts.isNotEmpty) return parts.join(', ');
    if (_hasText(addr.addressStreet)) return addr.addressStreet!.trim();
    return AppLocalizations.of(_ctx)?.deliveryCardNoDestination ??
        'No destination';
  }

  /// Subtitle: street + postal code. Falls back to postal code alone.
  String? _subtitleFrom(DeliveryAddress addr) {
    final parts = <String>[];
    if (_hasText(addr.addressStreet)) parts.add(addr.addressStreet!.trim());
    if (_hasText(addr.addressPostalCode)) {
      parts.add(addr.addressPostalCode!.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  // Context accessor so _titleFrom can read localizations without
  // threading a context through every helper. Set during build.
  BuildContext get _ctx => _deliveryCardContext!;
  static BuildContext? _deliveryCardContext;

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  static void _bind(BuildContext c) => _deliveryCardContext = c;
}

// ============================================================================
// STATUS CONFIG — localized
// ============================================================================

class DeliveryStatusConfig {
  final IconData icon;
  final Color color;
  final String label;

  const DeliveryStatusConfig({
    required this.icon,
    required this.color,
    required this.label,
  });

  factory DeliveryStatusConfig.fromStatus(
    String status,
    AppLocalizations l10n,
  ) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return DeliveryStatusConfig(
          icon: Icons.schedule_rounded,
          color: const Color(0xFFF59E0B),
          label: l10n.deliveryStatusPending,
        );
      case 'PROCESSING':
        return DeliveryStatusConfig(
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFF3B82F6),
          label: l10n.deliveryStatusProcessing,
        );
      case 'CONFIRMED':
        return DeliveryStatusConfig(
          icon: Icons.verified_outlined,
          color: const Color(0xFF0EA5E9),
          label: l10n.deliveryStatusConfirmed,
        );
      case 'READY_FOR_PICKUP':
        return DeliveryStatusConfig(
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF14B8A6),
          label: l10n.deliveryStatusReadyForPickup,
        );
      case 'IN_TRANSIT':
        return DeliveryStatusConfig(
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF8B5CF6),
          label: l10n.deliveryStatusInTransit,
        );
      case 'OUT_FOR_DELIVERY':
        return DeliveryStatusConfig(
          icon: Icons.delivery_dining_outlined,
          color: const Color(0xFFF97316),
          label: l10n.deliveryStatusOutForDelivery,
        );
      case 'DELIVERED':
        return DeliveryStatusConfig(
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF10B981),
          label: l10n.deliveryStatusDelivered,
        );
      case 'FAILED':
        return DeliveryStatusConfig(
          icon: Icons.error_outline_rounded,
          color: const Color(0xFFEF4444),
          label: l10n.deliveryStatusFailed,
        );
      case 'CANCELLED':
        return DeliveryStatusConfig(
          icon: Icons.cancel_outlined,
          color: const Color(0xFF6B7280),
          label: l10n.deliveryStatusCancelled,
        );
      case 'RETURNED':
        return DeliveryStatusConfig(
          icon: Icons.assignment_return_outlined,
          color: const Color(0xFFF59E0B),
          label: l10n.deliveryStatusReturned,
        );
      case 'REFUNDED':
        return DeliveryStatusConfig(
          icon: Icons.replay_rounded,
          color: const Color(0xFF06B6D4),
          label: l10n.deliveryStatusRefunded,
        );
      default:
        return DeliveryStatusConfig(
          icon: Icons.help_outline_rounded,
          color: const Color(0xFF9CA3AF),
          label: l10n.deliveryStatusUnknown,
        );
    }
  }
}

// ============================================================================
// SUB-WIDGETS
// ============================================================================

class _StatusPill extends StatelessWidget {
  final DeliveryStatusConfig status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: status.color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimestampText extends StatelessWidget {
  final DateTime timestamp;
  final AppLocalizations l10n;

  const _TimestampText({required this.timestamp, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      _relativeTime(timestamp),
      style: TextStyle(
        fontSize: 11,
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return l10n.deliveryDetailUpdatedJustNow;
    if (diff.inMinutes < 60) {
      return l10n.deliveryDetailUpdatedMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.deliveryDetailUpdatedHoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) {
      return l10n.deliveryDetailUpdatedDaysAgo(diff.inDays);
    }
    return l10n.deliveryDetailUpdatedOnDate(ts.day, ts.month, ts.year);
  }
}

/// Soft circular badge holding the destination icon. Colour-keyed to
/// the delivery status so the card's visual fingerprint matches the pill.
class _LocationBadge extends StatelessWidget {
  final Color color;

  const _LocationBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.location_on_rounded,
        size: 20,
        color: color,
      ),
    );
  }
}

/// Row of small chips: packages, weight, shipping method.
/// Chips that have no value are simply not rendered.
class _MetaRow extends StatelessWidget {
  final Delivery delivery;
  final AppLocalizations l10n;
  final Color statusColor;

  const _MetaRow({
    required this.delivery,
    required this.l10n,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chips = <Widget>[];

    if (delivery.delivery_package_count != null &&
        delivery.delivery_package_count! > 0) {
      chips.add(_InfoChip(
        icon: Icons.inventory_2_outlined,
        label: l10n.deliveryDetailPackageCount(
          delivery.delivery_package_count!,
        ),
        color: cs.primary,
      ));
    }

    if (delivery.delivery_total_weight != null &&
        delivery.delivery_total_weight! > 0) {
      chips.add(_InfoChip(
        icon: Icons.monitor_weight_outlined,
        label: l10n.deliveryDetailWeightKg(
          delivery.delivery_total_weight!.toStringAsFixed(2),
        ),
        color: cs.tertiary,
      ));
    }

    chips.add(_InfoChip(
      icon: Icons.local_shipping_outlined,
      label: _shippingLabel(l10n),
      color: statusColor,
    ));

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  String _shippingLabel(AppLocalizations l10n) {
    switch (delivery.delivery_shipping_method.toLowerCase()) {
      case 'express':
        return l10n.shippingMethodExpress;
      case 'overnight':
        return l10n.shippingMethodOvernight;
      case 'freight':
        return l10n.shippingMethodFreight;
      case 'pickup':
        return l10n.shippingMethodPickup;
      case 'courier':
        return l10n.shippingMethodCourier;
      case 'same_day':
        return l10n.shippingMethodSameDay;
      case 'international':
        return l10n.shippingMethodInternational;
      case 'standard':
      default:
        return l10n.shippingMethodStandard;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width row for the goods description, tucked at the bottom of
/// the card. Padded the same as the meta chips so it reads as part of
/// the same cluster.
class _GoodsLine extends StatelessWidget {
  final String text;

  const _GoodsLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.description_outlined,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Right-aligned price block with a small caption above the amount.
class _FeeBlock extends StatelessWidget {
  final double amount;

  const _FeeBlock({required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          l10n.deliveryDetailFieldFee,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.4,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.deliveryDetailPriceWithCurrency(
            amount.toStringAsFixed(2),
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
