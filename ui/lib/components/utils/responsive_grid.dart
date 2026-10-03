// lib/ui/utils/responsive_grid.dart

import 'package:flutter/material.dart';

/// Build a fixed-column grid delegate sized so tiles stay within a
/// sensible width band at any screen size.
///
/// Column count is derived from the widest acceptable tile:
/// `usableWidth / (maxTileWidth + spacing)`, rounded up so the last
/// column isn't chopped. Clamped to 1..6 so extremes (folded phones,
/// ultra-wide desktops) don't produce absurd counts.
///
/// The tile's vertical budget is composed of:
///   * image header — scales with tile width, bounded
///   * info block   — fixed content height
///   * controls bar — included so a carted tile never overflows
///   * padding      — insets around the card
///
/// Aspect ratio is `tileWidth / tileHeight`, so a single-column phone
/// tile is a squat banner and a six-column desktop tile is a compact
/// card.
SliverGridDelegate responsiveGridDelegate({
  required double availableWidth,
  double maxTileWidth = 220,
  double spacing = 12,
  double padding = 12,
}) {
  final usable = availableWidth - (padding * 2);
  final columns = (usable / (maxTileWidth + spacing)).ceil().clamp(1, 6);
  final tileWidth = (usable - (spacing * (columns - 1))) / columns;

  // Image header scales with width but is bounded.
  final imageHeight = (tileWidth * 0.45).clamp(64.0, 120.0);

  // Fixed content below the image:
  //   info block    — title (up to 2 lines) + price + stock
  //   controls bar  — quantity bar + insets when the item is carted
  //   card padding  — insets around the card content
  const infoHeight = 80.0;
  const controlsTotal = 52.0;
  const paddingTotal = 24.0;

  final tileHeight = imageHeight + infoHeight + controlsTotal + paddingTotal;

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
    childAspectRatio: tileWidth / tileHeight,
  );
}
