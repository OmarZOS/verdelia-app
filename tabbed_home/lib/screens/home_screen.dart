import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui/components/image/image_url.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:tabbed_home/screens/SettingsScreen.dart';
import 'package:tabbed_home/screens/components/notification_button.dart';
import 'package:tabbed_home/screens/components/notifications_panel.dart';
import 'package:tabbed_home/screens/profile_screen.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider_geo/screens/suppliers_map_screen.dart';
import 'package:product_catalog/screens/product_catalog_screen.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final _pages = <Widget>[
    const ProductCatalogScreen(),
    const SuppliersMapScreen(),
    const ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _onTabChanged(index);
  }

  void _onTabChanged(int index) {
    switch (index) {
      case _Tab.catalog:
        final notifier = context.read<ProductNotifier>();
        notifier.fetchProducts(
          categoryId: notifier.currentCategory,
          reset: true,
        );
        break;
      case _Tab.suppliers:
        context.read<SupplierChangeNotifier>().fetchOrganisations();
        break;
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NotificationsPanel(),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isProfileTab = _selectedIndex == _Tab.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(context, _selectedIndex)),
        actions: [
          NotificationButton(
            onPressed: _showNotifications,
            iconColor: scheme.onSurface,
          ),
          if (isProfileTab)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettings,
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: scheme.surfaceContainerHighest,
        destinations: _buildDestinations(context),
      ),
    );
  }

  String _titleFor(BuildContext context, int index) {
    final loc = AppLocalizations.of(context)!;
    switch (index) {
      case _Tab.catalog:
        return loc.productsText;
      case _Tab.suppliers:
        return loc.providersText;
      case _Tab.profile:
        return loc.profileText;
      default:
        return '';
    }
  }

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appUser = context.watch<AppUserNotifier>().appUser;

    return [
      NavigationDestination(
        icon: const Icon(CupertinoIcons.cube_box),
        selectedIcon: const Icon(CupertinoIcons.cube_box_fill),
        label: loc.productsText,
      ),
      NavigationDestination(
        icon: const Icon(Icons.store_outlined),
        selectedIcon: const Icon(Icons.store),
        label: loc.providersText,
      ),
      NavigationDestination(
        icon: _ProfileAvatar(user: appUser, selected: false),
        selectedIcon: _ProfileAvatar(user: appUser, selected: true),
        label: _profileLabel(appUser, loc),
      ),
    ];
  }

  String _profileLabel(AppUser? user, AppLocalizations loc) {
    final name =
        '${user?.personFirstName ?? ''} ${user?.personLastName ?? ''}'.trim();
    final isGuest = (user?.idAppUser ?? 0) == 0;
    return isGuest || name.isEmpty ? loc.profileText : name;
  }
}

// ==================== TAB CONSTANTS ====================

abstract class _Tab {
  static const int catalog = 0;
  static const int suppliers = 1;
  static const int profile = 2;
}

// ==================== PROFILE AVATAR ====================

class _ProfileAvatar extends StatelessWidget {
  final AppUser? user;
  final bool selected;

  const _ProfileAvatar({required this.user, required this.selected});

  static const double _size = 26;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isGuest = (user?.idAppUser ?? 0) == 0;

    // Resolve the raw URL at render time. `resolveImageUrl` handles
    // null, empty, placeholder strings, and relative paths — it
    // prefixes relative paths with `AppConstants.fsBaseUrl` and passes
    // absolute http(s) URLs through unchanged. Returns null when the
    // value can't be rendered.
    final resolvedUrl = isGuest ? null : resolveImageUrl(user?.appUserImageUrl);

    if (resolvedUrl == null) return _fallbackIcon(scheme);

    return SizedBox(
      width: _size,
      height: _size,
      child: ClipOval(
        child: Image.network(
          resolvedUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _fallbackIcon(scheme),
        ),
      ),
    );
  }

  Widget _fallbackIcon(ColorScheme scheme) {
    return Icon(
      selected ? Icons.account_circle : CupertinoIcons.profile_circled,
      size: _size,
      color: selected ? scheme.primary : scheme.onSurfaceVariant,
    );
  }
}
