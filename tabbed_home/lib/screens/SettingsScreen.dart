import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:tabbed_home/screens/PasswordChangeScreen.dart';
import 'package:tabbed_home/screens/PdfViewerScreen.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:health/screens/informations_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _Section(
            title: loc.appearanceText,
            children: const [
              _LanguageTile(),
              _ThemeModeTile(),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<AppUserNotifier>(
            builder: (context, auth, _) => _Section(
              title: loc.accountText,
              children: [
                if (auth.isAuthenticated) ...[
                  _ProfileUpdateTile(),
                  _PasswordUpdateTile(),
                ],
                const _LegalDocumentsTile(),
                const _AboutTile(),
                _AuthActionTile(auth: auth),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SECTION ====================

/// Groups related tiles under a labeled, rounded card.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _interleaveDividers(children),
          ),
        ),
      ],
    );
  }

  /// Inserts thin dividers between tiles, respecting the section's horizontal inset.
  List<Widget> _interleaveDividers(List<Widget> items) {
    if (items.length <= 1) return items;

    return [
      for (var i = 0; i < items.length; i++) ...[
        items[i],
        if (i < items.length - 1)
          const Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            thickness: 0.5,
          ),
      ],
    ];
  }
}

// ==================== TILE PRIMITIVE ====================

/// A consistent, well-spaced settings tile with a colored leading icon.
///
/// Every settings row uses this so spacing, icon sizing, and colors
/// stay uniform across the entire screen.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? scheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _LeadingIcon(icon: icon, color: effectiveIconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: scheme.onSurfaceVariant),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant)
              : null),
      onTap: onTap,
    );
  }
}

/// Rounded tinted square behind a settings icon — replaces the old circle
/// pattern for a more modern Material 3 feel.
class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LeadingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ==================== INDIVIDUAL TILES ====================

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<LocaleProvider>();
    final current = _languageName(provider.languagePreference);

    return _SettingsTile(
      icon: Icons.translate_rounded,
      title: loc.languageText,
      subtitle: current,
      onTap: () => _showLanguageSheet(context, provider),
    );
  }

  String _languageName(String? code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  void _showLanguageSheet(BuildContext context, LocaleProvider provider) {
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  loc.selectLanguageText,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              _LanguageOption(
                label: 'English',
                code: 'en',
                provider: provider,
              ),
              _LanguageOption(
                label: 'Français',
                code: 'fr',
                provider: provider,
              ),
              _LanguageOption(
                label: 'العربية',
                code: 'ar',
                provider: provider,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final LocaleProvider provider;

  const _LanguageOption({
    required this.label,
    required this.code,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = provider.languagePreference == code;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? scheme.primary : scheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : null,
      onTap: () async {
        await provider.setLanguagePreference(code);
        provider.setLocale(Locale(code));
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<LocaleProvider>();
    final isDark = provider.isDarkMode ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return _SettingsTile(
      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
      title: loc.darkModeText,
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (_) => provider.toggleTheme(),
      ),
    );
  }
}

class _ProfileUpdateTile extends StatelessWidget {
  const _ProfileUpdateTile();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = context.read<AppUserNotifier>().appUser;

    return _SettingsTile(
      icon: Icons.person_outline_rounded,
      title: loc.profileUpdateText,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.userEdit,
        arguments: {'user': user},
      ),
    );
  }
}

class _PasswordUpdateTile extends StatelessWidget {
  const _PasswordUpdateTile();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return _SettingsTile(
      icon: Icons.lock_outline_rounded,
      title: loc.passwordUpdateText,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PasswordChangeScreen()),
      ),
    );
  }
}

class _LegalDocumentsTile extends StatelessWidget {
  const _LegalDocumentsTile();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return _SettingsTile(
      icon: Icons.gavel_rounded,
      title: loc.legalDocumentsTitle,
      onTap: () => _showDocumentsSheet(context),
    );
  }

  void _showDocumentsSheet(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(
                  loc.legalDocumentsTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: loc.privacyPolicy,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openPdf(context,
                      docType: 'policy', title: loc.privacyPolicy);
                },
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: loc.termsOfUse,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openPdf(context, docType: 'terms', title: loc.termsOfUse);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openPdf(
    BuildContext context, {
    required String docType,
    required String title,
  }) {
    final locale = Localizations.localeOf(context).languageCode;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          assetPath: 'assets/docs/${docType}_$locale.pdf',
          screenTitle: title,
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return _SettingsTile(
      icon: Icons.info_outline_rounded,
      title: loc.aboutProvider,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HealthInfoScreen()),
      ),
    );
  }
}

// ==================== AUTH ACTION ====================

/// Login / Logout, styled as a single tile that changes meaning based on
/// authentication state. Uses the semantic error color for logout so it's
/// clearly a destructive action.
class _AuthActionTile extends StatelessWidget {
  final AppUserNotifier auth;

  const _AuthActionTile({required this.auth});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    if (!auth.isAuthenticated) {
      return _SettingsTile(
        icon: Icons.login_rounded,
        title: loc.loginText,
        onTap: () => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        ),
      );
    }

    return _SettingsTile(
      icon: Icons.logout_rounded,
      iconColor: scheme.error,
      titleColor: scheme.error,
      title: loc.logoutText,
      onTap: () => _confirmLogout(context),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.logout_rounded, color: scheme.error),
        title: Text(loc.loggingOutText),
        content: Text(loc.logoutConsentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.cancelTxt),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.logoutText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform logout
    await auth.signOut();

    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(loc.logoutText),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
