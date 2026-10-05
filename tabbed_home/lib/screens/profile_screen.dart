import 'dart:convert';

import 'package:app_constants/app_routes.dart';
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

typedef _ProfileSections = ({
  List<Widget> personal,
  List<Widget> business,
  List<Widget> account,
  Widget? preferences,
});

/// Which profile the screen is rendering.
enum ProfileMode { owner, visitor }

class _Breakpoint {
  static const double medium = 720;
  static const double expanded = 1080;
}

class _Rhythm {
  static const double sectionGap = 20;
  static const double cardRadius = 16;
}

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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool get _isOwner => widget.mode == ProfileMode.owner;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null && _isOwner) {
      return Scaffold(
        floatingActionButton: _isOwner ? const _UpgradePlanFab() : null,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Consumer<AppUserNotifier>(
            builder: (context, notifier, _) {
              final user = notifier.appUser;
              if (user is! AppUser) {
                return const _LoadingState();
              }
              return _buildBody(context, user, notifier);
            },
          ),
        ),
      );
    }

    final user = widget.user;
    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(AppLocalizations.of(context)?.noUserToDisplay ?? '—'),
          ),
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
    final cs = Theme.of(context).colorScheme;

    final Subscription? subscription =
        user.subscription ?? notifier?.subscription;

    Plan? plan;
    final planId = subscription?.subscriptionPlanId;
    if (planId != null && planId > 0) {
      plan = notifier?.planById(planId);
    }

    if (_isOwner && plan == null && planId != null && planId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier?.fetchPlans();
      });
    }

    final sections = _buildSections(
      user: user,
      l10n: l10n,
      locale: locale,
      subscription: subscription,
      plan: plan,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isExpanded = constraints.maxWidth >= _Breakpoint.expanded;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileCoverHeader(
                user: user,
                isOwner: _isOwner,
                l10n: l10n,
              ),
            ),
            if (_isOwner)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _StatusStrip(
                    user: user,
                    subscription: subscription,
                    l10n: l10n,
                  ),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                controller: _tabController,
                l10n: l10n,
                colors: cs,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: isExpanded
                  ? _ExpandedBody(
                      tabController: _tabController,
                      personal: sections.personal,
                      business: sections.business,
                      account: sections.account,
                      preferences: sections.preferences,
                      bottomPadding: _isOwner ? 96 : 32,
                    )
                  : _CompactBody(
                      tabController: _tabController,
                      personal: sections.personal,
                      business: sections.business,
                      account: sections.account,
                      preferences: sections.preferences,
                      bottomPadding: _isOwner ? 96 : 32,
                    ),
            ),
          ],
        );
      },
    );
  }

  _ProfileSections _buildSections({
    required AppUser user,
    required AppLocalizations l10n,
    required String locale,
    required Subscription? subscription,
    required Plan? plan,
  }) {
    // ── Personal tab: identity + contact + location ──
    final personal = <Widget>[
      _Section(
        icon: Icons.person_pin_outlined,
        title: l10n.personalInfoText,
        entries: _personalEntries(user, l10n, locale),
      ),
      if (_isOwner && _hasContact(user))
        _Section(
          icon: Icons.contact_page_outlined,
          title: l10n.contactInfoText,
          entries: _contactEntries(user, l10n),
        ),
      if (_isOwner && _hasLocation(user))
        _Section(
          icon: Icons.place_outlined,
          title: l10n.locationInfoText,
          entries: _locationEntries(user, l10n),
        ),
    ];

    // ── Business tab: subscription + wallet ──
    final business = <Widget>[
      if (_isOwner && subscription != null)
        _Section(
          icon: Icons.workspace_premium_outlined,
          title: l10n.subscriptionInfoText,
          entries: _subscriptionEntries(subscription, plan, l10n),
        ),
      if (_isOwner && user.hasInlinedWallet)
        _Section(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.walletSectionText,
          entries: _walletEntries(user.wallet!, l10n),
        ),
    ];

    // ── Account tab: status + timestamps ──
    final account = <Widget>[
      if (_isOwner)
        _Section(
          icon: Icons.shield_outlined,
          title: l10n.accountStatusText,
          entries: _accountEntries(user, l10n, locale),
        ),
    ];

    return (
      personal: personal,
      business: business,
      account: account,
      preferences:
          _isOwner ? _PreferencesSection(user: user, l10n: l10n) : null,
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
          value: '${plan.planPrice.toStringAsFixed(2)} ${l10n.currencySymbol}',
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
            : _formatDateTime(context, sub.subscriptionExpiry!),
      ),
      _Entry(
        icon: Icons.event_available_outlined,
        label: l10n.subscriptionCreatedText,
        value: _formatDateTime(context, sub.subscriptionCreatedAt),
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
        value: _formatDateTime(context, user.appUserLastActive),
      ),
      _Entry(
        icon: Icons.calendar_today_outlined,
        label: l10n.accountCreatedText,
        value: _formatDateTime(context, user.appUserCreation),
      ),
      _Entry(
        icon: Icons.update_outlined,
        label: l10n.accountUpdatedText,
        value: _formatDateTime(context, user.appUserLastUpdated),
      ),
    ];
  }

  // ==================== Formatters ====================

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

  String? _formatDateOnly(String? raw, String locale) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.yMd(locale).format(parsed);
  }

  String? _formatDateTime(BuildContext context, DateTime? date) {
    if (date == null) return null;
    final locale =
        context.read<LocaleProvider>().locale?.toLanguageTag() ?? 'en';
    return DateFormat.yMd(locale).add_Hm().format(date.toLocal());
  }
}

// ══════════════════════════════════════════════════════════════════
// Loading state
// ══════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)?.loading ?? 'Loading…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Profile cover + identity header
// ══════════════════════════════════════════════════════════════════
//
// Facebook pattern: a full-bleed cover band with a gradient, the
// avatar overlapping its bottom edge, then a horizontal identity row
// underneath. On narrow screens the identity row wraps; on wide
// screens the name and action buttons sit side by side.

class _ProfileCoverHeader extends StatelessWidget {
  final AppUser user;
  final bool isOwner;
  final AppLocalizations l10n;

  const _ProfileCoverHeader({
    required this.user,
    required this.isOwner,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fullName = user.displayName;
    final avatarSize =
        (MediaQuery.sizeOf(context).width * 0.28).clamp(84.0, 140.0);
    const buttonOverhang = 18.0;
    final avatarBox = avatarSize * 2 + buttonOverhang;
    const coverHeight = 180.0;
    const avatarDrop = 8.0;

    final showBack = !isOwner;

    // The top inset is how much space the status bar / notch eats.
    // We extend the cover band upward by this amount so it fills the
    // area behind the status bar. The identity row stays where it was
    // relative to the visible cover.
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _Breakpoint.medium;
        // The visible cover is `coverHeight` tall, but the painted band
        // extends `topInset` further up so it goes behind the status
        // bar. The identity row's top position is measured from the
        // visible cover's top, so `rowTop` is unchanged.
        final rowTop = coverHeight - (avatarBox / 2 - avatarDrop);
        final totalCoverHeight = coverHeight + topInset;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ─── Cover band — extended upward behind the status bar ───
            Positioned(
              top: -topInset,
              left: 0,
              right: 0,
              height: totalCoverHeight,
              child: _CoverBand(colors: cs),
            ),

            // ─── Identity row + inner content ───
            Padding(
              padding: EdgeInsets.only(top: rowTop),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isWide
                    ? _WideIdentityRow(
                        user: user,
                        isOwner: isOwner,
                        l10n: l10n,
                        avatarSize: avatarSize,
                        avatarBox: avatarBox,
                        buttonOverhang: buttonOverhang,
                        fullName: fullName,
                      )
                    : _NarrowIdentityRow(
                        user: user,
                        isOwner: isOwner,
                        l10n: l10n,
                        avatarSize: avatarSize,
                        avatarBox: avatarBox,
                        buttonOverhang: buttonOverhang,
                        fullName: fullName,
                      ),
              ),
            ),

            // ─── Back button — only in visitor mode ───
            if (showBack)
              Positioned(
                top: 0,
                left: 0,
                child: Padding(
                  padding: EdgeInsets.only(top: topInset + 8, left: 8),
                  child: _BackButton(
                    onTap: () => _handleBack(context),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _handleBack(BuildContext context) {
    final navigator = Navigator.of(context);
    // If this screen is the first route in the stack (deep link, cold
    // start on a visitor profile), there's nothing to pop. Fall back to
    // the app's home. If the caller navigated here from a personnel
    // list, this pops back to that list naturally.
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    }
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CoverBand extends StatelessWidget {
  final ColorScheme colors;

  const _CoverBand({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withOpacity(0.85),
                colors.primary.withOpacity(0.55),
                colors.tertiary.withOpacity(0.45),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DotPatternPainter(
                color: Colors.white.withOpacity(0.06),
                spacing: 22,
                radius: 1.4,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 60,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Wide layout: avatar left, name + actions right ──

class _WideIdentityRow extends StatelessWidget {
  final AppUser user;
  final bool isOwner;
  final AppLocalizations l10n;
  final double avatarSize;
  final double avatarBox;
  final double buttonOverhang;
  final String fullName;

  const _WideIdentityRow({
    required this.user,
    required this.isOwner,
    required this.l10n,
    required this.avatarSize,
    required this.avatarBox,
    required this.buttonOverhang,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Avatar(
          user: user,
          avatarSize: avatarSize,
          avatarBox: avatarBox,
          buttonOverhang: buttonOverhang,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName.isEmpty ? '—' : fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
                ),
                if ((user.appUserName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${user.appUserName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _IdentityBadgesRow(user: user, l10n: l10n),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 8),
        //   child: _HeaderActions(
        //     isOwner: isOwner,
        //     onEdit: isOwner ? () => _onEditPressed(context) : null,
        //     onShare: () => _onSharePressed(context),
        //   ),
        // ),
      ],
    );
  }

  void _onEditPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile (not implemented)')),
    );
  }

  void _onSharePressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share profile (not implemented)')),
    );
  }
}

// ── Narrow layout: avatar and name in a column ──

class _NarrowIdentityRow extends StatelessWidget {
  final AppUser user;
  final bool isOwner;
  final AppLocalizations l10n;
  final double avatarSize;
  final double avatarBox;
  final double buttonOverhang;
  final String fullName;

  const _NarrowIdentityRow({
    required this.user,
    required this.isOwner,
    required this.l10n,
    required this.avatarSize,
    required this.avatarBox,
    required this.buttonOverhang,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        _Avatar(
          user: user,
          avatarSize: avatarSize,
          avatarBox: avatarBox,
          buttonOverhang: buttonOverhang,
        ),
        const SizedBox(height: 14),
        Text(
          fullName.isEmpty ? '—' : fullName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: cs.onSurface,
            height: 1.15,
          ),
        ),
        if ((user.appUserName ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@${user.appUserName}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _IdentityBadgesRow(user: user, l10n: l10n),
        const SizedBox(height: 14),
        // _HeaderActions(
        //   isOwner: isOwner,
        //   onEdit: isOwner ? () => _onEditPressed(context) : null,
        //   onShare: () => _onSharePressed(context),
        //   fullWidth: true,
        // ),
      ],
    );
  }

  void _onEditPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile (not implemented)')),
    );
  }

  void _onSharePressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share profile (not implemented)')),
    );
  }
}

// ── Avatar with ring and verified dot ──

class _Avatar extends StatelessWidget {
  final AppUser user;
  final double avatarSize;
  final double avatarBox;
  final double buttonOverhang;

  const _Avatar({
    required this.user,
    required this.avatarSize,
    required this.avatarBox,
    required this.buttonOverhang,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: avatarBox,
      height: avatarBox,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.tertiary],
                  ),
                ),
                child: FlippingAvatar(
                  imageUrl: user.appUserImageUrl ?? '',
                  qrData: 'user:${user.idAppUser ?? 0}',
                  size: avatarSize,
                  borderColor: cs.surface,
                  backgroundColor: cs.surfaceVariant,
                ),
              ),
            ),
          ),
          if (user.verifiedAppUser != null)
            Positioned(
              right: buttonOverhang + 4,
              top: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: user.isVerified ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 3),
                ),
                child: user.isVerified
                    ? Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: cs.surface,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Badge row: verified + user type ──

class _IdentityBadgesRow extends StatelessWidget {
  final AppUser user;
  final AppLocalizations l10n;

  const _IdentityBadgesRow({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (user.verifiedAppUser != null)
          _StatusBadge(
            icon: user.isVerified ? Icons.verified_rounded : Icons.help_outline,
            label: _verificationLabel(user.verifiedAppUser!),
            tone: user.isVerified ? _BadgeTone.positive : _BadgeTone.neutral,
          ),
        _StatusBadge(
          icon: Icons.workspace_premium_outlined,
          label: _userTypeLabel(user.appUserType),
          tone: _BadgeTone.neutral,
        ),
      ],
    );
  }

  String _verificationLabel(VerifiedAppUser status) {
    switch (status) {
      case VerifiedAppUser.verified:
        return l10n.verifiedLabel;
      case VerifiedAppUser.unverified:
        return l10n.unverifiedLabel;
      case VerifiedAppUser.unknown:
        return l10n.unknownLabel;
    }
  }

  String _userTypeLabel(AppUserType? type) {
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

// ── Action buttons under the name ──

class _HeaderActions extends StatelessWidget {
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final bool fullWidth;

  const _HeaderActions({
    required this.isOwner,
    required this.onEdit,
    required this.onShare,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final buttons = <Widget>[
      if (isOwner && onEdit != null)
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text(l10n?.editProfileLabel ?? 'Edit profile'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      if (onShare != null)
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined, size: 18),
          label: Text(l10n?.shareProfileLabel ?? 'Share'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
    ];

    if (fullWidth) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: buttons[i]),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          buttons[i],
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab bar delegate (pinned header)
// ══════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final AppLocalizations l10n;
  final ColorScheme colors;

  _TabBarDelegate({
    required this.controller,
    required this.l10n,
    required this.colors,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: colors.surface,
      child: Column(
        children: [
          TabBar(
            controller: controller,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: l10n.personalInfoText),
              Tab(
                text: l10n.subscriptionInfoText,
                // Subscription tab is only meaningful for owners, but
                // we always show it and render an empty state when the
                // user isn't an owner. Keeps the tab bar stable
                // across owner/visitor transitions.
              ),
              Tab(text: l10n.accountStatusText),
            ],
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.outlineVariant.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.l10n != l10n ||
        oldDelegate.colors != colors;
  }
}

// ══════════════════════════════════════════════════════════════════
// Compact body — TabBarView with the three section groups
// ══════════════════════════════════════════════════════════════════

class _CompactBody extends StatelessWidget {
  final TabController tabController;
  final List<Widget> personal;
  final List<Widget> business;
  final List<Widget> account;
  final Widget? preferences;
  final double bottomPadding;

  const _CompactBody({
    required this.tabController,
    required this.personal,
    required this.business,
    required this.account,
    required this.preferences,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        _TabScroll(
          sections: personal,
          bottomPadding: bottomPadding,
        ),
        _TabScroll(
          sections: business,
          trailing: preferences,
          bottomPadding: bottomPadding,
        ),
        _TabScroll(
          sections: account,
          bottomPadding: bottomPadding,
        ),
      ],
    );
  }
}

class _TabScroll extends StatelessWidget {
  final List<Widget> sections;
  final Widget? trailing;
  final double bottomPadding;

  const _TabScroll({
    required this.sections,
    this.trailing,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty && trailing == null) {
      return const _EmptyTab();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding),
      children: [
        ...sections,
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Expanded body — two-column split with the tabs on the right
// ══════════════════════════════════════════════════════════════════

class _ExpandedBody extends StatelessWidget {
  final TabController tabController;
  final List<Widget> personal;
  final List<Widget> business;
  final List<Widget> account;
  final Widget? preferences;
  final double bottomPadding;

  const _ExpandedBody({
    required this.tabController,
    required this.personal,
    required this.business,
    required this.account,
    required this.preferences,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    // On expanded screens, the same TabBarView spans the full width,
    // but we constrain the content column to a comfortable reading
    // width and center it. This keeps a wide monitor from stretching
    // the entries to absurd line lengths.
    return TabBarView(
      controller: tabController,
      children: [
        _CenteredColumn(children: personal, bottomPadding: bottomPadding),
        _CenteredColumn(
          children: [...business, if (preferences != null) preferences!],
          bottomPadding: bottomPadding,
        ),
        _CenteredColumn(children: account, bottomPadding: bottomPadding),
      ],
    );
  }
}

class _CenteredColumn extends StatelessWidget {
  final List<Widget> children;
  final double bottomPadding;

  const _CenteredColumn({
    required this.children,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
          children: children,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Empty tab
// ══════════════════════════════════════════════════════════════════

class _EmptyTab extends StatelessWidget {
  const _EmptyTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)?.noInformationAvailable ??
                  'Nothing to show here yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Status strip
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
              ? Icons.workspace_premium_rounded
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
          icon: Icons.account_balance_wallet_rounded,
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
        icon: Icons.bolt_rounded,
        label: l10n.quotaText,
        value: '${user.quota}',
        tone: user.quota > 0 ? _BadgeTone.positive : _BadgeTone.neutral,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final perCard = available >= 360 ? (available - 20) / 3 : available;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map((c) => SizedBox(width: perCard, child: c))
              .toList(growable: false),
        );
      },
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
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: fg.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg,
                    height: 1.1,
                    letterSpacing: -0.2,
                  ),
                ),
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
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Section
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

  static const double _minTileWidth = 210;

  @override
  Widget build(BuildContext context) {
    final filled = entries.where((e) => e.hasValue).toList();
    if (filled.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: _Rhythm.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: icon, title: title),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _columnsForWidth(
                constraints.maxWidth,
                itemMinWidth: _minTileWidth,
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
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.2,
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
          indent: 16,
          endIndent: 16,
          color: cs.outlineVariant.withOpacity(0.4),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(_Rhythm.cardRadius),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
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
        borderRadius: BorderRadius.circular(_Rhythm.cardRadius),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Entry tile
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            entry.icon,
            size: 18,
            color: cs.onSurfaceVariant.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.25,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          if (entry.copyable)
            Icon(
              Icons.content_copy_rounded,
              size: 14,
              color: cs.onSurfaceVariant.withOpacity(0.4),
            ),
        ],
      ),
    );

    if (!entry.copyable) return tile;

    return InkWell(
      borderRadius: BorderRadius.circular(_Rhythm.cardRadius),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: display));
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final label = entry.copyLabel ?? entry.label;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.copiedToClipboard(label)),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 1400),
              behavior: SnackBarBehavior.floating,
              width: 280,
            ),
          );
      },
      child: tile,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Preferences
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
      padding: const EdgeInsets.only(bottom: _Rhythm.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.tune_outlined,
            title: l10n.preferencesText,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(_Rhythm.cardRadius),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
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
                maxLines: 1,
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Dot pattern for the cover
// ══════════════════════════════════════════════════════════════════

class _DotPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double radius;

  _DotPatternPainter({
    required this.color,
    this.spacing = 24,
    this.radius = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}

// ══════════════════════════════════════════════════════════════════
// Badge tone
// ══════════════════════════════════════════════════════════════════

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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradePlanFab extends StatelessWidget {
  const _UpgradePlanFab();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Consumer<AppUserNotifier>(
      builder: (context, notifier, _) {
        // "Active" is not the right test here. A Free subscription
        // is technically active (no expiry, no cancel) but the user
        // hasn't opted into anything — the FAB should invite them
        // to pick a plan, not to manage one they never chose.
        //
        // `hasPaidSubscription` is the correct predicate: true when
        // a subscription exists AND its plan has a non-zero price.
        // Free users get the catalogue. Paid users get the
        // management screen.
        final hasPaidSubscription = _hasPaidSubscription(notifier);

        final label =
            hasPaidSubscription ? loc.managePlanFab : loc.choosePlanFab;

        final icon = hasPaidSubscription
            ? Icons.workspace_premium_rounded
            : Icons.rocket_launch_rounded;

        final route = hasPaidSubscription
            ? AppRoutes.manageSubscription
            : AppRoutes.plans;

        return FloatingActionButton.extended(
          heroTag: 'profile_upgrade_plan_fab',
          onPressed: () => _open(context, route),
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            softWrap: false,
          ),
          tooltip: label,
        );
      },
    );
  }

  /// True when the user has a subscription whose plan is paid.
  ///
  /// Returns false when:
  ///   * there is no subscription at all, or
  ///   * the subscription's plan is the zero-price Free plan, or
  ///   * the plan catalogue hasn't loaded yet (in which case we
  ///     fall through to "choose a plan", which is the safe default
  ///     — a paid user briefly seeing "Choose Plan" is a lesser evil
  ///     than a Free user seeing "Manage Plan").
  bool _hasPaidSubscription(AppUserNotifier notifier) {
    if (!notifier.isSubscriptionActive) return false;

    final sub = notifier.subscription;
    if (sub == null) return false;

    final planId = sub.subscriptionPlanId;
    if (planId == null) return false;

    final plan = notifier.planById(planId);
    if (plan == null) return false;

    return plan.isPaid;
  }

  Future<void> _open(BuildContext context, String route) async {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);

    final changed = await navigator.pushNamed(route);

    if (changed == true && context.mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.planUpdatedConfirmation),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }
}
