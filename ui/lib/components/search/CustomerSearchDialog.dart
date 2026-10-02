import 'dart:async';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Person.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:ui/components/search/new_customer_dialog.dart';
import 'package:provider/provider.dart';

class CustomerSearchDialog extends StatefulWidget {
  final ValueChanged<AppUser?> onCustomerSelected;
  final ValueChanged<Person>? onPersonSelected;
  final int? supplierId;
  final AppUser? currentSelectedCustomer;
  final bool showPersonsAsUsers;

  const CustomerSearchDialog({
    Key? key,
    required this.onCustomerSelected,
    this.onPersonSelected,
    this.supplierId,
    this.currentSelectedCustomer,
    this.showPersonsAsUsers = true,
  }) : super(key: key);

  @override
  State<CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<CustomerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  late PersonnelNotifier _personnelNotifier;
  late AppUserNotifier _userNotifier;
  bool _isInitialLoadComplete = false;
  String _selectedTab = 'users'; // 'users' or 'persons'
  bool _hasSearchQuery = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _personnelNotifier = context.read<PersonnelNotifier>();
    _userNotifier = context.read<AppUserNotifier>();

    if (!_isInitialLoadComplete) {
      _isInitialLoadComplete = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
    }
  }

  void _loadInitialData() {
    _personnelNotifier.loadPersonnel(
      supplierId: widget.supplierId ?? 0,
      reset: true,
      includePending: true,
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _hasSearchQuery = query.isNotEmpty;

    _debounceTimer?.cancel();

    if (query.isEmpty) {
      _personnelNotifier.clearSearch(supplierId: widget.supplierId ?? 0);
      setState(() {});
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (query.length >= 2) {
        final userId = _userNotifier.appUser?.idAppUser ?? 0;
        _personnelNotifier.searchPersonnel(
          query,
          // userId,
          supplierId: widget.supplierId ?? 0,
        );
      }
      setState(() {});
    });
  }

  // In _CustomerSearchDialogState class
  void _selectAppUser(AppUser customer) {
    // If showPersonsAsUsers is true, we should convert person to AppUser
    if (widget.showPersonsAsUsers) {
      widget.onCustomerSelected(customer);
    } else {
      // Call both callbacks if available
      widget.onCustomerSelected(customer);
      // widget.onPersonSelected?.call(null); // Clear person selection
    }
    Navigator.pop(context);
  }

  void _selectPerson(Person person) {
    if (widget.showPersonsAsUsers) {
      // Convert Person to AppUser for backward compatibility
      // final appUser = _convertPersonToAppUser(person);
      // widget.onCustomerSelected(appUser);
      widget.onPersonSelected?.call(person); // Person is converted to AppUser
    } else {
      // Call the person callback directly
      widget.onCustomerSelected(null); // Clear AppUser selection
      widget.onPersonSelected?.call(person);
    }
    Navigator.pop(context);
  }

  // AppUser _convertPersonToAppUser(Person person) {
  //   return AppUser(
  //     id_app_user: person.id_person,
  //     appUserName:
  //         person.person_details.person_email ?? 'person_${person.id_person}',
  //     appUserImageUrl: null,
  //     personFirstName: person.person_details.person_first_name,
  //     personLastName: person.person_details.person_last_name,
  //     // personEmail: person.person_details.person_email,
  //     // personPhone: person.person_details.person_phone,
  //     personGender: person.person_details.person_gender,
  //     personNationality: person.person_details.person_nationality,
  //     personBirthDate: person.person_details.person_birth_date,
  //     app_user_type_desc: 'Customer',
  //     // is_person: true,
  //     // personId: person.id_person,
  //   );
  // }

  void _clearSelection() {
    widget.onCustomerSelected(null);
    Navigator.pop(context);
  }

  Future<void> _createNewCustomer() async {
    final result = await showDialog<Person?>(
      context: context,
      builder: (context) => NewCustomerDialog(
        onCustomerCreated: (Person p) {
          widget.onCustomerSelected(null);
          widget.onPersonSelected!(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 600,
          minHeight: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(loc),
            _buildSearchBar(loc),
            if (_hasSearchQuery) _buildTabBar(),
            Expanded(
              child: Consumer<PersonnelNotifier>(
                builder: (context, notifier, child) {
                  return _buildContent(notifier, loc);
                },
              ),
            ),
            _buildFooter(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.customer,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.selectCustomerForOrder,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc) {
    return Consumer<PersonnelNotifier>(
      builder: (context, notifier, child) {
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: loc.searchCustomers,
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _personnelNotifier.clearSearch(
                                  supplierId: widget.supplierId ?? 0,
                                );
                                setState(() {
                                  _hasSearchQuery = false;
                                });
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (notifier.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                label: 'Users',
                isActive: _selectedTab == 'users',
                onTap: () => setState(() => _selectedTab = 'users'),
              ),
            ),
            Expanded(
              child: _buildTabButton(
                label: 'Persons',
                isActive: _selectedTab == 'persons',
                onTap: () => setState(() => _selectedTab = 'persons'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PersonnelNotifier notifier, AppLocalizations loc) {
    if (notifier.isLoading && !_hasSearchQuery) {
      return _buildLoadingState(loc);
    }

    if (!_hasSearchQuery) {
      if (_selectedTab == 'users') {
        return _buildInitialUserState(loc, notifier);
      } else {
        return _buildInitialPersonState(loc);
      }
    }

    if (_selectedTab == 'users') {
      return _buildUserResults(notifier, loc);
    } else {
      return _buildPersonResults(notifier, loc);
    }
  }

  Widget _buildInitialUserState(
      AppLocalizations loc, PersonnelNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentUsers = notifier.searchResults.take(5).toList();

    if (recentUsers.isEmpty) {
      return _buildEmptyInitialState(loc);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.recentCustomers,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${recentUsers.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: recentUsers.length,
            itemBuilder: (context, index) {
              final user = recentUsers[index];
              final isSelected =
                  widget.currentSelectedCustomer?.idAppUser == user.idAppUser;
              return _buildCustomerTile(user, isSelected, isPerson: false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInitialPersonState(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.people_alt_outlined,
          size: 80,
          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          loc.searchForPersons,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.enterNameToFindPersons,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyInitialState(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.group_outlined,
          size: 80,
          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          loc.noCustomersYet,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loc.startByAddingCustomers,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          loc.searching,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildUserResults(PersonnelNotifier notifier, AppLocalizations loc) {
    final searchResults = notifier.searchResults;

    if (searchResults.isEmpty) {
      return _buildEmptySearchState(loc, isPerson: false);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.users}: ${searchResults.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'User Accounts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final user = searchResults[index];
              final isSelected =
                  widget.currentSelectedCustomer?.idAppUser == user.idAppUser;
              return _buildCustomerTile(user, isSelected, isPerson: false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonResults(PersonnelNotifier notifier, AppLocalizations loc) {
    final personResults = notifier.personSearchResults;

    if (personResults.isEmpty) {
      return _buildEmptySearchState(loc, isPerson: true);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.persons}: ${personResults.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Persons',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: personResults.length,
            itemBuilder: (context, index) {
              final person = personResults[index];
              return _buildPersonTile(person);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState(AppLocalizations loc,
      {required bool isPerson}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isPerson ? Icons.person_search : Icons.search_off,
          size: 80,
          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          isPerson ? loc.noPersonsFound : loc.noCustomersFound,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPerson ? loc.tryDifferentName : loc.tryDifferentSearchText,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerTile(AppUser customer, bool isSelected,
      {required bool isPerson}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAppUser(customer),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.1)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.3)
                    : (isPerson
                        ? Colors.orange.withOpacity(0.2)
                        : colorScheme.outline.withOpacity(0.1)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildCustomerAvatar(customer, isSelected, isPerson: isPerson),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${customer.personFirstName} ${customer.personLastName}'
                                  .trim(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPerson)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 10,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Person',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (customer.appUserName != null &&
                          customer.appUserName!.isNotEmpty &&
                          !isPerson)
                        Row(
                          children: [
                            Icon(
                              Icons.alternate_email_rounded,
                              size: 12,
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.8)
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '@${customer.appUserName!}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary.withOpacity(0.8)
                                    : colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      // if (customer.personEmail != null &&
                      //     customer.personEmail!.isNotEmpty)
                      //   Row(
                      //     children: [
                      //       Icon(
                      //         Icons.email,
                      //         size: 12,
                      //         color: isSelected
                      //             ? colorScheme.primary.withOpacity(0.6)
                      //             : colorScheme.onSurfaceVariant
                      //                 .withOpacity(0.7),
                      //       ),
                      //       const SizedBox(width: 4),
                      //       Text(
                      //         customer.personEmail!,
                      //         style: textTheme.bodySmall?.copyWith(
                      //           color: isSelected
                      //               ? colorScheme.primary.withOpacity(0.6)
                      //               : colorScheme.onSurfaceVariant
                      //                   .withOpacity(0.7),
                      //         ),
                      //         maxLines: 1,
                      //         overflow: TextOverflow.ellipsis,
                      //       ),
                      //     ],
                      //   ),
                      // if (customer.personPhone != null &&
                      //     customer.personPhone!.isNotEmpty)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 2),
                      //     child: Row(
                      //       children: [
                      //         Icon(
                      //           Icons.phone,
                      //           size: 12,
                      //           color: isSelected
                      //               ? colorScheme.primary.withOpacity(0.6)
                      //               : colorScheme.onSurfaceVariant
                      //                   .withOpacity(0.7),
                      //         ),
                      //         const SizedBox(width: 4),
                      //         Text(
                      //           customer.personPhone!,
                      //           style: textTheme.bodySmall?.copyWith(
                      //             color: isSelected
                      //                 ? colorScheme.primary.withOpacity(0.6)
                      //                 : colorScheme.onSurfaceVariant
                      //                     .withOpacity(0.7),
                      //           ),
                      //           maxLines: 1,
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                    ],
                  ),
                ),
                _buildSelectButton(isSelected, isPerson: isPerson),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonTile(Person person) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final details = person.person_details;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPerson(person),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildPersonAvatar(person),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.fullName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Person',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (details.person_gender.isNotEmpty ||
                          details.person_nationality != "")
                        Row(
                          children: [
                            if (details.person_gender.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    details.person_gender.toLowerCase() ==
                                            'male'
                                        ? Icons.male
                                        : details.person_gender.toLowerCase() ==
                                                'female'
                                            ? Icons.female
                                            : Icons.transgender,
                                    size: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    details.person_gender,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            if (details.person_gender.isNotEmpty &&
                                details.person_nationality != "")
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (details.person_nationality != "")
                              Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    details.person_nationality ?? "",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      if (details.person_phone != null &&
                          details.person_phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                details.person_phone!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (details.person_email != null &&
                          details.person_email!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                details.person_email!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (person.age != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cake,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${person.age} years',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (person.formattedBirthDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '(${person.formattedBirthDate!})',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildSelectButton(false, isPerson: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerAvatar(AppUser customer, bool isSelected,
      {required bool isPerson}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isSelected
                ? colorScheme.primary.withOpacity(0.1)
                : (isPerson
                    ? Colors.orange.withOpacity(0.1)
                    : colorScheme.surfaceVariant),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.3)
                  : (isPerson
                      ? Colors.orange.withOpacity(0.3)
                      : colorScheme.outline.withOpacity(0.2)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: customer.appUserImageUrl != null &&
                    customer.appUserImageUrl!.isNotEmpty
                ? Image.network(
                    customer.appUserImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackAvatar(customer, isSelected,
                          isPerson: isPerson);
                    },
                  )
                : _buildFallbackAvatar(customer, isSelected,
                    isPerson: isPerson),
          ),
        ),
        if (isPerson)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        if (isSelected && !isPerson)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 12,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonAvatar(Person person) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      Colors.orange,
      Colors.deepOrange,
      Colors.amber,
      Colors.orangeAccent,
      Colors.deepOrangeAccent,
    ];
    final color = colors[person.id_person % colors.length];
    final initials = person.initials;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.orange.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(AppUser customer, bool isSelected,
      {required bool isPerson}) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final color =
        isPerson ? Colors.orange : colors[customer.idAppUser! % colors.length];
    final initials = _getCustomerInitials(customer);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isSelected ? 0.3 : 0.15),
            color.withOpacity(isSelected ? 0.5 : 0.3),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectButton(bool isSelected, {bool isPerson = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPerson
            ? Colors.orange.withOpacity(0.1)
            : (isSelected ? colorScheme.primary : colorScheme.surfaceVariant),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPerson
              ? Colors.orange.withOpacity(0.2)
              : (isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.2)),
          width: 1,
        ),
      ),
      child: Icon(
        isPerson
            ? Icons.person_add
            : (isSelected ? Icons.check : Icons.arrow_forward_ios_rounded),
        size: 20,
        color: isPerson
            ? Colors.orange
            : (isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (widget.currentSelectedCustomer != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearSelection,
                  icon: Icon(
                    Icons.person_remove,
                    color: colorScheme.error,
                  ),
                  label: Text(
                    loc.clearSelection,
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            if (widget.currentSelectedCustomer != null)
              const SizedBox(width: 12),
            Expanded(
              flex: widget.currentSelectedCustomer != null ? 1 : 2,
              child: ElevatedButton.icon(
                onPressed: _createNewCustomer,
                icon: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  loc.addNewCustomer,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCustomerInitials(AppUser customer) {
    final firstName = customer.personFirstName?.trim() ?? '';
    final lastName = customer.personLastName?.trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return '?';
    }

    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
