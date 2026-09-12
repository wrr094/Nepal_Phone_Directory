import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/legal_documents.dart';
import '../../../core/location/location_selection.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/utils/personal_contact_photo_store.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../features/alerts/data/emergency_alert_service.dart';
import '../../../features/contacts/data/contact_repository.dart';
import '../../../features/settings/data/user_preferences.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/helpline_exit_button.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../../../shared/widgets/personal_contact_avatar.dart';
import 'legal_document_screen.dart';
import 'national_emergency_alerts_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({this.onExit, super.key});

  static const routeName = '/settings';
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [if (onExit != null) HelplineExitButton(onExit: onExit!)],
      ),
      body: const SettingsView(),
    );
  }
}

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _working = false;
  String? _manualProvince;
  String? _manualDistrict;
  String? _manualPalika;
  String _manualLocationSeed = '';
  bool? _nationalAlertsEnabled;

  @override
  void initState() {
    super.initState();
    EmergencyAlertService.instance.isEnabled().then((enabled) {
      if (mounted) setState(() => _nationalAlertsEnabled = enabled);
    });
  }

  Future<void> _setNationalAlertsEnabled(bool enabled) async {
    setState(() => _working = true);
    final result = await EmergencyAlertService.instance.setEnabled(enabled);
    if (!mounted) return;
    setState(() {
      _working = false;
      _nationalAlertsEnabled = result;
    });
    if (enabled && !result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission was not granted.'),
        ),
      );
    }
  }

  Future<void> _forceRefresh() async {
    setState(() => _working = true);
    final sync = await ref.read(contactSyncServiceProvider.future);
    final ok = await sync.refreshFromRemote();
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Data refreshed from remote source.'
              : 'Remote sync is unavailable. Cached local data is still available.',
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    setState(() => _working = true);
    final repository = await ref.read(contactRepositoryProvider.future);
    final count = await repository.reloadSeedData();
    ref.invalidate(contactRepositoryProvider);
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cache cleared. Imported $count seed contacts.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repositoryValue = ref.watch(contactRepositoryProvider);
    final userPreferencesValue = ref.watch(userPreferencesProvider);
    final isDarkMode = ref.watch(themeModeControllerProvider) == ThemeMode.dark;
    return repositoryValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (repository) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: AppRadii.panel,
              blur: 8,
              shadow: false,
              bevelStrength: 0.28,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark mode'),
                    subtitle: const Text(
                      'Use Dark Liquid Glass instead of Blue Liquid Glass.',
                    ),
                    value: isDarkMode,
                    onChanged: (value) {
                      ref
                          .read(themeModeControllerProvider.notifier)
                          .setDarkMode(value);
                    },
                  ),
                  FutureBuilder<String>(
                    future: repository.metadata('data_version'),
                    builder: (context, snapshot) {
                      return ListTile(
                        leading: const Icon(Icons.dataset_outlined),
                        title: const Text('Data version'),
                        subtitle: Text(
                          snapshot.data?.isNotEmpty == true
                              ? snapshot.data!
                              : AppConstants.bundledDataVersion,
                        ),
                      );
                    },
                  ),
                  FutureBuilder<String>(
                    future: repository.metadata('last_sync_at'),
                    builder: (context, snapshot) {
                      return ListTile(
                        leading: const Icon(Icons.sync_outlined),
                        title: const Text('Last sync time'),
                        subtitle: Text(
                          snapshot.data?.isNotEmpty == true
                              ? snapshot.data!
                              : 'Remote sync not configured yet',
                        ),
                      );
                    },
                  ),
                  FutureBuilder<int>(
                    future: ref
                        .read(correctionRepositoryProvider.future)
                        .then((repo) => repo.pendingCount()),
                    builder: (context, snapshot) {
                      return ListTile(
                        leading: const Icon(Icons.edit_note_outlined),
                        title: const Text('Pending local corrections'),
                        subtitle: Text('${snapshot.data ?? 0} pending review'),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            NationalEmergencyAlertsCard(
              enabled: _nationalAlertsEnabled ?? false,
              loading: _nationalAlertsEnabled == null || _working,
              onChanged: _setNationalAlertsEnabled,
            ),
            const SizedBox(height: AppSpacing.md),
            userPreferencesValue.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error: (error, _) => Text(error.toString()),
              data: (preferences) {
                _syncManualLocationSelection(preferences.manualLocation);
                return _DefaultAddressSettingsCard(
                  repository: repository,
                  preferences: preferences,
                  province: _manualProvince,
                  district: _manualDistrict,
                  palika: _manualPalika,
                  onModeChanged: (mode) {
                    ref
                        .read(userPreferencesProvider.notifier)
                        .setDefaultAddressMode(mode);
                  },
                  onProvinceChanged: (value) {
                    setState(() {
                      _manualProvince = value;
                      _manualDistrict = null;
                      _manualPalika = null;
                    });
                  },
                  onDistrictChanged: (value) {
                    setState(() {
                      _manualDistrict = value;
                      _manualPalika = null;
                    });
                  },
                  onPalikaChanged: (value) {
                    setState(() => _manualPalika = value);
                  },
                  onSaveManualLocation: () async {
                    final location = LocationSelection(
                      province: _manualProvince ?? '',
                      district: _manualDistrict ?? '',
                      palika: _manualPalika ?? '',
                    );
                    await ref
                        .read(userPreferencesProvider.notifier)
                        .setManualDefaultLocation(location);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default manual address saved.'),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            userPreferencesValue.when(
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Text(error.toString()),
              data:
                  (preferences) => _EmergencyContactsSettingsCard(
                    contacts: preferences.personalEmergencyContacts,
                    onAdd: () => _showEmergencyContactDialog(),
                    onEdit: _showEmergencyContactDialog,
                    onRemove: _confirmRemoveEmergencyContact,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: AppRadii.panel,
              blur: 8,
              shadow: false,
              bevelStrength: 0.28,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_outlined),
                    title: const Text('Force refresh data'),
                    subtitle: const Text('Uses remote source when configured.'),
                    enabled: !_working,
                    onTap: _forceRefresh,
                  ),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('Clear cache'),
                    subtitle: const Text('Reloads bundled offline seed data.'),
                    enabled: !_working,
                    onTap: _clearCache,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: AppRadii.panel,
              blur: 8,
              shadow: false,
              bevelStrength: 0.28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Legal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final document in legalDocuments)
                    ListTile(
                      leading: Icon(_iconForLegalDocument(document.iconName)),
                      title: Text(document.title),
                      subtitle:
                          document.sourceUrl == null
                              ? null
                              : const Text(
                                'Loaded from GitHub document source',
                              ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          LegalDocumentScreen.routeName,
                          arguments: document,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _syncManualLocationSelection(LocationSelection location) {
    final seed = '${location.province}|${location.district}|${location.palika}';
    if (_manualLocationSeed == seed) return;
    _manualLocationSeed = seed;
    _manualProvince = location.province.isEmpty ? null : location.province;
    _manualDistrict = location.district.isEmpty ? null : location.district;
    _manualPalika = location.palika.isEmpty ? null : location.palika;
  }

  Future<void> _confirmRemoveEmergencyContact(
    PersonalEmergencyContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete emergency contact?'),
          content: Text(
            'Remove ${contact.displayName} from your personal emergency contacts?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref
        .read(userPreferencesProvider.notifier)
        .removeEmergencyContact(contact.id);
    await PersonalContactPhotoStore.deletePhoto(contact.photoPath);
  }

  Future<void> _showEmergencyContactDialog([
    PersonalEmergencyContact? existing,
  ]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final relationshipController = TextEditingController(
      text: existing?.relationship ?? '',
    );
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    var actionPreference =
        existing?.actionPreference ?? EmergencyContactActionPreference.call;
    final photoPath = existing?.photoPath ?? '';
    String? pendingPhotoPath;
    var removePhoto = false;
    final saved = await showDialog<PersonalEmergencyContact>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewPhotoPath =
                removePhoto ? '' : pendingPhotoPath ?? photoPath;
            return AlertDialog(
              title: Text(
                existing == null ? 'Add emergency contact' : 'Edit contact',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        PersonalContactAvatar(
                          photoPath: previewPhotoPath,
                          size: 64,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final pickedPath =
                                      await PersonalContactPhotoStore.pickFromGallery();
                                  if (pickedPath == null || !context.mounted) {
                                    return;
                                  }
                                  setDialogState(() {
                                    pendingPhotoPath = pickedPath;
                                    removePhoto = false;
                                  });
                                },
                                icon: const Icon(Icons.photo_outlined),
                                label: const Text('Choose photo'),
                              ),
                              if (previewPhotoPath.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      pendingPhotoPath = null;
                                      removePhoto = true;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('Remove'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: relationshipController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        hintText: 'Spouse, parent, sibling',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Emergency action',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<EmergencyContactActionPreference>(
                      segments: const [
                        ButtonSegment(
                          value: EmergencyContactActionPreference.call,
                          icon: Icon(Icons.call_outlined),
                          label: Text('Call'),
                        ),
                        ButtonSegment(
                          value: EmergencyContactActionPreference.text,
                          icon: Icon(Icons.sms_outlined),
                          label: Text('Text'),
                        ),
                      ],
                      selected: {actionPreference},
                      onSelectionChanged: (values) {
                        setDialogState(() => actionPreference = values.first);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final phone = phoneController.text.trim();
                    if (phone.isEmpty) return;
                    final verified =
                        PhoneUtils.isRecognizedNepalPersonalPhone(phone) ||
                        await _confirmUnusualPhoneNumber(context, phone);
                    if (!verified || !context.mounted) return;
                    final contactId =
                        existing?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString();
                    var savedPhotoPath = removePhoto ? '' : photoPath;
                    if (pendingPhotoPath != null) {
                      try {
                        savedPhotoPath =
                            await PersonalContactPhotoStore.savePhoto(
                              sourcePath: pendingPhotoPath!,
                              contactId: contactId,
                            );
                      } catch (_) {
                        savedPhotoPath = removePhoto ? '' : photoPath;
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not save contact image. Contact saved without changing the image.',
                              ),
                            ),
                          );
                        }
                      }
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop(
                      PersonalEmergencyContact(
                        id: contactId,
                        name: nameController.text.trim(),
                        relationship: relationshipController.text.trim(),
                        phone: phone,
                        actionPreference: actionPreference,
                        photoPath: savedPhotoPath,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
    relationshipController.dispose();
    phoneController.dispose();
    if (saved == null) return;
    await ref
        .read(userPreferencesProvider.notifier)
        .saveEmergencyContact(saved);
    final previousPhotoPath = existing?.photoPath ?? '';
    if (previousPhotoPath.isNotEmpty && previousPhotoPath != saved.photoPath) {
      await PersonalContactPhotoStore.deletePhoto(previousPhotoPath);
    }
  }

  Future<bool> _confirmUnusualPhoneNumber(
    BuildContext context,
    String phone,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify phone number'),
          content: Text(
            '$phone does not match the expected Nepal phone number formats. Save it anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Review'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save anyway'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}

class _DefaultAddressSettingsCard extends StatelessWidget {
  const _DefaultAddressSettingsCard({
    required this.repository,
    required this.preferences,
    required this.province,
    required this.district,
    required this.palika,
    required this.onModeChanged,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onPalikaChanged,
    required this.onSaveManualLocation,
  });

  final ContactRepository repository;
  final UserPreferences preferences;
  final String? province;
  final String? district;
  final String? palika;
  final ValueChanged<DefaultAddressMode> onModeChanged;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onPalikaChanged;
  final Future<void> Function() onSaveManualLocation;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.panel,
      blur: 8,
      shadow: false,
      bevelStrength: 0.28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Default address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<DefaultAddressMode>(
            groupValue: preferences.defaultAddressMode,
            onChanged: (value) {
              if (value != null) onModeChanged(value);
            },
            child: Column(
              children: [
                RadioListTile<DefaultAddressMode>(
                  secondary: const Icon(Icons.edit_location_alt_outlined),
                  title: const Text('Manual location'),
                  subtitle: Text(preferences.manualLocation.label),
                  value: DefaultAddressMode.manual,
                ),
                if (preferences.defaultAddressMode == DefaultAddressMode.manual)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SettingsAsyncDropdown(
                                label: 'Province',
                                value: province,
                                valuesFuture: repository.distinctValues(
                                  'province',
                                ),
                                onChanged: onProvinceChanged,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SettingsAsyncDropdown(
                                label: 'District',
                                value: district,
                                valuesFuture: repository.distinctValues(
                                  'district',
                                  filters: {'province': province ?? ''},
                                ),
                                onChanged: onDistrictChanged,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SettingsAsyncDropdown(
                          label: 'Palika',
                          value: palika,
                          valuesFuture: repository.distinctValues(
                            'palika',
                            filters: {
                              'province': province ?? '',
                              'district': district ?? '',
                            },
                          ),
                          onChanged: onPalikaChanged,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () {
                              onSaveManualLocation();
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save address'),
                          ),
                        ),
                      ],
                    ),
                  ),
                RadioListTile<DefaultAddressMode>(
                  secondary: const Icon(Icons.my_location_outlined),
                  title: const Text('GPS location'),
                  subtitle: const Text(
                    'Use current location in Search and Location.',
                  ),
                  value: DefaultAddressMode.gps,
                ),
                RadioListTile<DefaultAddressMode>(
                  secondary: const Icon(Icons.history_outlined),
                  title: const Text('Last searched location'),
                  subtitle: Text(preferences.lastSearchedLocation.label),
                  value: DefaultAddressMode.lastSearched,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsAsyncDropdown extends StatelessWidget {
  const _SettingsAsyncDropdown({
    required this.label,
    required this.value,
    required this.valuesFuture,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Future<List<String>> valuesFuture;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: valuesFuture,
      builder: (context, snapshot) {
        final values = snapshot.data ?? const <String>[];
        return _SettingsStaticDropdown(
          label: label,
          value: value,
          values: values,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SettingsStaticDropdown extends StatelessWidget {
  const _SettingsStaticDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final uniqueValues = values.toSet().toList()..sort();
    final selected = uniqueValues.contains(value) ? value : null;
    return DropdownButtonFormField<String?>(
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Any')),
        for (final item in uniqueValues)
          DropdownMenuItem<String?>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EmergencyContactsSettingsCard extends StatelessWidget {
  const _EmergencyContactsSettingsCard({
    required this.contacts,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<PersonalEmergencyContact> contacts;
  final VoidCallback onAdd;
  final ValueChanged<PersonalEmergencyContact> onEdit;
  final ValueChanged<PersonalEmergencyContact> onRemove;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.panel,
      blur: 8,
      shadow: false,
      bevelStrength: 0.28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Personal emergency contacts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${contacts.length}/$maxPersonalEmergencyContacts'),
              ],
            ),
          ),
          if (contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Add up to 4 family or trusted contacts.'),
            ),
          for (final contact in contacts)
            ListTile(
              leading: PersonalContactAvatar(
                photoPath: contact.photoPath,
                size: 44,
                icon: Icons.contact_emergency_outlined,
              ),
              title: Text(contact.displayName),
              subtitle: Text(
                '${contact.actionPreference.label} • ${contact.subtitle}',
              ),
              trailing: SizedBox(
                width: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => onEdit(contact),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => onRemove(contact),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: FilledButton.icon(
              onPressed:
                  contacts.length >= maxPersonalEmergencyContacts
                      ? null
                      : onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add emergency contact'),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForLegalDocument(String iconName) {
  return switch (iconName) {
    'privacy' => Icons.privacy_tip_outlined,
    'terms' => Icons.article_outlined,
    'about' => Icons.info_outline,
    'sources' => Icons.source_outlined,
    'disclaimer' => Icons.warning_amber_outlined,
    _ => Icons.description_outlined,
  };
}
