import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:verdelia_core/app/AppUser.dart';

class CategoryPicker extends StatefulWidget {
  final ValueChanged<int> onCategoryChanged;
  final List<AppUserCategory> categories;
  final int category_id;

  const CategoryPicker({
    super.key,
    required this.onCategoryChanged,
    required this.categories,
    required this.category_id,
  });

  @override
  _CategoryPickerState createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    _selectedCategoryIndex = widget.categories
        .indexWhere((category) => category.idAppUserType == widget.category_id);
    widget.onCategoryChanged(
      widget.categories[_selectedCategoryIndex].idAppUserType,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          // tileColor: Colors.blue[50],
          title: Text(
            widget.categories[_selectedCategoryIndex].appUserTypeDesc,
          ),
          onTap: () {
            _showPicker(context);
          },
          // trailing: getAppUsercategoryIcon(
          //   widget.categories[_selectedCategoryIndex].recipe_provider_type_id,
          // ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          child: CupertinoPicker(
            itemExtent: 32.0,
            onSelectedItemChanged: (int index) {
              if (mounted) {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              }
              // //log('${widget.categories[index].recipe_provider_type_id}');

              widget.onCategoryChanged(
                widget.categories[index].idAppUserType,
              );
            },
            children: widget.categories.map((AppUserCategory category) {
              return Center(child: Text(category.appUserTypeDesc));
            }).toList(),
          ),
        );
      },
    );
  }
}
