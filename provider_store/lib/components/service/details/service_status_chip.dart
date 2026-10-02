import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class ServiceStatusChip extends StatelessWidget {
  final bool isActive;

  const ServiceStatusChip({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : colorScheme.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green : colorScheme.error,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isActive ? Colors.green : colorScheme.error,
          ),
          const SizedBox(width: 6),
          Text(
            isActive
                ? localizations?.status_active ?? 'Active'
                : localizations?.status_inactive ?? 'Inactive',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? Colors.green : colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
