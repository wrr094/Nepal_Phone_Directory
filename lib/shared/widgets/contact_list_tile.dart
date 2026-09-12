import 'package:flutter/material.dart';

import '../../core/utils/phone_utils.dart';
import '../../features/contacts/domain/contact.dart';
import '../../features/contacts/presentation/contact_detail_screen.dart';
import 'liquid_glass.dart';
import 'status_chips.dart';

class ContactListTile extends StatelessWidget {
  const ContactListTile({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (contact.category.isNotEmpty) contact.category,
      if (contact.district.isNotEmpty) contact.district,
      if (contact.palika.isNotEmpty) contact.palika,
    ].join(' • ');
    final numbers = contact.phoneNumbers;
    final primaryNumber = numbers.isEmpty ? null : numbers.first;

    return LiquidGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.zero,
      enableBlur: false,
      blur: 0,
      shadow: false,
      gradientOverlay: false,
      bevelStrength: 0.22,
      child: ListTile(
        title: Text(
          contact.organisationName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.nameNepali.isNotEmpty) Text(contact.nameNepali),
            if (subtitle.isNotEmpty) Text(subtitle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                VerificationChip(status: contact.verificationStatus),
                if (contact.isEmergency)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.emergency_outlined, size: 18),
                    label: Text('Emergency'),
                  ),
                if (contact.is247)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.schedule_outlined, size: 18),
                    label: Text('24/7'),
                  ),
              ],
            ),
          ],
        ),
        trailing:
            primaryNumber == null
                ? const Icon(Icons.chevron_right)
                : IconButton.filledTonal(
                  tooltip: 'Call',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(58, 58),
                    minimumSize: const Size(58, 58),
                  ),
                  onPressed: () => PhoneUtils.call(primaryNumber),
                  icon: const Icon(Icons.call, size: 28),
                ),
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(ContactDetailScreen.routeName, arguments: contact);
        },
      ),
    );
  }
}
