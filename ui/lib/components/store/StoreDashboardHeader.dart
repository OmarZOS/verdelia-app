// ui/lib/components/store/dashboard_header.dart

import 'package:flutter/material.dart';

/// A simple, non-collapsing header used at the top of dashboard screens.
///
/// Renders a leading icon, a title, an optional subtitle, an optional
/// trailing action row, and an optional search bar.
///
/// On narrow screens the subtitle is hidden so the title and actions
/// don't have to fight for the same row. The threshold is 360dp — below
/// that, header chrome (leading icon + actions + padding) can eat most
/// of the width, and a second line of text adds vertical noise without
/// being readable at that size.
class DashboardHeader extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? searchBar;
  final EdgeInsetsGeometry padding;

  /// Width below which the subtitle is hidden. Override this if a
  /// particular screen has unusually wide actions and needs a larger
  /// threshold.
  final double subtitleHideBreakpoint;

  const DashboardHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.subtitle,
    this.actions = const [],
    this.searchBar,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 8),
    this.subtitleHideBreakpoint = 360,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface,
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Below the breakpoint, drop the subtitle. The title stays
          // readable, the actions stay tappable, and the header stays
          // one line tall.
          final showSubtitle = subtitle != null &&
              constraints.maxWidth >= subtitleHideBreakpoint;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 22, color: cs.primary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                  ],
                ],
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (searchBar != null) ...[
                const SizedBox(height: 12),
                searchBar!,
              ],
            ],
          );
        },
      ),
    );
  }
}
