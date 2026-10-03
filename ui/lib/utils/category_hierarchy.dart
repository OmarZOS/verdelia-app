import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// Structured, presentation-ready view of a category path.
///
/// The picker lays the three parts out at different weights:
///   - [leaf]      → the primary, large label
///   - [subdomain] → small caption above or below the leaf
///   - [domain]    → small caption, shown first
///
/// Any of the three may be empty when the source path doesn't carry
/// that segment (legacy rows, flat categories, etc.).
class LocalizedCategoryHierarchy {
  final String domain;
  final String subdomain;
  final String leaf;

  const LocalizedCategoryHierarchy({
    required this.domain,
    required this.subdomain,
    required this.leaf,
  });

  /// Small caption above the leaf: `domain › subdomain`.
  /// Empty when both parts are missing.
  String get caption {
    final parts = [domain, subdomain].where((p) => p.isNotEmpty);
    return parts.join('  ›  ');
  }

  /// Combined single-line form, useful for autocomplete, tooltips,
  /// chips, or anywhere that can't render two weights.
  String get fullLabel {
    final parts = [domain, subdomain, leaf].where((p) => p.isNotEmpty);
    return parts.join('  ›  ');
  }

  @override
  String toString() => fullLabel;
}

/// Build a presentation-ready hierarchy from a dotted category path.
///
/// [categoryPath] is the raw dotted key (`domain.subdomain.category`).
/// [localizedLeaf] is the leaf's localized display string — it takes
/// precedence over the raw trailing segment so the caller controls
/// how the leaf name is resolved.
LocalizedCategoryHierarchy localizedCategoryHierarchyParts({
  required String categoryPath,
  required String localizedLeaf,
  required AppLocalizations localizations,
}) {
  final segments = categoryPath
      .split('.')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();

  // Leaf: prefer the caller-provided localized name.
  final resolvedLeaf = localizedLeaf.isNotEmpty && !localizedLeaf.contains('.')
      ? localizedLeaf
      : (segments.isEmpty ? '' : _humanize(segments.last));

  // Not enough segments for a hierarchy — show the leaf alone.
  if (segments.length < 3) {
    return LocalizedCategoryHierarchy(
      domain: '',
      subdomain: '',
      leaf: resolvedLeaf,
    );
  }

  return LocalizedCategoryHierarchy(
    domain: localizedCategorySegment(localizations, segments[0]),
    subdomain: localizedCategorySegment(localizations, segments[1]),
    leaf: resolvedLeaf,
  );
}

/// Backwards-compatible single-string form.
///
/// Kept so existing callers that only render one line
/// (autocomplete rows, filter chips, breadcrumbs) don't break.
String localizedCategoryHierarchy({
  required String categoryPath,
  required String localizedLeaf,
  required AppLocalizations localizations,
}) {
  return localizedCategoryHierarchyParts(
    categoryPath: categoryPath,
    localizedLeaf: localizedLeaf,
    localizations: localizations,
  ).fullLabel;
}

String localizedCategorySegment(AppLocalizations localizations, String key) {
  final translations = <String, String>{
    'food': localizations.food,
    'health': localizations.health,
    'retail': localizations.retail,
    'trade': localizations.trade,
    'beauty': localizations.beauty,
    'home': localizations.home,
    'professional': localizations.professional,
    'education': localizations.education,
    'technology': localizations.technology,
    'logistics': localizations.logistics,
    'automotive': localizations.automotive,
    'agriculture': localizations.agriculture,
    'hospitality': localizations.hospitality,
    'finance': localizations.finance,
    'alimentary': localizations.alimentary,
    'beverages': localizations.beverages,
    'prepared': localizations.prepared,
    'dining': localizations.dining,
    'production': localizations.production,
    'specialty': localizations.specialty,
    'pharma': localizations.pharma,
    'services': localizations.services,
    'wellness': localizations.wellness,
    'medical_devices': localizations.medical_devices,
    'personal_care': localizations.personal_care,
    'facilities': localizations.facilities,
    'diagnostics': localizations.diagnostics,
    'primary_care': localizations.primary_care,
    'specialized_care': localizations.specialized_care,
    'dental': localizations.dental,
    'therapy': localizations.therapy,
    'clinical_procedures': localizations.clinical_procedures,
    'household': localizations.household,
    'electronics': localizations.electronics,
    'apparel': localizations.apparel,
    'pet_supplies': localizations.pet_supplies,
    'food_retail': localizations.food_retail,
    'fashion': localizations.fashion,
    'home_living': localizations.home_living,
    'lifestyle': localizations.lifestyle,
    'health_retail': localizations.health_retail,
    'distribution': localizations.distribution,
    'international': localizations.international,
    'intermediary': localizations.intermediary,
    'home_services': localizations.home_services,
    'health_services': localizations.health_services,
    'construction': localizations.construction,
    'hair': localizations.hair,
    'aesthetics': localizations.aesthetics,
    'nails': localizations.nails,
    'skincare': localizations.skincare,
    'repair': localizations.repair,
    'maintenance': localizations.maintenance,
    'moving': localizations.moving,
    'legal': localizations.legal,
    'accounting': localizations.accounting,
    'consulting': localizations.consulting,
    'institutions': localizations.institutions,
    'tutoring': localizations.tutoring,
    'training': localizations.training,
    'it_support': localizations.it_support,
    'development': localizations.development,
    'digital_marketing': localizations.digital_marketing,
    'warehousing': localizations.warehousing,
    'transport': localizations.transport,
    'storage': localizations.storage,
    'customs': localizations.customs,
    'parts': localizations.parts,
    'fluids': localizations.fluids,
    'sales': localizations.sales,
    'seeds': localizations.seeds,
    'fertilizers': localizations.fertilizers,
    'equipment': localizations.equipment,
    'supply': localizations.supply,
    'accommodation': localizations.accommodation,
    'events': localizations.events,
    'banking': localizations.banking,
  };
  return translations[key] ?? _humanize(key);
}

String _humanize(String key) => key
    .split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
