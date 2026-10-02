import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

/// 服务UI提供者 - 基于ID映射的医疗健康服务
class ServiceUIProvider {
  // 单例实例
  static final ServiceUIProvider _instance = ServiceUIProvider._internal();
  factory ServiceUIProvider() => _instance;
  ServiceUIProvider._internal();

  // ==================== 服务分类配置 (基于ID映射) ====================

  /// 医疗健康服务分类定义 - 按ID映射
  static final Map<int, MedicalServiceConfig> _medicalServices = {
    // 检测类服务
    1: MedicalServiceConfig(
      id: 1,
      key: 'blood_testing',
      name: 'Blood Testing',
      defaultPrice: 30.00,
      description:
          'Complete blood count, cholesterol, glucose, and other blood tests',
      icon: Icons.bloodtype_rounded,
      color: Colors.red,
      duration: 15,
      category: 'testing',
      priority: 1,
    ),
    2: MedicalServiceConfig(
      id: 2,
      key: 'diagnostic_imaging',
      name: 'Diagnostic Imaging',
      defaultPrice: 45.00,
      description: 'X-rays, MRIs, CT scans, and ultrasound services',
      icon: Icons.scanner_rounded,
      color: Colors.blue,
      duration: 30,
      category: 'imaging',
      priority: 2,
    ),
    6: MedicalServiceConfig(
      id: 6,
      key: 'pathology_tests',
      name: 'Pathology Tests',
      defaultPrice: 120.00,
      description: 'Tissue biopsy analysis and histopathology',
      icon: Icons.handyman,
      color: Colors.purple,
      duration: 60,
      category: 'testing',
      priority: 6,
    ),
    7: MedicalServiceConfig(
      id: 7,
      key: 'urine_analysis',
      name: 'Urine Analysis',
      defaultPrice: 20.00,
      description: 'Complete urinalysis and culture tests',
      icon: Icons.science_rounded,
      color: Colors.amber,
      duration: 10,
      category: 'testing',
      priority: 7,
    ),
    8: MedicalServiceConfig(
      id: 8,
      key: 'allergy_testing',
      name: 'Allergy Testing',
      defaultPrice: 90.00,
      description: 'Skin prick tests and allergen screening',
      icon: Icons.handyman,
      color: Colors.orange,
      duration: 45,
      category: 'testing',
      priority: 8,
    ),
    9: MedicalServiceConfig(
      id: 9,
      key: 'genetic_testing',
      name: 'Genetic Testing',
      defaultPrice: 180.00,
      description: 'DNA analysis and genetic screening services',
      icon: Icons.handyman,
      color: Colors.indigo,
      duration: 90,
      category: 'testing',
      priority: 9,
    ),

    // 预防和治疗类服务
    3: MedicalServiceConfig(
      id: 3,
      key: 'vaccination',
      name: 'Vaccination',
      defaultPrice: 15.00,
      description: 'Routine immunizations and travel vaccinations',
      icon: Icons.medical_services_rounded,
      color: Colors.green,
      duration: 10,
      category: 'prevention',
      priority: 3,
    ),
    4: MedicalServiceConfig(
      id: 4,
      key: 'health_checkup',
      name: 'Health Check-up',
      defaultPrice: 60.00,
      description: 'Comprehensive annual physical examinations',
      icon: Icons.handyman,
      color: Colors.blueAccent,
      duration: 45,
      category: 'checkup',
      priority: 4,
    ),
    5: MedicalServiceConfig(
      id: 5,
      key: 'dental_care',
      name: 'Dental Care',
      defaultPrice: 40.00,
      description: 'Teeth cleaning, fillings, and basic dental procedures',
      icon: Icons.handyman,
      color: Colors.lightBlue,
      duration: 30,
      category: 'dental',
      priority: 5,
    ),
    19: MedicalServiceConfig(
      id: 19,
      key: 'minor_surgery',
      name: 'Minor Surgery',
      defaultPrice: 75.00,
      description: 'Outpatient minor surgical procedures',
      icon: Icons.handyman,
      color: Colors.deepPurple,
      duration: 60,
      category: 'surgical',
      priority: 19,
    ),
    20: MedicalServiceConfig(
      id: 20,
      key: 'wound_care',
      name: 'Wound Care',
      defaultPrice: 25.00,
      description: 'Dressing changes and wound management',
      icon: Icons.healing_rounded,
      color: Colors.pink,
      duration: 15,
      category: 'treatment',
      priority: 20,
    ),
    21: MedicalServiceConfig(
      id: 21,
      key: 'iv_therapy',
      name: 'IV Therapy',
      defaultPrice: 35.00,
      description: 'Intravenous hydration and vitamin therapy',
      icon: Icons.medication_liquid_rounded,
      color: Colors.cyan,
      duration: 30,
      category: 'treatment',
      priority: 21,
    ),

    // 康复和治疗类服务
    10: MedicalServiceConfig(
      id: 10,
      key: 'physiotherapy',
      name: 'Physiotherapy',
      defaultPrice: 50.00,
      description: 'Rehabilitation and physical therapy sessions',
      icon: Icons.handyman,
      color: Colors.teal,
      duration: 45,
      category: 'rehabilitation',
      priority: 10,
    ),
    13: MedicalServiceConfig(
      id: 13,
      key: 'acupuncture',
      name: 'Acupuncture',
      defaultPrice: 40.00,
      description: 'Traditional acupuncture therapy sessions',
      icon: Icons.ac_unit_rounded,
      color: Colors.brown,
      duration: 30,
      category: 'alternative',
      priority: 13,
    ),

    // 咨询和辅导类服务
    11: MedicalServiceConfig(
      id: 11,
      key: 'nutrition_counseling',
      name: 'Nutrition Counseling',
      defaultPrice: 45.00,
      description: 'Diet planning and nutritional guidance',
      icon: Icons.restaurant_rounded,
      color: Colors.lightGreen,
      duration: 45,
      category: 'counseling',
      priority: 11,
    ),
    12: MedicalServiceConfig(
      id: 12,
      key: 'mental_health_counseling',
      name: 'Mental Health Counseling',
      defaultPrice: 60.00,
      description: 'Therapy and psychological counseling sessions',
      icon: Icons.psychology_rounded,
      color: Colors.deepOrange,
      duration: 50,
      category: 'counseling',
      priority: 12,
    ),
    18: MedicalServiceConfig(
      id: 18,
      key: 'first_aid_training',
      name: 'First Aid Training',
      defaultPrice: 240.00,
      description: 'CPR and emergency first aid certification',
      icon: Icons.emergency_rounded,
      color: Colors.redAccent,
      duration: 240,
      category: 'training',
      priority: 18,
    ),

    // 专业人群服务
    14: MedicalServiceConfig(
      id: 14,
      key: 'prenatal_care',
      name: 'Prenatal Care',
      defaultPrice: 30.00,
      description: 'Pregnancy monitoring and prenatal check-ups',
      icon: Icons.pregnant_woman_rounded,
      color: Colors.pinkAccent,
      duration: 30,
      category: 'specialized',
      priority: 14,
    ),
    15: MedicalServiceConfig(
      id: 15,
      key: 'pediatric_care',
      name: 'Pediatric Care',
      defaultPrice: 25.00,
      description: 'Child healthcare and development monitoring',
      icon: Icons.child_care_rounded,
      color: Colors.orangeAccent,
      duration: 25,
      category: 'specialized',
      priority: 15,
    ),
    16: MedicalServiceConfig(
      id: 16,
      key: 'geriatric_care',
      name: 'Geriatric Care',
      defaultPrice: 40.00,
      description: 'Elderly health monitoring and management',
      icon: Icons.elderly_rounded,
      color: Colors.blueGrey,
      duration: 40,
      category: 'specialized',
      priority: 16,
    ),
    17: MedicalServiceConfig(
      id: 17,
      key: 'sports_medicine',
      name: 'Sports Medicine',
      defaultPrice: 50.00,
      description: 'Injury assessment and sports-related healthcare',
      icon: Icons.sports_rounded,
      color: Colors.deepOrangeAccent,
      duration: 45,
      category: 'specialized',
      priority: 17,
    ),

    // 默认/通用服务 (ID为0表示未知服务)
    0: MedicalServiceConfig(
      id: 0,
      key: 'general_medical',
      name: 'General Medical Service',
      defaultPrice: 50.00,
      description: 'General medical consultation and examination',
      icon: Icons.local_hospital_rounded,
      color: Colors.grey,
      duration: 30,
      category: 'general',
      priority: 999,
    ),
  };

  // ==================== 分类分组 ====================

  /// 按类别分组服务
  static final Map<String, List<int>> _serviceCategories = {
    'testing': [1, 6, 7, 8, 9],
    'imaging': [2],
    'prevention': [3],
    'checkup': [4],
    'dental': [5],
    'surgical': [19],
    'treatment': [20, 21],
    'rehabilitation': [10],
    'alternative': [13],
    'counseling': [11, 12],
    'training': [18],
    'specialized': [14, 15, 16, 17],
    'general': [0],
  };

  // ==================== 公共方法 ====================

  /// 根据服务ID获取配置
  MedicalServiceConfig getServiceConfig(int serviceId) {
    return _medicalServices[serviceId] ?? _medicalServices[0]!;
  }

  /// 根据服务名称获取ID
  int? getServiceIdByName(String serviceName) {
    for (final entry in _medicalServices.entries) {
      if (entry.value.name.toLowerCase() == serviceName.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  /// 获取本地化的服务名称
  String getLocalizedServiceName(int serviceId, AppLocalizations l10n) {
    final config = getServiceConfig(serviceId);
    return _getLocalizedName(config.key, l10n);
  }

  /// 获取本地化的服务描述
  String getLocalizedServiceDescription(int serviceId, AppLocalizations l10n) {
    final config = getServiceConfig(serviceId);
    return _getLocalizedDescription(config.key, l10n);
  }

  /// 获取服务图标
  IconData getServiceIcon(int serviceId) {
    return getServiceConfig(serviceId).icon;
  }

  /// 获取服务颜色
  Color getServiceColor(int serviceId) {
    return getServiceConfig(serviceId).color;
  }

  /// 获取服务默认价格
  double getServicePrice(int serviceId) {
    return getServiceConfig(serviceId).defaultPrice;
  }

  /// 获取服务默认时长（分钟）
  int getServiceDuration(int serviceId) {
    return getServiceConfig(serviceId).duration;
  }

  /// 获取服务分类
  String getServiceCategory(int serviceId) {
    return getServiceConfig(serviceId).category;
  }

  /// 获取分类中的所有服务ID
  List<int> getServicesByCategory(String category) {
    return _serviceCategories[category] ?? [];
  }

  /// 获取所有服务ID
  List<int> getAllServiceIds() {
    return _medicalServices.keys.where((id) => id > 0).toList();
  }

  /// 获取服务分类徽章
  Widget getServiceBadge(
    int serviceId,
    BuildContext context, {
    bool showIcon = true,
    bool showLabel = true,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final config = getServiceConfig(serviceId);
    final color = config.color;
    final label = getLocalizedServiceName(serviceId, l10n);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              size: compact ? 12 : 14,
              color: color,
            ),
            if (showLabel) const SizedBox(width: 6),
          ],
          if (showLabel) ...[
            Text(
              compact ? config.key.replaceAll('_', ' ') : label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 获取服务卡片图标容器
  Widget getServiceIconContainer(
    int serviceId,
    BuildContext context, {
    double size = 100,
    bool withBackground = true,
  }) {
    final config = getServiceConfig(serviceId);
    final color = config.color;

    if (!withBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          config.icon,
          size: size * 0.4,
          color: color,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            config.icon,
            size: size * 0.25,
            color: color,
          ),
        ),
      ),
    );
  }

  /// 获取时长显示组件
  Widget getDurationChip(
    int? durationMinutes,
    BuildContext context, {
    int? serviceId,
    bool showIcon = true,
  }) {
    final displayDuration = durationMinutes ??
        (serviceId != null ? getServiceDuration(serviceId) : 30);

    if (displayDuration <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final color = serviceId != null
        ? getServiceColor(serviceId)
        : theme.colorScheme.secondary;
    final durationText = _formatDuration(displayDuration);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            durationText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 私有辅助方法 ====================

  /// 获取本地化名称
  String _getLocalizedName(String key, AppLocalizations l10n) {
    switch (key) {
      // 检测类服务
      case 'blood_testing':
        return l10n.serviceBloodTesting;
      case 'diagnostic_imaging':
        return l10n.serviceDiagnosticImaging;
      case 'pathology_tests':
        return l10n.servicePathologyTests;
      case 'urine_analysis':
        return l10n.serviceUrineAnalysis;
      case 'allergy_testing':
        return l10n.serviceAllergyTesting;
      case 'genetic_testing':
        return l10n.serviceGeneticTesting;

      // 预防和治疗类服务
      case 'vaccination':
        return l10n.serviceVaccination;
      case 'health_checkup':
        return l10n.serviceHealthCheckup;
      case 'dental_care':
        return l10n.serviceDentalCare;
      case 'minor_surgery':
        return l10n.serviceMinorSurgery;
      case 'wound_care':
        return l10n.serviceWoundCare;
      case 'iv_therapy':
        return l10n.serviceIVTherapy;

      // 康复和治疗类服务
      case 'physiotherapy':
        return l10n.servicePhysiotherapy;
      case 'acupuncture':
        return l10n.serviceAcupuncture;

      // 咨询和辅导类服务
      case 'nutrition_counseling':
        return l10n.serviceNutritionCounseling;
      case 'mental_health_counseling':
        return l10n.serviceMentalHealthCounseling;
      case 'first_aid_training':
        return l10n.serviceFirstAidTraining;

      // 专业人群服务
      case 'prenatal_care':
        return l10n.servicePrenatalCare;
      case 'pediatric_care':
        return l10n.servicePediatricCare;
      case 'geriatric_care':
        return l10n.serviceGeriatricCare;
      case 'sports_medicine':
        return l10n.serviceSportsMedicine;

      case 'general_medical':
      default:
        return l10n.serviceGeneralMedical;
    }
  }

  /// 获取本地化描述
  String _getLocalizedDescription(String key, AppLocalizations l10n) {
    switch (key) {
      case 'blood_testing':
        return "l10n.serviceDescBloodTesting";
      case 'diagnostic_imaging':
        return "l10n.serviceDescDiagnosticImaging";
      // 其他描述...
      default:
        return getServiceConfig(
                getServiceIdByName(key.replaceAll('_', ' ')) ?? 0)
            .description;
    }
  }

  /// 格式化时长
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}min';
  }
}

/// 医疗服务配置模型
class MedicalServiceConfig {
  final int id;
  final String key;
  final String name;
  final double defaultPrice;
  final String description;
  final IconData icon;
  final Color color;
  final int duration; // 分钟
  final String category;
  final int priority;

  const MedicalServiceConfig({
    required this.id,
    required this.key,
    required this.name,
    required this.defaultPrice,
    required this.description,
    required this.icon,
    required this.color,
    required this.duration,
    required this.category,
    required this.priority,
  });
}
