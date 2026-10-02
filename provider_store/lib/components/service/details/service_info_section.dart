import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:provider_store/components/service/details/info_row.dart';
import 'package:provider_store/components/service/details/section_container.dart';

class ServiceInfoSection extends StatelessWidget {
  final ProvidedService service;

  const ServiceInfoSection({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SectionContainer(
      icon: Icons.info_outline_rounded,
      title: localizations?.serviceDetails ?? 'Service Details',
      color: colorScheme.primary,
      child: Column(
        children: [
          InfoRow(
            label: localizations?.serviceDescription ?? 'Description',
            value: service.description,
            icon: Icons.description,
          ),
          const Divider(height: 24),
          InfoRow(
            label: localizations?.duration ?? 'Duration',
            value: service.durationFormatted,
            icon: Icons.access_time,
          ),
          const Divider(height: 24),
          InfoRow(
            label: localizations?.category ?? 'Category',
            value: _getCategoryName(service.categoryId),
            icon: Icons.category,
          ),
          const Divider(height: 24),
          InfoRow(
            label: localizations?.createdAt ?? 'Created',
            value: _formatDate(service.createdAt),
            icon: Icons.calendar_today,
          ),
          if (service.deletedAt != null) ...[
            const Divider(height: 24),
            InfoRow(
              label: localizations?.deletedAt ?? 'Deleted',
              value: _formatDate(service.deletedAt!),
              icon: Icons.delete_outline,
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryName(int categoryId) {
    const categories = {
      1: 'Pathology Tests',
      2: 'Medical Imaging',
      3: 'Vaccinations',
      4: 'Health Checkups',
      5: 'Dental Services',
      6: 'Other Services',
    };
    return categories[categoryId] ?? 'Unknown Category';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
