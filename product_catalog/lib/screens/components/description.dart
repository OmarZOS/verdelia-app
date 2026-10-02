import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Product.dart';

class Description extends StatelessWidget {
  const Description({super.key, required this.product});

  final Product product;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppConstants.kDefaultPaddin),
      child: Text(
        product.product_description ?? "",
        style: const TextStyle(height: 1.5),
      ),
    );
  }
}
