import 'dart:convert';

import 'package:event/preferenceChangeNotifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_core/app/finance/Plan.dart';
import 'package:verdelia_core/app/finance/Subscription.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/user_change_notifier.dart';
import 'package:tabbed_home/screens/components/flipping_avatar.dart';
import 'package:ui/components/gender/gender_widgets.dart';

/// Which profile the screen is rendering.
enum ProfileMode { owner, visitor }

class ProfileScreen extends StatefulWidget {
  final ProfileMode mode;
  final AppUser? user;

  const ProfileScreen({
    super.key,
    this.mode = ProfileMode.owner,
    this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get _isOwner => widget.mode == ProfileMode.owner;

  @override
  Widget build(BuildContext context) {
    if (widget.user == null && _isOwner) {
      return Scaffold(
        body: SafeArea(
          top: true,
          bottom: true,
          child: Consumer<AppUserNotifier>(
            builder: (context, notifier, _) {
              final user = notifier.appUser;
              if (user is! AppUser) {
                return const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _buildBody(context, user, notifier);
            },
          ),
        ),
      );
    }

    final user = widget.user;
    if (user == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('No user to display')),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: true,
        child: _buildBody(context, user, null),
      ),
    );
  }

  // ==================== Main content ====================

  Widget _buildBody(
    BuildContext context,
    AppUser user,
    AppUserNotifier? notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale =
        context.read<LocaleProvider>().locale?.toLanguageTag() ?? 'en';

    // Owner mode uses the notifier's subscription when the user row
    // doesn't carry an inlined one. This gives the tile current data
    // even when the payload only sent the FK.
    final Subscription? subscription =
        user.subscription ?? notifier?.subscription;

    // Resolve the plan from the notifier's cached catalogue.
    // Falls back to null when the notifier isn't available (visitor
    // mode) or the catalogue hasn't been fetched yet — the
    // subscription section degrades gracefully by hiding the plan
    // rows.
    Plan? plan;
    final planId = subscription?.subscriptionPlanId;
    if (planId != null && planId > 0) {
      plan = notifier?.planById(planId);
    }

    // If the plan isn't cached yet, kick off a fetch. Fire-and-forget;
    // the notifier notifies listeners on completion and the next build
    // picks up the plan.
    if (_isOwner && plan == null && planId != null && planId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier?.fetchPlans();
      });
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, _isOwner ? 96 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IdentityHeader(
                  user: user,
                  isOwner: _isOwner,
                  l10n: l10n,
                ),
                const SizedBox(height: 20),

                // ─── Status strip: subscription + wallet + quota ──
                if (_isOwner)
                  _StatusStrip(
                    user: user,
                    subscription: subscription,
                    l10n: l10n,
                  ),
                if (_isOwner) const SizedBox(height: 16),

                // ─── Personal ───────────────────────────────────
                _Section(
                  icon: Icons.person_pin_outlined,
                  title: l10n.personalInfoText,
                  entries: _personalEntries(user, l10n, locale),
                ),

                // ─── Contact ────────────────────────────────────
                if (_isOwner && _hasContact(user))
                  _Section(
                    icon: Icons.contact_page_outlined,
                    title: l10n.contactInfoText,
                    entries: _contactEntries(user, l10n),
                  ),

                // ─── Location ───────────────────────────────────
                if (_isOwner && _hasLocation(user))
                  _Section(
                    icon: Icons.place_outlined,
                    title: l10n.locationInfoText,
                    entries: _locationEntries(user, l10n),
                  ),

                // ─── Subscription ───────────────────────────────
                if (_isOwner && subscription != null)
                  _Section(
                    icon: Icons.workspace_premium_outlined,
                    title: l10n.subscriptionInfoText,
                    entries: _subscriptionEntries(subscription, plan, l10n),
                  ),

                // ─── Wallet ─────────────────────────────────────
                if (_isOwner && user.hasInlinedWallet)
                  _Section(
                    icon: Icons.account_balance_wallet_outlined,
                    title: l10n.walletSectionText,
                    entries: _walletEntries(user.wallet!, l10n),
                  ),

                // ─── Account ────────────────────────────────────
                if (_isOwner)
                  _Section(
                    icon: Icons.shield_outlined,
                    title: l10n.accountStatusText,
                    entries: _accountEntries(user, l10n, locale),
                  ),

                // ─── Preferences ────────────────────────────────
                if (_isOwner) _PreferencesSection(user: user, l10n: l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Entry builders ====================

  bool _hasContact(AppUser user) {
    return (user.personPhone ?? '').isNotEmpty ||
        (user.personEmail ?? '').isNotEmpty;
  }

  bool _hasLocation(AppUser user) {
    return (user.locationName ?? '').isNotEmpty ||
        (user.addressStreet ?? '').isNotEmpty ||
        (user.addressCity ?? '').isNotEmpty ||
        (user.addressCountry ?? '').isNotEmpty ||
        (user.locationLatitude ?? 0) != 0 ||
        (user.locationLongitude ?? 0) != 0;
  }

  List<_Entry> _personalEntries(
    AppUser user,
    AppLocalizations l10n,
    String locale,
  ) {
    final genderLabel = user.personGender.isKnown
        ? localizedGenderLabel(l10n, user.personGender)
        : null;

    return [
      _Entry(
        icon: Icons.badge_outlined,
        label: l10n.firstNameText,
        value: user.personFirstName,
      ),
      _Entry(
        icon: Icons.badge_outlined,
        label: l10n.lastNameText,
        value: user.personLastName,
      ),
      _Entry(
        icon: Icons.cake_outlined,
        label: l10n.birthdayText,
        value: _formatDateOnly(user.personBirthDate, locale),
      ),
      _Entry(
        icon: Icons.wc_outlined,
        label: l10n.genderText,
        value: genderLabel,
      ),
      _Entry(
        icon: Icons.bloodtype_outlined,
        label: l10n.bloodTypeText,
        value: user.bloodType,
      ),
    ];
  }

  List<_Entry> _contactEntries(AppUser user, AppLocalizations l10n) {
    return [
      _Entry(
        icon: Icons.phone_outlined,
        label: l10n.phoneText,
        value: user.personPhone,
        copyable: true,
        copyLabel: l10n.phoneText,
      ),
      _Entry(
        icon: Icons.email_outlined,
        label: l10n.emailText,
        value: user.personEmail,
        copyable: true,
        copyLabel: l10n.emailText,
      ),
    ];
  }

  List<_Entry> _locationEntries(AppUser user, AppLocalizations l10n) {
    final coords = _formatCoordinates(
      user.locationLatitude,
      user.locationLongitude,
    );

    return [
      _Entry(
        icon: Icons.label_outline,
        label: l10n.locationNameText,
        value: user.locationName,
      ),
      _Entry(
        icon: Icons.signpost_outlined,
        label: l10n.streetText,
        value: user.addressStreet,
      ),
      _Entry(
        icon: Icons.location_city_outlined,
        label: l10n.cityText,
        value: user.addressCity,
      ),
      _Entry(
        icon: Icons.markunread_mailbox_outlined,
        label: l10n.postalCodeText,
        value: user.addressPostalCode,
      ),
      _Entry(
        icon: Icons.public_outlined,
        label: l10n.countryText,
        value: user.addressCountry,
      ),
      _Entry(
        icon: Icons.my_location_outlined,
        label: l10n.coordinatesText,
        value: coords,
        copyable: true,
        copyLabel: l10n.coordinatesText,
      ),
    ];
  }

  List<_Entry> _subscriptionEntries(
    Subscription sub,
    Plan? plan,
    AppLocalizations l10n,
  ) {
    return [
      // Plan name, when we have it. If the catalogue hasn't been
      // fetched, the entry is filtered out and the section just shows
      // the subscription's own fields.
      if (plan != null && plan.planName.isNotEmpty)
        _Entry(
          icon: Icons.card_membership_outlined,
          label: l10n.subscriptionPlanText,
          value: plan.planName,
        ),
      if (plan != null)
        _Entry(
          icon: Icons.payments_outlined,
          label: l10n.subscriptionPriceText,
          value:
              '${plan.planPrice.toStringAsFixed(2)} ${l10n.currencySymbol ?? 'DA'}',
        ),
      if (plan != null)
        _Entry(
          icon: Icons.repeat_outlined,
          label: l10n.billingCycleText,
          value: _formatBillingCycle(l10n, plan.billingCycle),
        ),
      _Entry(
        icon: Icons.speed_outlined,
        label: l10n.subscriptionQuotaText,
        value: sub.subscriptionQuota?.toString(),
      ),
      _Entry(
        icon: Icons.event_outlined,
        label: l10n.subscriptionExpiryText,
        value: sub.subscriptionExpiry == null
            ? l10n.subscriptionNeverExpiresLabel
            : _formatDateTime(sub.subscriptionExpiry),
      ),
      _Entry(
        icon: Icons.event_available_outlined,
        label: l10n.subscriptionCreatedText,
        value: _formatDateTime(sub.subscriptionCreatedAt),
      ),
      _Entry(
        icon: Icons.check_circle_outline,
        label: l10n.subscriptionStatusText,
        value: sub.isActive
            ? l10n.subscriptionActiveLabel
            : l10n.subscriptionInactiveLabel,
      ),
    ];
  }

  List<_Entry> _walletEntries(Wallet wallet, AppLocalizations l10n) {
    return [
      _Entry(
        icon: Icons.account_balance_wallet_outlined,
        label: l10n.walletBalanceText,
        value: '${wallet.walletBalance.toStringAsFixed(2)} '
            '${wallet.walletCurrency}',
      ),
      _Entry(
        icon: Icons.category_outlined,
        label: l10n.walletTypeText,
        value: _formatWalletType(l10n, wallet.walletType),
      ),
      _Entry(
        icon: Icons.verified_outlined,
        label: l10n.walletStatusText,
        value: _formatWalletStatus(l10n, wallet.walletStatus),
      ),
    ];
  }

  List<_Entry> _accountEntries(
    AppUser user,
    AppLocalizations l10n,
    String locale,
  ) {
    return [
      if (user.appUserLoginOption != null)
        _Entry(
          icon: user.appUserLoginOption == LoginOption.google
              ? Icons.g_mobiledata
              : Icons.lock_outline,
          label: l10n.loginMethodText,
          value: _formatLoginOption(l10n, user.appUserLoginOption!),
        ),
      _Entry(
        icon: Icons.timer_outlined,
        label: l10n.lastActiveText,
        value: _formatDateTime(user.appUserLastActive),
      ),
      _Entry(
        icon: Icons.calendar_today_outlined,
        label: l10n.accountCreatedText,
        value: _formatDateTime(user.appUserCreation),
      ),
      _Entry(
        icon: Icons.update_outlined,
        label: l10n.accountUpdatedText,
        value: _formatDateTime(user.appUserLastUpdated),
      ),
    ];
  }

  // ==================== Formatters ====================

  String _formatVerification(AppLocalizations l10n, VerifiedAppUser status) {
    switch (status) {
      case VerifiedAppUser.verified:
        return l10n.verifiedLabel;
      case VerifiedAppUser.unverified:
        return l10n.unverifiedLabel;
      case VerifiedAppUser.unknown:
        return l10n.unknownLabel;
    }
  }

  String _formatLoginOption(AppLocalizations l10n, LoginOption option) {
    switch (option) {
      case LoginOption.google:
        return l10n.loginOptionGoogle;
      case LoginOption.verdelia:
        return l10n.loginOptionVerdelia;
    }
  }

  String _formatWalletType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'user':
        return l10n.walletTypeUser;
      case 'provider':
        return l10n.walletTypeProvider;
      case 'organization':
        return l10n.walletTypeOrganization;
      case 'system':
        return l10n.walletTypeSystem;
      case 'virtual':
        return l10n.walletTypeVirtual;
      case 'business':
        return l10n.walletTypeBusiness;
      default:
        return type;
    }
  }

  String _formatWalletStatus(AppLocalizations l10n, String status) {
    switch (status) {
      case 'active':
        return l10n.walletStatusActive;
      case 'pending_verification':
        return l10n.walletStatusPendingVerification;
      case 'inactive':
        return l10n.walletStatusInactive;
      case 'suspended':
        return l10n.walletStatusSuspended;
      case 'closed':
        return l10n.walletStatusClosed;
      default:
        return status;
    }
  }

  String _formatBillingCycle(AppLocalizations l10n, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return l10n.billingCycleMonthly;
      case BillingCycle.semestrial:
        return l10n.billingCycleSemestrial;
      case BillingCycle.yearly:
        return l10n.billingCycleYearly;
      case BillingCycle.lifetime:
        return l10n.billingCycleLifetime;
    }
  }

  String? _formatCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat == 0.0 && lng == 0.0) return null;
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  /// Date-only. `person_birth_date` is a Date column on the backend,
  /// so no time component is meaningful.
  String? _formatDateOnly(String? raw, String locale) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.yMd(locale).format(parsed);
  }

  String? _formatDateTime(DateTime? date) {
    if (date == null) return null;
    final locale =
        context.read<LocaleProvider>().locale?.toLanguageTag() ?? 'en';
    return DateFormat.yMd(locale).add_Hm().format(date.toLocal());
  }
}

// ══════════════════════════════════════════════════════════════════
// Identity header
// ══════════════════════════════════════════════════════════════════

class _IdentityHeader extends StatelessWidget {
  final AppUser user;
  final bool isOwner;
  final AppLocalizations l10n;

  const _IdentityHeader({
    required this.user,
    required this.isOwner,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fullName = user.displayName;
    final avatarSize = MediaQuery.of(context).size.width * 0.24;

    return Semantics(
      label: fullName.isEmpty ? l10n.userInfoText : fullName,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.tertiary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FlippingAvatar(
                  imageUrl: user.appUserImageUrl ?? '',
                  qrData: 'user:${user.idAppUser ?? 0}',
                  size: avatarSize,
                  borderColor: cs.surface,
                  backgroundColor: cs.surfaceVariant,
                ),
              ),
              if (user.verifiedAppUser != null)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _VerifiedDot(
                    verified: user.isVerified,
                    borderColor: cs.surface,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullName.isEmpty ? '—' : fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if ((user.appUserName ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@${user.appUserName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (user.verifiedAppUser != null)
                _StatusBadge(
                  icon: user.isVerified
                      ? Icons.verified_rounded
                      : Icons.help_outline,
                  label: _formatVerification(user.verifiedAppUser!),
                  tone: user.isVerified
                      ? _BadgeTone.positive
                      : _BadgeTone.neutral,
                ),
              _StatusBadge(
                icon: Icons.workspace_premium_outlined,
                label: _formatUserType(user.appUserType),
                tone: _BadgeTone.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVerification(VerifiedAppUser status) {
    switch (status) {
      case VerifiedAppUser.verified:
        return l10n.verifiedLabel;
      case VerifiedAppUser.unverified:
        return l10n.unverifiedLabel;
      case VerifiedAppUser.unknown:
        return l10n.unknownLabel;
    }
  }

  String _formatUserType(AppUserType? type) {
    switch (type) {
      case AppUserType.customer:
        return l10n.customer;
      case AppUserType.provider:
        return l10n.provider;
      case AppUserType.guest:
      default:
        return l10n.guest;
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// Status strip — subscription, wallet, quota at a glance
// ══════════════════════════════════════════════════════════════════

class _StatusStrip extends StatelessWidget {
  final AppUser user;
  final Subscription? subscription;
  final AppLocalizations l10n;

  const _StatusStrip({
    required this.user,
    required this.subscription,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    if (subscription != null) {
      cards.add(
        _StatusCard(
          icon: subscription!.isActive
              ? Icons.workspace_premium
              : Icons.workspace_premium_outlined,
          label: l10n.subscriptionInfoText,
          value: subscription!.isActive
              ? l10n.subscriptionActiveLabel
              : l10n.subscriptionInactiveLabel,
          tone:
              subscription!.isActive ? _BadgeTone.positive : _BadgeTone.warning,
        ),
      );
    }

    if (user.hasInlinedWallet) {
      cards.add(
        _StatusCard(
          icon: Icons.account_balance_wallet,
          label: l10n.walletBalanceText,
          value:
              '${user.wallet!.walletBalance.toStringAsFixed(2)} ${user.wallet!.walletCurrency}',
          tone:
              user.wallet!.isActive ? _BadgeTone.positive : _BadgeTone.neutral,
        ),
      );
    }

    cards.add(
      _StatusCard(
        icon: Icons.bolt,
        label: l10n.quotaText,
        value: '${user.quota}',
        tone: user.quota > 0 ? _BadgeTone.positive : _BadgeTone.neutral,
      ),
    );

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _BadgeTone tone;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (bg, fg) = tone.colors(cs);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg.withOpacity(0.75),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Section — icon + title, then a responsive grid of entry tiles
// ══════════════════════════════════════════════════════════════════

class _Entry {
  final IconData icon;
  final String label;
  final String? value;
  final bool copyable;
  final String? copyLabel;

  const _Entry({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.copyLabel,
  });

  bool get hasValue => (value ?? '').isNotEmpty;
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_Entry> entries;

  const _Section({
    required this.icon,
    required this.title,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out entries that have no value to keep cards tight. An
    // entry with `value == null` or empty is a missing field, not an
    // interesting empty state.
    final filled = entries.where((e) => e.hasValue).toList();
    if (filled.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: icon, title: title),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _columnsForWidth(
                constraints.maxWidth,
                itemMinWidth: 220,
              );

              if (columns <= 1 || filled.length == 1) {
                return _StackedCard(entries: filled);
              }

              return _GridOfTiles(
                constraints: constraints,
                entries: filled,
                columns: columns,
              );
            },
          ),
        ],
      ),
    );
  }

  int _columnsForWidth(
    double width, {
    required double itemMinWidth,
    double spacing = 10,
  }) {
    if (!width.isFinite || width <= 0) return 1;
    final count = ((width + spacing) / (itemMinWidth + spacing)).floor();
    return count.clamp(1, 4);
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedCard extends StatelessWidget {
  final List<_Entry> entries;

  const _StackedCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spaced = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      spaced.add(_EntryTile(entry: entries[i]));
      if (i != entries.length - 1) {
        spaced.add(Divider(
          height: 1,
          thickness: 1,
          color: cs.outlineVariant.withOpacity(0.4),
        ));
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: spaced),
      ),
    );
  }
}

class _GridOfTiles extends StatelessWidget {
  final BoxConstraints constraints;
  final List<_Entry> entries;
  final int columns;

  const _GridOfTiles({
    required this.constraints,
    required this.entries,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;
    final totalSpacing = spacing * (columns - 1);
    final tileWidth = (constraints.maxWidth - totalSpacing) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: entries
          .map(
            (entry) => SizedBox(
              width: tileWidth,
              child: _TitledCard(child: _EntryTile(entry: entry)),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TitledCard extends StatelessWidget {
  final Widget child;

  const _TitledCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Entry tile — icon, label, value. Copies on tap when marked copyable.
// ══════════════════════════════════════════════════════════════════

class _EntryTile extends StatelessWidget {
  final _Entry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final display = entry.value!;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(entry.icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (entry.copyable)
                Icon(
                  Icons.content_copy_rounded,
                  size: 13,
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            display,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (!entry.copyable) return tile;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: display));
        if (!context.mounted) return;
        final label = entry.copyLabel ?? entry.label;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('$label copied'),
              duration: const Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
              width: 220,
            ),
          );
      },
      child: tile,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Preferences — compact layout, decoded from the JSON blob
// ══════════════════════════════════════════════════════════════════

class _PreferencesSection extends StatelessWidget {
  final AppUser user;
  final AppLocalizations l10n;

  const _PreferencesSection({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final prefs = _decodePreferences(user.appUserPreferences);
    if (prefs.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final rows = <Widget>[];

    void addIfPresent(String key, IconData icon, String label) {
      final v = prefs[key];
      if (v == null) return;
      String display;
      if (v is bool) {
        display = v ? l10n.enabledLabel : l10n.disabledLabel;
      } else {
        display = v.toString();
        if (display.isEmpty) return;
      }
      rows.add(_PrefChip(icon: icon, label: label, value: display));
    }

    addIfPresent('language', Icons.language_outlined, l10n.languageText);
    addIfPresent('timezone', Icons.access_time_outlined, l10n.timezoneText);
    addIfPresent('currency', Icons.attach_money_outlined, l10n.currencyText);
    addIfPresent('theme', Icons.brightness_6_outlined, l10n.themeText);
    addIfPresent(
        'notifications', Icons.notifications_outlined, l10n.notificationsText);
    addIfPresent(
        'date_format', Icons.calendar_month_outlined, l10n.dateFormatText);

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.tune_outlined,
            title: l10n.preferencesText,
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: cs.surfaceContainerHighest.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Decode the `app_user_preferences` blob.
  ///
  /// The backend double-encodes: the DB column holds a JSON string
  /// whose value is *itself* a JSON string. A single `jsonDecode` can
  /// yield another string; decode twice if needed. Malformed content
  /// returns an empty map — preferences are cosmetic and shouldn't
  /// break the screen.
  Map<String, dynamic> _decodePreferences(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      dynamic decoded = jsonDecode(raw);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {};
    } catch (_) {
      return {};
    }
  }
}

class _PrefChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PrefChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Small widgets
// ══════════════════════════════════════════════════════════════════

class _VerifiedDot extends StatelessWidget {
  final bool verified;
  final Color borderColor;

  const _VerifiedDot({required this.verified, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: verified ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
      ),
    );
  }
}

enum _BadgeTone { positive, neutral, warning }

extension on _BadgeTone {
  (Color background, Color foreground) colors(ColorScheme cs) {
    switch (this) {
      case _BadgeTone.positive:
        return (
          const Color(0xFF1E8E5A).withOpacity(0.12),
          const Color(0xFF1E8E5A)
        );
      case _BadgeTone.warning:
        return (
          const Color(0xFFB26A00).withOpacity(0.12),
          const Color(0xFFB26A00)
        );
      case _BadgeTone.neutral:
        return (
          cs.surfaceContainerHighest.withOpacity(0.6),
          cs.onSurfaceVariant
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final _BadgeTone tone;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (bg, fg) = tone.colors(cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
