import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/user_change_notifier.dart';
import 'package:tabbed_home/screens/components/flipping_avatar.dart';
import 'package:ui/components/gender/gender_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Consumer<AppUserNotifier>(
                builder: (context, notifier, _) {
                  final user = notifier.appUser;
                  if (user is! AppUser) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildProfileContent(context, user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------- Main content

  Widget _buildProfileContent(BuildContext context, AppUser user) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final genderLabel = user.personGender.isKnown
        ? localizedGenderLabel(l10n, user.personGender)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatarSection(user, theme),
          const SizedBox(height: 24),
          _buildProfileSection(
            icon: Icons.badge_outlined,
            title: l10n.userInfoText,
            theme: theme,
            children: [
              _buildInfoTile(
                icon: Icons.person_outline,
                label: l10n.usernameText,
                value: user.appUserName,
                theme: theme,
              ),
              _buildInfoTile(
                icon: Icons.verified_user_outlined,
                label: l10n.userTypeText,
                value: _formatUserType(
                    l10n, user.appUserType ?? AppUserType.guest),
                theme: theme,
              ),
            ],
          ),
          _buildProfileSection(
            icon: Icons.person_pin_outlined,
            title: l10n.personalInfoText,
            theme: theme,
            children: [
              _buildInfoTile(
                icon: Icons.badge_outlined,
                label: l10n.firstNameText,
                value: user.personFirstName,
                theme: theme,
              ),
              _buildInfoTile(
                icon: Icons.badge_outlined,
                label: l10n.lastNameText,
                value: user.personLastName,
                theme: theme,
              ),
              _buildInfoTile(
                icon: Icons.cake_outlined,
                label: l10n.birthdayText,
                value: user.personBirthDate,
                theme: theme,
              ),
              _buildInfoTile(
                icon: Icons.wc_outlined,
                label: l10n.genderText,
                value: genderLabel,
                theme: theme,
              ),
            ],
          ),
          _buildProfileSection(
            icon: Icons.place_outlined,
            title: l10n.locationInfoText,
            theme: theme,
            children: [
              _buildInfoTile(
                icon: Icons.location_city_outlined,
                label: l10n.cityText,
                value: user.addressCity,
                theme: theme,
              ),
              _buildInfoTile(
                icon: Icons.public_outlined,
                label: l10n.countryText,
                value: user.addressCountry,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- Avatar block

  String _formatUserType(AppLocalizations l10n, AppUserType type) {
    switch (type) {
      case AppUserType.customer:
        return l10n.customer;
      case AppUserType.guest:
        return l10n.guest;
      case AppUserType.provider:
        return l10n.provider;
      default:
        return l10n.guest;
    }
  }

  Widget _buildUserAvatarSection(AppUser user, ThemeData theme) {
    final fullName =
        '${user.personFirstName ?? ''} ${user.personLastName ?? ''}'.trim();

    return Semantics(
      label: fullName.isEmpty ? 'User avatar' : fullName,
      child: Center(
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
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FlippingAvatar(
                    imageUrl: user.appUserImageUrl ?? '',
                    qrData: 'user:${user.idAppUser ?? 0}',
                    size: MediaQuery.of(context).size.width * 0.25,
                    borderColor: theme.colorScheme.surface,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fullName.isEmpty ? '—' : fullName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (user.appUserName != null && user.appUserName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '@${user.appUserName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------ Section card

  /// Renders a section as a single-column card on narrow screens, and
  /// as a responsive grid of title+subtitle cards when there's enough
  /// horizontal room.
  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _columnsForWidth(
                constraints.maxWidth,
                itemMinWidth: 220,
                spacing: 10,
              );

              // Single column — stacked list, no inner card chrome.
              if (columns <= 1 || children.length <= 1) {
                return _buildStackedCard(children, theme);
              }

              // Multi-column — grid of title+subtitle cards, no outer
              // card. Each tile is its own card, matching the visual
              // language of the stacked list items.
              return _buildGridOfCards(
                constraints: constraints,
                children: children,
                columns: columns,
                theme: theme,
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

  /// Classic stacked layout: one outer card, all tiles full-width,
  /// separated by hairline dividers. No per-tile chrome.
  Widget _buildStackedCard(List<Widget> children, ThemeData theme) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i != children.length - 1) {
        spaced.add(Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ));
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: spaced),
      ),
    );
  }

  /// Multi-column layout: each tile is its own titled card. No outer
  /// card, no dividers — the per-tile chrome does the separation.
  Widget _buildGridOfCards({
    required BoxConstraints constraints,
    required List<Widget> children,
    required int columns,
    required ThemeData theme,
  }) {
    const spacing = 10.0;
    final totalSpacing = spacing * (columns - 1);
    final tileWidth = (constraints.maxWidth - totalSpacing) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: children
          .map(
            (child) => SizedBox(
              width: tileWidth,
              child: _TitledCard(child: child),
            ),
          )
          .toList(growable: false),
    );
  }

  // -------------------------------------------------------- Info tile

  /// A tile with an icon, a title (the label), and a subtitle (the
  /// value). Used in both the stacked and grid layouts — the layout
  /// changes around it, the tile itself doesn't.
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String? value,
    required ThemeData theme,
  }) {
    final hasValue = value?.isNotEmpty ?? false;
    final display = hasValue ? value! : '—';
    final cs = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: hasValue
          ? () async {
              await Clipboard.setData(ClipboardData(text: display));
              if (!mounted) return;
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
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Title row: icon + label ─────────────────────────
            Row(
              children: [
                Icon(icon, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ─── Subtitle: the value ─────────────────────────────
            Text(
              display,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                color: hasValue
                    ? cs.onSurface
                    : cs.onSurfaceVariant.withOpacity(0.6),
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------ Bottom sheet

  Widget _buildSectionHeader(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Card chrome for the grid layout
// ══════════════════════════════════════════════════════════════════

/// A titled card that wraps a single info tile.
///
/// Only used in the grid layout — the stacked layout relies on the
/// section card's outer surface and dividers instead.
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
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
