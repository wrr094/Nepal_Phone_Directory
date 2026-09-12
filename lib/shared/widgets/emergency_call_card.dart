import 'package:flutter/material.dart';

import '../../core/constants/directory_icons.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/utils/phone_utils.dart';
import '../../features/contacts/domain/contact.dart';
import 'liquid_glass.dart';

class EmergencyCallCard extends StatelessWidget {
  const EmergencyCallCard({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final numbers = contact.phoneNumbers;
    final number =
        contact.hotlineCode.isNotEmpty
            ? contact.hotlineCode
            : numbers.isEmpty
            ? ''
            : numbers.first;

    return LiquidGlass3DCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      borderRadius: AppRadii.card,
      blur: 8,
      strong: contact.isEmergency,
      bevelStrength: 0.82,
      onTap: number.isEmpty ? null : () => PhoneUtils.call(number),
      semanticLabel:
          number.isEmpty
              ? contact.organisationName
              : 'Call ${contact.organisationName} at $number',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _EmergencyIconBadge(contact: contact),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              PhoneUtils.normalizePhoneForDisplay(number),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: glass.textPrimary,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _compactEmergencyLabel(contact.organisationName),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: glass.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyIconBadge extends StatelessWidget {
  const _EmergencyIconBadge({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final accent = _accentForEmergencyContact(contact, glass);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.18),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(iconForEmergencyContact(contact), size: 29, color: accent),
          if (contact.organisationName.toLowerCase().contains('police'))
            Positioned(
              right: 9,
              top: 8,
              child: Icon(Icons.star, size: 8, color: accent),
            ),
        ],
      ),
    );
  }
}

String _compactEmergencyLabel(String label) {
  return label
      .replaceAll('Traffic Police', 'Traffic')
      .replaceAll('Child Helpline', 'Child Help')
      .replaceAll('Women Helpline', 'Women Help');
}

Color _accentForEmergencyContact(Contact contact, LiquidGlassTheme glass) {
  final label =
      '${contact.organisationName} ${contact.subcategory}'.toLowerCase();
  final number = contact.hotlineCode;
  if (label.contains('police') && !label.contains('traffic')) {
    return glass.primaryAccent;
  }
  if (label.contains('traffic') || number == '103') {
    return glass.warningAccent;
  }
  if (label.contains('child')) return glass.successAccent;
  if (label.contains('women')) return const Color(0xFFE46CFF);
  if (label.contains('electricity') || label.contains('nea')) {
    return const Color(0xFFFFC83D);
  }
  return glass.emergencyAccent;
}
