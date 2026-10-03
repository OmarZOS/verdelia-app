import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:ui/utils/category_hierarchy.dart';

// ══════════════════════════════════════════════════════════════════
// Public value types
// ══════════════════════════════════════════════════════════════════

class HierarchicalCategoryOption {
  final int id;
  final String path;
  final String leafLabel;

  const HierarchicalCategoryOption({
    required this.id,
    required this.path,
    required this.leafLabel,
  });
}

/// What the user picked. Always carries the domain, optionally a
/// subdomain, and optionally a leaf category id.
///
/// - Domain only       → `subdomain == null`, `leafId == 0`
/// - Domain + subdomain→ `subdomain != null`, `leafId == 0`
/// - Leaf category     → both `subdomain` and `leafId` are set
/// - "All"             → `domain == null`, `leafId == 0`
class CategorySelection {
  final String? domain;
  final String? subdomain;
  final int leafId;

  const CategorySelection({
    this.domain,
    this.subdomain,
    this.leafId = 0,
  });

  static const all = CategorySelection();

  bool get isAll => domain == null && leafId == 0;
  bool get isDomainOnly => domain != null && subdomain == null && leafId == 0;
  bool get isSubdomainOnly =>
      domain != null && subdomain != null && leafId == 0;
  bool get isLeaf => domain != null && leafId != 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySelection &&
          domain == other.domain &&
          subdomain == other.subdomain &&
          leafId == other.leafId;

  @override
  int get hashCode => Object.hash(domain, subdomain, leafId);

  @override
  String toString() =>
      'CategorySelection(domain: $domain, subdomain: $subdomain, '
      'leafId: $leafId)';
}

// ══════════════════════════════════════════════════════════════════
// Picker
// ══════════════════════════════════════════════════════════════════

class HierarchicalCategoryPicker extends StatelessWidget {
  final List<HierarchicalCategoryOption> options;

  /// The current leaf category id, or 0 for "no leaf".
  final int selectedId;

  /// The current domain filter, if any.
  final String? selectedDomain;

  /// The current subdomain filter, if any.
  final String? selectedSubdomain;

  /// Called whenever the user confirms a new selection. Carries the
  /// whole triple — domain, subdomain, leaf id.
  final ValueChanged<CategorySelection> onChanged;

  final String label;
  final String? iconAsset;
  final String? package;
  final bool showLabel;
  final bool allowAllOption;
  final String? allLabel;

  const HierarchicalCategoryPicker({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onChanged,
    required this.label,
    this.selectedDomain,
    this.selectedSubdomain,
    this.iconAsset,
    this.package,
    this.showLabel = true,
    this.allowAllOption = false,
    this.allLabel,
  });

  CategorySelection get _currentSelection => CategorySelection(
        domain: selectedDomain,
        subdomain: selectedSubdomain,
        leafId: selectedId,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final current = _currentSelection;
    final hasSelection = !current.isAll;

    final selectedLabel = _labelForSelection(current, l10n);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: options.isEmpty && !allowAllOption
            ? null
            : () => _showTreePicker(context),
        borderRadius: BorderRadius.circular(16),
        splashColor: colors.primary.withOpacity(0.08),
        highlightColor: colors.primary.withOpacity(0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSelection
                  ? colors.primary.withOpacity(0.35)
                  : colors.outlineVariant,
              width: hasSelection ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: iconAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          iconAsset!,
                          package: package,
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.category_outlined,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.account_tree_outlined,
                        color: colors.primary,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showLabel)
                      Text(
                        label.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.55),
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (showLabel) const SizedBox(height: 2),
                    Text(
                      hasSelection ? selectedLabel : l10n.categoryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasSelection
                            ? colors.onSurface
                            : colors.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: 20,
                color: colors.onSurface.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Sheet
  // ══════════════════════════════════════════════════════════════

  Future<void> _showTreePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tree = _buildTree();

    var selection = _currentSelection;
    // Expansion state needs to survive the setModalState rebuilds.
    final expandedDomains = <String>{
      if (selection.domain != null) selection.domain!,
    };
    final expandedSubdomains = <String>{
      if (selection.domain != null && selection.subdomain != null)
        '${selection.domain}.${selection.subdomain}',
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void pick(CategorySelection next) {
            setModalState(() {
              selection = next;
              if (next.domain != null) {
                expandedDomains.add(next.domain!);
              }
              if (next.domain != null && next.subdomain != null) {
                expandedSubdomains.add('${next.domain}.${next.subdomain}');
              }
            });
          }

          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.82,
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.categoryText,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: colors.outlineVariant.withOpacity(0.6),
                ),

                // Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (allowAllOption)
                        _AllOption(
                          label: allLabel ?? l10n.allText,
                          selected: selection.isAll,
                          onTap: () => pick(CategorySelection.all),
                        ),
                      ...tree.entries.map((domainEntry) {
                        final domain = domainEntry.key;
                        return _DomainTile(
                          key: PageStorageKey<String>('domain:$domain'),
                          domain: domain,
                          subdomains: domainEntry.value,
                          selection: selection,
                          initiallyExpanded: expandedDomains.contains(domain),
                          onExpansionChanged: (open) {
                            if (open) {
                              expandedDomains.add(domain);
                            } else {
                              expandedDomains.remove(domain);
                            }
                          },
                          onSelectDomain: () => pick(
                            CategorySelection(domain: domain),
                          ),
                          onSelectSubdomain: (subdomain) => pick(
                            CategorySelection(
                              domain: domain,
                              subdomain: subdomain,
                            ),
                          ),
                          onSelectLeaf: (subdomain, leafId) => pick(
                            CategorySelection(
                              domain: domain,
                              subdomain: subdomain,
                              leafId: leafId,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.outlineVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: !allowAllOption && selection.isAll
                          ? null
                          : () {
                              onChanged(selection);
                              Navigator.pop(sheetContext);
                            },
                      child: Text(l10n.confirm),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════

  String _labelForSelection(CategorySelection sel, AppLocalizations l10n) {
    if (sel.isAll) return allLabel ?? l10n.allText;

    final parts = <String>[];
    if (sel.domain != null) {
      parts.add(localizedCategorySegment(l10n, sel.domain!));
    }
    if (sel.subdomain != null) {
      parts.add(localizedCategorySegment(l10n, sel.subdomain!));
    }

    if (sel.leafId != 0) {
      final leaf = options.cast<HierarchicalCategoryOption?>().firstWhere(
            (o) => o?.id == sel.leafId,
            orElse: () => null,
          );
      if (leaf != null) parts.add(leaf.leafLabel);
    }

    return parts.join(' · ');
  }

  Map<String, Map<String, List<HierarchicalCategoryOption>>> _buildTree() {
    final tree = <String, Map<String, List<HierarchicalCategoryOption>>>{};
    for (final option in options) {
      final segments = option.path
          .split('.')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final domain = segments.length >= 2 ? segments[0] : 'other';
      final subdomain = segments.length >= 3 ? segments[1] : 'other';
      (tree[domain] ??= <String, List<HierarchicalCategoryOption>>{})
          .putIfAbsent(subdomain, () => <HierarchicalCategoryOption>[])
          .add(option);
    }
    return tree;
  }
}

// ══════════════════════════════════════════════════════════════════
// Inner widgets
// ══════════════════════════════════════════════════════════════════

class _AllOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AllOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _TappableRow(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          _RadioDot(selected: selected),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? colors.primary : colors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Domain tile. Two tap targets inside:
///  - the "select this domain" radio on the left
///  - the expansion chevron for drilling into subdomains
class _DomainTile extends StatelessWidget {
  final String domain;
  final Map<String, List<HierarchicalCategoryOption>> subdomains;
  final CategorySelection selection;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onSelectDomain;
  final ValueChanged<String> onSelectSubdomain;
  final void Function(String subdomain, int leafId) onSelectLeaf;

  const _DomainTile({
    super.key,
    required this.domain,
    required this.subdomains,
    required this.selection,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onSelectDomain,
    required this.onSelectSubdomain,
    required this.onSelectLeaf,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final totalLeaves = subdomains.values.expand((e) => e).length;
    final isSelected = selection.domain == domain &&
        selection.subdomain == null &&
        selection.leafId == 0;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          iconColor: colors.primary,
          collapsedIconColor: colors.onSurface.withOpacity(0.55),
          leading: _RadioDot(
            selected: isSelected,
            onTap: onSelectDomain,
          ),
          title: InkWell(
            onTap: onSelectDomain,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizedCategorySegment(l10n, domain),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '$totalLeaves ${l10n.itemsText.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.55),
                        ),
                  ),
                ],
              ),
            ),
          ),
          children: subdomains.entries.map((subEntry) {
            final subdomain = subEntry.key;
            final options = subEntry.value;
            final isSubSelected = selection.domain == domain &&
                selection.subdomain == subdomain &&
                selection.leafId == 0;

            return _SubdomainTile(
              key: PageStorageKey<String>('subdomain:$domain.$subdomain'),
              title: localizedCategorySegment(l10n, subdomain),
              options: options,
              leafSelectedId: selection.leafId,
              subdomainSelected: isSubSelected,
              onSelectSubdomain: () => onSelectSubdomain(subdomain),
              onSelectLeaf: (id) => onSelectLeaf(subdomain, id),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SubdomainTile extends StatefulWidget {
  final String title;
  final List<HierarchicalCategoryOption> options;
  final int leafSelectedId;
  final bool subdomainSelected;
  final VoidCallback onSelectSubdomain;
  final ValueChanged<int> onSelectLeaf;

  const _SubdomainTile({
    super.key,
    required this.title,
    required this.options,
    required this.leafSelectedId,
    required this.subdomainSelected,
    required this.onSelectSubdomain,
    required this.onSelectLeaf,
  });

  @override
  State<_SubdomainTile> createState() => _SubdomainTileState();
}

class _SubdomainTileState extends State<_SubdomainTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.subdomainSelected ||
        widget.options.any((o) => o.id == widget.leafSelectedId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => _expanded = v,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
        leading: _RadioDot(
          selected: widget.subdomainSelected,
          onTap: widget.onSelectSubdomain,
        ),
        title: InkWell(
          onTap: widget.onSelectSubdomain,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withOpacity(0.85),
                  ),
            ),
          ),
        ),
        children: widget.options.map((option) {
          final selected = option.id == widget.leafSelectedId;
          return _TappableRow(
            selected: selected,
            onTap: () => widget.onSelectLeaf(option.id),
            child: Row(
              children: [
                _RadioDot(selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.leafLabel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? colors.primary
                              : colors.onSurface.withOpacity(0.9),
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TappableRow extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _TappableRow({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected ? colors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;

  const _RadioDot({required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dot = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? colors.primary : colors.onSurface.withOpacity(0.35),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );

    if (onTap == null) return dot;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: dot,
      ),
    );
  }
}
