import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/contacts/domain/contact.dart';
import '../../../features/corrections/domain/correction.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/liquid_glass.dart';

class SuggestCorrectionScreen extends ConsumerStatefulWidget {
  const SuggestCorrectionScreen({super.key, this.contact});

  static const routeName = '/suggest-correction';

  final Contact? contact;

  @override
  ConsumerState<SuggestCorrectionScreen> createState() =>
      _SuggestCorrectionScreenState();
}

class _SuggestCorrectionScreenState
    extends ConsumerState<SuggestCorrectionScreen> {
  final _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _type = 'Wrong number';
  bool _saving = false;

  static const _types = [
    'Wrong number',
    'New number',
    'Closed office',
    'Duplicate entry',
    'Missing organisation',
    'Other correction',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repository = await ref.read(correctionRepositoryProvider.future);
    final now = DateTime.now();
    final correction = Correction(
      id: 'correction-${now.microsecondsSinceEpoch}',
      contactId: widget.contact?.id,
      correctionType: _type,
      details: _detailsController.text.trim(),
      createdAt: now,
    );
    await repository.save(correction);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correction saved for review.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    return LiquidGlassScaffold(
      appBar: AppBar(title: const Text('Suggest correction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (contact != null) ...[
              Text(
                contact.organisationName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(contact.category),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Correction type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final type in _types)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText:
                    'Write the correct number, duplicate details, or what changed.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Please add correction details.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon:
                  _saving
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              label: const Text('Save pending review'),
            ),
            const SizedBox(height: 12),
            Text(
              'Corrections are saved locally as pending review and do not automatically update public contact data.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
