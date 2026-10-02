import 'package:flutter/material.dart';
import 'package:verdelia_core/business/iProduct.dart';

class IProductHeroImage extends StatelessWidget {
  final IProduct iproduct;

  const IProductHeroImage({super.key, required this.iproduct});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: colorScheme.primary.withOpacity(0.05)),
        if (iproduct.iproductImageUrl != null &&
            iproduct.iproductImageUrl!.isNotEmpty)
          _buildNetworkImage(context),
        _buildGradientOverlay(colorScheme),
      ],
    );
  }

  Widget _buildNetworkImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Image.network(
      iproduct.iproductImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: colorScheme.surface,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colorScheme.surface.withOpacity(0.3),
            colorScheme.surface.withOpacity(0.8),
            colorScheme.surface,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ),
      ),
    );
  }
}
