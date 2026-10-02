class NamingContribution {
  final int? id;
  final String en;
  final String? ar;
  final String? fr;

  /// PENDING | ACCEPTED | APP_TRANSLATED | REJECTED
  final String? status;

  /// product | provider | ingredient | recipe | service | symptom | role
  final String? type;

  final String? iconUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NamingContribution({
    required this.id,
    required this.en,
    this.ar,
    this.fr,
    this.status,
    this.type,
    this.iconUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory NamingContribution.empty() =>
      const NamingContribution(id: null, en: '');

  factory NamingContribution.fromJson(dynamic json) {
    if (json is! Map) return NamingContribution.empty();
    final map = Map<String, dynamic>.from(json);

    String? str(String key) {
      final v = map[key];
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    int? i(String key) {
      final v = map[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    DateTime? d(String key) {
      final v = map[key];
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return NamingContribution(
      id: i('id_naming_contribution'),
      en: str('naming_contribution_en') ?? '',
      ar: str('naming_contribution_ar'),
      fr: str('naming_contribution_fr'),
      status: str('naming_contribution_status'),
      type: str('naming_contribution_type'),
      iconUrl: str('naming_contribution_icon_url'),
      createdAt: d('naming_contribution_created_at'),
      updatedAt: d('naming_contribution_updated_at'),
    );
  }

  /// Return the name in [lang], falling back to English, then to the
  /// first non-empty of Arabic / French. Returns an empty string when
  /// the contribution carries no name at all.
  String nameFor(String lang) {
    switch (lang) {
      case 'ar':
        if (ar != null && ar!.isNotEmpty) return ar!;
        break;
      case 'fr':
        if (fr != null && fr!.isNotEmpty) return fr!;
        break;
      case 'en':
      default:
        break;
    }
    if (en.isNotEmpty) return en;
    if (ar != null && ar!.isNotEmpty) return ar!;
    if (fr != null && fr!.isNotEmpty) return fr!;
    return '';
  }

  bool get hasTranslations =>
      (ar != null && ar!.isNotEmpty) || (fr != null && fr!.isNotEmpty);

  Map<String, dynamic> toJson() => {
        if (id != null) 'id_naming_contribution': id,
        'naming_contribution_en': en,
        'naming_contribution_ar': ar,
        'naming_contribution_fr': fr,
        'naming_contribution_status': status,
        'naming_contribution_type': type,
        'naming_contribution_icon_url': iconUrl,
      };

  @override
  String toString() => 'NamingContribution(id: $id, en: $en, ar: $ar, fr: $fr)';
}
