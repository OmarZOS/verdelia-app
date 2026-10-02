import 'package:flutter/material.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'package:provider_personnel/components/privilege_dialog/privilege_category_section.dart';
import 'package:provider_personnel/components/privilege_ui.dart';

class PrivilegeDialogContent extends StatelessWidget {
  final AppUser user;
  final Map<String, bool> selectedPrivileges;
  final Function(String, bool) onPrivilegeChanged;

  const PrivilegeDialogContent({
    super.key,
    required this.user,
    required this.selectedPrivileges,
    required this.onPrivilegeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = _getCategories();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryPrivileges = PrivilegeManager.allPrivileges
              .where((p) => p.category == category)
              .toList();

          return PrivilegeCategorySection(
            category: category,
            privileges: categoryPrivileges,
            user: user,
            selectedPrivileges: selectedPrivileges,
            onPrivilegeChanged: onPrivilegeChanged,
            isFirst: index == 0,
          );
        },
      ),
    );
  }

  List<String> _getCategories() {
    return PrivilegeManager.allPrivileges
        .map((p) => p.category)
        .toSet()
        .toList();
  }
}
