import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/user_change_notifier.dart';
import 'package:tabbed_home/screens/components/flipping_avatar.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFloatingActionButton(context),
      body: CustomScrollView(
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
    );
  }

  // ---------------------------------------------------------------- FAB

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      heroTag: 'profile-info-fab',
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      elevation: 2,
      onPressed: () => showIllnessInfoPopup(context),
      icon: const Icon(Icons.info_outline),
      label: Text(AppLocalizations.of(context)!.illnessOverviewTitle),
    );
  }

  // ------------------------------------------------------- Main content

  Widget _buildProfileContent(BuildContext context, AppUser user) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
              _buildInfoTile(Icons.person_outline, l10n.usernameText,
                  user.appUserName, theme),
              _buildInfoTile(
                  Icons.verified_user_outlined,
                  l10n.userTypeText,
                  _formatUserType(l10n, user.appUserType ?? AppUserType.guest),
                  theme),
            ],
          ),
          _buildProfileSection(
            icon: Icons.person_pin_outlined,
            title: l10n.personalInfoText,
            theme: theme,
            children: [
              _buildInfoTile(Icons.badge_outlined, l10n.firstNameText,
                  user.personFirstName, theme),
              _buildInfoTile(Icons.badge_outlined, l10n.lastNameText,
                  user.personLastName, theme),
              _buildInfoTile(Icons.cake_outlined, l10n.birthdayText,
                  user.personBirthDate, theme),
              _buildInfoTile(
                  Icons.wc_outlined, l10n.genderText, user.personGender, theme),
            ],
          ),
          _buildProfileSection(
            icon: Icons.place_outlined,
            title: l10n.locationInfoText,
            theme: theme,
            children: [
              _buildInfoTile(Icons.location_city_outlined, l10n.cityText,
                  user.addressCity, theme),
              _buildInfoTile(Icons.public_outlined, l10n.countryText,
                  user.addressCountry, theme),
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
      // case AppUserType.patient:
      //   return l10n.patient;
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
                // Status indicator (placeholder — wire to real status if available)
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

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    // Interleave dividers between children.
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with accent bar
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
          Card(
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
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------- Info tile

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String? value,
    ThemeData theme,
  ) {
    final hasValue = value?.isNotEmpty ?? false;
    final display = hasValue ? value! : '—';

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
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                display,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasValue
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------ Bottom sheet

  void showIllnessInfoPopup(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            // Grab handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: _buildIllnessInfoTab(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllnessInfoTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.illnessOverviewTitle),
        _buildSectionText(l10n.illnessOverviewContent),
        const SizedBox(height: 24),
        _buildSectionHeader(l10n.symptomsTitle),
        _buildSymptomItem(l10n.symptom1),
        _buildSymptomItem(l10n.symptom2),
        _buildSymptomItem(l10n.symptom3),
        const SizedBox(height: 24),
        _buildSectionHeader(l10n.treatmentTitle),
        _buildSectionText(l10n.treatmentContent),
        const SizedBox(height: 24),
        _buildSectionHeader(l10n.resourcesTitle),
        _buildResourceLink(context, l10n.resource1),
        _buildResourceLink(context, l10n.resource2),
      ],
    );
  }

  Widget _buildSymptomItem(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(
              Icons.fiber_manual_record,
              size: 8,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceLink(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Opening: $text'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1200),
              ),
            );
          // TODO: launch URL
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.open_in_new,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
