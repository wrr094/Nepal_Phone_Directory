import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';

class VerificationChip extends StatelessWidget {
  const VerificationChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final color = switch (status) {
      'Verified' => glass.successAccent,
      'Needs Review' => glass.warningAccent,
      _ => glass.textSecondary,
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(Icons.verified_outlined, color: color, size: 18),
      label: Text(status.isEmpty ? 'Unverified' : status),
    );
  }
}

class SourceTypeChip extends StatelessWidget {
  const SourceTypeChip({super.key, required this.sourceType});

  final String sourceType;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(Icons.source_outlined, color: glass.primaryAccent, size: 18),
      label: Text(sourceType.isEmpty ? 'Unknown' : sourceType),
    );
  }
}
