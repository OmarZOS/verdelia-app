import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text(AppLocalizations.of(context)!.aboutAppTab),
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                                const Color.fromARGB(255, 100, 110, 105),
                                AppConstants.backgroundDarkColor
                              ] // Darker green shades
                            : [
                                AppConstants.backgroundColor,
                                const Color.fromARGB(255, 143, 197, 166)
                              ], // Your main color + slightly darker
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        package: "tabbed_home",
                        height: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                pinned: true,
                // bottom: TabBar(
                //   controller: _tabController,
                //   tabs: [
                //     Tab(text: AppLocalizations.of(context)!.aboutAppTab),
                //     // Tab(text: AppLocalizations.of(context)!.illnessInfoTab),
                //     Tab(text: AppLocalizations.of(context)!.aboutAppTab),
                //   ],
                //   indicatorColor: Colors.white,
                //   labelStyle: const TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ),
            ];
          },
          body: _buildAppInfoTab(context)),
    );
  }

  Widget _buildAppInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(AppLocalizations.of(context)!.appPurposeTitle),
          _buildSectionText(AppLocalizations.of(context)!.appPurposeContent),
          const SizedBox(height: 24),
          _buildSectionHeader(AppLocalizations.of(context)!.featuresTitle),
          _buildFeatureTile(
              Icons.store, AppLocalizations.of(context)!.feature1),
          _buildFeatureTile(
              Icons.gamepad, AppLocalizations.of(context)!.feature2),
          _buildFeatureTile(
              Icons.menu_book_outlined, AppLocalizations.of(context)!.feature3),
          _buildFeatureTile(
              Icons.location_on, AppLocalizations.of(context)!.feature4),
          const SizedBox(height: 24),
          _buildSectionHeader(AppLocalizations.of(context)!.contactUsTitle),
          _buildContactOption(
              Icons.email, AppLocalizations.of(context)!.contactEmail),
          _buildContactOption(
              Icons.phone, AppLocalizations.of(context)!.contactPhone),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
