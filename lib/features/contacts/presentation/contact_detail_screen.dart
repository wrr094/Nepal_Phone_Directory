import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../features/contacts/domain/contact.dart';
import '../../../features/corrections/presentation/suggest_correction_screen.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../../../shared/widgets/status_chips.dart';

class ContactDetailScreen extends StatelessWidget {
  const ContactDetailScreen({super.key, required this.contact});

  static const routeName = '/contact';

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final phoneButtonColor =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFD8EAFF)
            : const Color(0xFFEAF4FF);
    return LiquidGlassScaffold(
      appBar: AppBar(title: const Text('Contact details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LiquidGlass3DCard(
            borderRadius: AppRadii.panel,
            blur: 14,
            strong: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.organisationName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (contact.nameNepali.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    contact.nameNepali,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    VerificationChip(status: contact.verificationStatus),
                    SourceTypeChip(sourceType: contact.sourceType),
                    if (contact.isEmergency)
                      const Chip(label: Text('Emergency')),
                    if (contact.is247) const Chip(label: Text('24/7')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final phone in contact.phoneNumbers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BeveledGlassButton(
                onPressed: () => PhoneUtils.call(phone),
                icon: Icons.call,
                color: phoneButtonColor,
                foregroundColor: const Color(0xFF063E8A),
                label: 'Call ${PhoneUtils.normalizePhoneForDisplay(phone)}',
                semanticLabel:
                    'Call ${PhoneUtils.normalizePhoneForDisplay(phone)}',
              ),
            ),
          _ActionButtons(contact: contact),
          const SizedBox(height: 16),
          LiquidGlassCard(
            enableBlur: false,
            blur: 0,
            shadow: false,
            gradientOverlay: false,
            child: _InfoSection(
              rows: [
                _InfoRow(
                  'Category',
                  [
                    contact.category,
                    contact.subcategory,
                  ].where((e) => e.isNotEmpty).join(' / '),
                ),
                _InfoRow('Description', contact.description),
                _InfoRow('Address', contact.address),
                _InfoRow(
                  'Location',
                  [
                    contact.province,
                    contact.district,
                    contact.palika,
                    if (contact.ward.isNotEmpty) 'Ward ${contact.ward}',
                  ].where((e) => e.isNotEmpty).join(' / '),
                ),
                _InfoRow('Department', contact.department),
                _InfoRow('Working hours', contact.workingHours),
                _InfoRow('Key persons', contact.keyPersons),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SourceAndVerificationCard(contact: contact),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                SuggestCorrectionScreen.routeName,
                arguments: contact,
              );
            },
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Suggest correction'),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.disclaimer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    final emails =
        contact.email
            .split(';')
            .map((value) => value.trim())
            .where(isValidEmail)
            .toList();
    if (emails.isNotEmpty) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri(scheme: 'mailto', path: emails.first)),
          icon: const Icon(Icons.email_outlined),
          label: const Text('Email'),
        ),
      );
    }
    if (isValidWebsite(contact.website)) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse(contact.website)),
          icon: const Icon(Icons.language_outlined),
          label: const Text('Website'),
        ),
      );
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 8, runSpacing: 8, children: actions),
    );
  }
}

class _SourceAndVerificationCard extends StatelessWidget {
  const _SourceAndVerificationCard({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final sourceUrl = contact.sourceUrl.trim();
    final hasSourceUrl = isValidWebsite(sourceUrl);
    return LiquidGlassCard(
      enableBlur: false,
      blur: 0,
      shadow: false,
      gradientOverlay: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source and verification',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This app is independent and not a government app. Use the source link below to verify this public contact from its original source where available.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (hasSourceUrl) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  () => launchUrl(
                    Uri.parse(sourceUrl),
                    mode: LaunchMode.externalApplication,
                  ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open original source'),
            ),
          ],
          const SizedBox(height: 12),
          _InfoSection(
            rows: [
              _InfoRow('Source name', contact.sourceName),
              _InfoRow('Original source URL', contact.sourceUrl),
              _InfoRow('Source type', contact.sourceType),
              _InfoRow('Verification', contact.verificationStatus),
              _InfoRow('Confidence', contact.confidenceLevel),
              _InfoRow('Last checked', contact.lastChecked),
              _InfoRow('Notes', contact.notes),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows =
        rows.where((row) => row.value.trim().isNotEmpty).toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in visibleRows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  SelectableText(row.value),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}
