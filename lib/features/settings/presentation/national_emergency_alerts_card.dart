import 'package:flutter/material.dart';

import '../../../core/theme/app_radii.dart';
import '../../../shared/widgets/liquid_glass.dart';

class NationalEmergencyAlertsCard extends StatelessWidget {
  const NationalEmergencyAlertsCard({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onChanged,
  });

  final bool enabled;
  final bool loading;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.panel,
      blur: 8,
      shadow: false,
      bevelStrength: 0.28,
      child: SwitchListTile(
        secondary: const Icon(Icons.crisis_alert_outlined),
        title: const Text('National emergency alerts'),
        subtitle: const Text(
          'Receive opt-in earthquake, flood, landslide, and public-safety notices with sound when device settings allow.',
        ),
        value: enabled,
        onChanged: loading ? null : onChanged,
      ),
    );
  }
}
