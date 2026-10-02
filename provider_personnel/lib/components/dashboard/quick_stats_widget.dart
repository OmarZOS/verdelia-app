import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:event/personnel_notifier.dart';
import 'package:provider/provider.dart';

class QuickStatsWidget extends StatelessWidget {
  final int supplierId;

  const QuickStatsWidget({super.key, required this.supplierId});

  Widget _buildStatItem(BuildContext context, String label, int count,
      IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<PersonnelNotifier>(
      builder: (context, notifier, _) {
        final stats = notifier.getSupplierStats(supplierId);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                localizations.status_active,
                stats['active'] ?? 0,
                Icons.people_alt,
                Colors.green,
              ),
              _buildStatItem(
                context,
                localizations.status_pending,
                stats['pending'] ?? 0,
                Icons.access_time,
                Colors.orange,
              ),
              _buildStatItem(
                context,
                localizations.totalTxt,
                stats['total'] ?? 0,
                Icons.group,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
