import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:event/product_change_notifier.dart';
import 'package:provider/provider.dart';

// We need satefull widget for our categories

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  // List<String> categories = ["Hand bag", "Jewellery", "Footwear", "Dresses"];
  // By default our first item will be selected
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductNotifier>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductNotifier>().productCategories;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppConstants.kDefaultPaddin),
      child: SizedBox(
        height: 25,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) => buildCategory(index),
        ),
      ),
    );
  }

  Widget buildCategory(int index) {
    final categories = context.watch<ProductNotifier>().productCategories;
    if (index >= categories.length) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.kDefaultPaddin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              categories[index].nameFor(
                Localizations.localeOf(context).languageCode,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedIndex == index
                    ? AppConstants.kTextColor
                    : AppConstants.kTextLightColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(
                  top: AppConstants.kDefaultPaddin / 4), //top padding 5
              height: 2,
              width: 30,
              color: selectedIndex == index ? Colors.black : Colors.transparent,
            )
          ],
        ),
      ),
    );
  }
}
