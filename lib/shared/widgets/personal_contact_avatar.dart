import 'dart:io';

import 'package:flutter/material.dart';

class PersonalContactAvatar extends StatelessWidget {
  const PersonalContactAvatar({
    super.key,
    required this.photoPath,
    this.size = 42,
    this.icon = Icons.person_outline,
  });

  final String photoPath;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fallback = _FallbackAvatar(size: size, icon: icon);
    if (photoPath.trim().isEmpty) return fallback;

    return ClipOval(
      child: Image.file(
        File(photoPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, size: size * 0.52, color: colorScheme.primary),
    );
  }
}
