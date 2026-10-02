import 'package:event/user_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Organisation.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:ui/components/organisation_management_popup.dart';
import 'package:provider/provider.dart';

class OrganisationPicker extends StatefulWidget {
  final ValueChanged<Organisation>? onOrganisationSelected;
  final int? initialValue;
  final String hintText;
  final bool showLabel;

  const OrganisationPicker({
    super.key,
    this.onOrganisationSelected,
    this.initialValue,
    required this.hintText,
    this.showLabel = true,
  });

  @override
  _OrganisationPickerState createState() => _OrganisationPickerState();
}

class _OrganisationPickerState extends State<OrganisationPicker> {
  int? selectedOrganisationId;
  String? newOrganisationName;

  final TextEditingController _searchController = TextEditingController();
  List<Organisation> filteredOrganisations = [];
  bool showCreateOption = false;
  bool _isLoading = false;

  late List<Organisation> organisations;
  late SupplierChangeNotifier notifier;

  @override
  void initState() {
    super.initState();
    _initData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initData() async {
    notifier = Provider.of<SupplierChangeNotifier>(context, listen: false);

    setState(() => _isLoading = true);

    // Load organisations if empty
    if (notifier.organisations.isEmpty) {
      await notifier.fetchOrganisations(reset: true);
    }

    organisations = List.from(notifier.organisations);
    selectedOrganisationId = widget.initialValue;
    filteredOrganisations = List.from(organisations);

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredOrganisations = List.from(organisations);
        showCreateOption = false;
      } else {
        filteredOrganisations = organisations
            .where((org) =>
                org.provider_organisation_name.toLowerCase().contains(query))
            .toList();

        showCreateOption = query.isNotEmpty &&
            !organisations.any((org) =>
                org.provider_organisation_name.toLowerCase() ==
                query.toLowerCase());
      }
    });
  }

  void _openOrganisationPicker() async {
    HapticFeedback.lightImpact();

    _searchController.clear();
    setState(() {
      filteredOrganisations = List.from(organisations);
      showCreateOption = false;
    });

    final result = await showModalBottomSheet<Organisation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheet();
      },
    );

    if (result != null) {
      setState(() {
        selectedOrganisationId = result.id_provider_organisation;
        newOrganisationName = result.provider_organisation_name;
      });
      widget.onOrganisationSelected?.call(result);
    }
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with management button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectOrganisation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings, size: 22),
                      tooltip: 'Manage Organisations',
                      onPressed: () async {
                        // Close current bottom sheet
                        Navigator.pop(context);
                        // Open management popup
                        await showDialog(
                          context: context,
                          builder: (context) => OrganisationManagementPopup(
                            onOrganisationUpdated: (updatedOrg) {
                              _refreshOrganisations();
                            },
                          ),
                        );
                        // Reopen the picker after management
                        _openOrganisationPicker();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search organisations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // Organisation list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredOrganisations.isEmpty && !showCreateOption
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No organisations found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filteredOrganisations.length +
                                (showCreateOption ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (showCreateOption &&
                                  index == filteredOrganisations.length) {
                                return _buildCreateOption();
                              }
                              final org = filteredOrganisations[index];
                              return _buildOrganisationTile(org);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrganisationTile(Organisation org) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Text(
          org.provider_organisation_name[0].toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(org.provider_organisation_name),
      subtitle: org.provider_organisation_desc.isNotEmpty
          ? Text(
              org.provider_organisation_desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: selectedOrganisationId == org.id_provider_organisation
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, org),
    );
  }

  Widget _buildCreateOption() {
    final query = _searchController.text.trim();
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.orange),
      ),
      title: Text(
        'Create "$query"',
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: const Text('Create a new organisation with this name'),
      onTap: () async {
        // Close the bottom sheet first
        Navigator.pop(context);

        // Create new organisation
        final newOrg = Organisation(
          id_provider_organisation: 0,
          provider_organisation_name: query,
          provider_organisation_desc: '',
        );

        final created = await notifier.createOrganisation(newOrg,
            Provider.of<AppUserNotifier>(context, listen: false).token ?? "");

        if (created != null && mounted) {
          // Refresh the list
          await _refreshOrganisations();

          // Select the newly created organisation
          setState(() {
            selectedOrganisationId = created.id_provider_organisation;
            newOrganisationName = created.provider_organisation_name;
          });
          widget.onOrganisationSelected?.call(created);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Organisation created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _refreshOrganisations() async {
    await notifier.fetchOrganisations(reset: true);
    if (mounted) {
      setState(() {
        organisations = List.from(notifier.organisations);
        filteredOrganisations = List.from(organisations);
      });
    }
  }

  Color _getOrganizationColor() {
    return Theme.of(context).primaryColor;
  }

  Organisation? _getSelectedOrganisation() {
    if (selectedOrganisationId != null && selectedOrganisationId != 0) {
      try {
        return organisations.firstWhere(
          (org) => org.id_provider_organisation == selectedOrganisationId,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedOrg = _getSelectedOrganisation();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.hintText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ),
        GestureDetector(
          onTap: _isLoading ? null : _openOrganisationPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedOrg != null
                    ? _getOrganizationColor().withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      selectedOrg != null
                          ? Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  selectedOrg.provider_organisation_name[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.business_outlined,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hintText,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              selectedOrg != null
                                  ? selectedOrg.provider_organisation_name
                                  : (newOrganisationName ??
                                      'Select an organisation'),
                              style: TextStyle(
                                color: selectedOrg != null
                                    ? Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                    : (newOrganisationName != null
                                        ? Colors.orange
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6)),
                                fontWeight: selectedOrg != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
