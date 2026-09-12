import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/emergency_contacts.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../features/categories_screen.dart';
import '../../../features/alerts/data/emergency_alert_service.dart';
import '../../../features/contacts/data/contact_query.dart';
import '../../../features/contacts/data/contact_repository.dart';
import '../../../features/contacts/domain/contact.dart';
import '../../../features/emergency/presentation/emergency_screen.dart';
import '../../../features/location/presentation/location_browser_screen.dart';
import '../../../features/search/presentation/search_screen.dart';
import '../../../features/settings/data/user_preferences.dart';
import '../../../features/settings/presentation/settings_screen.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/contact_list_tile.dart';
import '../../../shared/widgets/emergency_call_card.dart';
import '../../../shared/widgets/helpline_exit_button.dart';
import '../../../shared/widgets/liquid_glass.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({this.onExit, super.key});

  static const routeName = '/';
  final VoidCallback? onExit;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final sync = await ref.read(contactSyncServiceProvider.future);
      await sync.refreshFromRemote();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final repositoryValue = ref.watch(contactRepositoryProvider);
    final title = switch (_selectedIndex) {
      0 => 'Nepal HelpLine',
      1 => null,
      2 => null,
      _ => 'Settings',
    };

    final showExit =
        widget.onExit != null && (_selectedIndex == 0 || _selectedIndex == 3);
    return LiquidGlassScaffold(
      appBar:
          title == null
              ? null
              : AppBar(
                title: Text(title),
                actions: [
                  if (showExit) HelplineExitButton(onExit: widget.onExit!),
                ],
              ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTabView(repositoryValue: repositoryValue),
          const CategoriesView(),
          const LocationBrowserView(),
          const SettingsView(),
        ],
      ),
      bottomNavigationBar: GlassBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Location',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTabView extends ConsumerWidget {
  const _HomeTabView({required this.repositoryValue});

  final AsyncValue<ContactRepository> repositoryValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return repositoryValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _StartupError(message: error.toString()),
      data: (repository) {
        final glass = LiquidGlassTheme.of(context);
        final userPreferencesValue = ref.watch(userPreferencesProvider);
        return RefreshIndicator(
          onRefresh: () async {
            final sync = await ref.read(contactSyncServiceProvider.future);
            await sync.refreshFromRemote();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GlassSearchBar(
                  hintText: 'Search name, place, phone, service',
                  onTap:
                      () => Navigator.of(
                        context,
                      ).pushNamed(SearchScreen.routeName),
                  onSubmitted: (value) {
                    Navigator.of(context).pushNamed(
                      SearchScreen.routeName,
                      arguments: SearchScreenArgs(searchTerm: value),
                    );
                  },
                  readOnly: true,
                ),
              ),
              FutureBuilder<String>(
                future: repository.metadata('last_sync_at'),
                builder: (context, snapshot) {
                  final lastSync = snapshot.data ?? '';
                  final text =
                      lastSync.isEmpty
                          ? 'Offline seed data is available. Remote sync is not configured yet.'
                          : 'Using cached data. Last sync: $lastSync';
                  return LiquidGlassCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: AppRadii.card,
                    blur: 8,
                    shadow: false,
                    child: Row(
                      children: [
                        Icon(
                          Icons.offline_bolt_outlined,
                          color: glass.primaryAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            text,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const _IndependenceNoticeCard(),
              FutureBuilder<EmergencyAlert?>(
                future: EmergencyAlertService.instance.latestAlert(),
                builder: (context, snapshot) {
                  final alert = snapshot.data;
                  if (alert == null) return const SizedBox.shrink();
                  return _LatestNationalAlertCard(alert: alert);
                },
              ),
              userPreferencesValue.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data:
                    (preferences) => _PersonalEmergencyContactsSection(
                      preferences: preferences,
                    ),
              ),
              LiquidGlassCard(
                margin: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                borderRadius: AppRadii.panel,
                blur: 14,
                strong: true,
                bevelStrength: 0.34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: glass.emergencyAccent.withValues(
                              alpha: 0.14,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emergency_outlined,
                            color: glass.emergencyAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency quick actions',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Tap a card to call immediately.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pushNamed(EmergencyScreen.routeName),
                          child: const Text('All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 128,
                            childAspectRatio: 0.80,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return EmergencyCallCard(
                          contact: nationalEmergencyContacts[index],
                        );
                      },
                    ),
                  ],
                ),
              ),
              _SectionHeader(title: 'Recent / popular emergency contacts'),
              FutureBuilder<List<Contact>>(
                future: repository.search(
                  const ContactQuery(emergencyOnly: true, limit: 6),
                ),
                builder: (context, snapshot) {
                  final contacts = snapshot.data ?? const <Contact>[];
                  if (contacts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(AppConstants.disclaimer),
                    );
                  }
                  return Column(
                    children: [
                      for (final contact in contacts)
                        ContactListTile(contact: contact),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IndependenceNoticeCard extends StatelessWidget {
  const _IndependenceNoticeCard();

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.card,
      enableBlur: false,
      blur: 0,
      shadow: false,
      gradientOverlay: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Independent app. Not affiliated with any government entity. Contact detail pages include original source links where available.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestNationalAlertCard extends StatelessWidget {
  const _LatestNationalAlertCard({required this.alert});

  final EmergencyAlert alert;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    return LiquidGlassCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadii.card,
      strong: true,
      blur: 12,
      bevelStrength: 0.34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.crisis_alert_outlined, color: glass.emergencyAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latest national emergency alert',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert.title, style: Theme.of(context).textTheme.titleMedium),
          if (alert.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(alert.body),
          ],
          const SizedBox(height: 8),
          Text(
            'Source: ${alert.sourceName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (alert.sourceUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(alert.sourceUrl)),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open source'),
            ),
        ],
      ),
    );
  }
}

class _PersonalEmergencyContactsSection extends ConsumerWidget {
  const _PersonalEmergencyContactsSection({required this.preferences});

  final UserPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = preferences.personalEmergencyContacts;
    if (contacts.isEmpty) {
      if (preferences.emergencyContactPromptDismissed) {
        return const SizedBox.shrink();
      }
      return LiquidGlassCard(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        borderRadius: AppRadii.panel,
        blur: 10,
        shadow: false,
        child: Row(
          children: [
            const Icon(Icons.contact_emergency_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add a personal emergency contact',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed:
                  () =>
                      Navigator.of(context).pushNamed(SettingsScreen.routeName),
              child: const Text('Add'),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () {
                ref
                    .read(userPreferencesProvider.notifier)
                    .setEmergencyContactPromptDismissed(true);
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
    }

    final glass = LiquidGlassTheme.of(context);
    return LiquidGlassCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      borderRadius: AppRadii.panel,
      blur: 12,
      strong: true,
      bevelStrength: 0.34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_emergency_outlined,
                color: glass.primaryAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your emergency contacts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pushNamed(SettingsScreen.routeName),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 1.05,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _PersonalEmergencyContactCard(
                contact: contact,
                onAction: () => _openPersonalEmergencyContact(contact),
                onAddImage:
                    () => Navigator.of(
                      context,
                    ).pushNamed(SettingsScreen.routeName),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openPersonalEmergencyContact(PersonalEmergencyContact contact) {
    return switch (contact.actionPreference) {
      EmergencyContactActionPreference.call => PhoneUtils.call(contact.phone),
      EmergencyContactActionPreference.text => PhoneUtils.text(contact.phone),
    };
  }
}

class _PersonalEmergencyContactCard extends StatelessWidget {
  const _PersonalEmergencyContactCard({
    required this.contact,
    required this.onAction,
    required this.onAddImage,
  });

  final PersonalEmergencyContact contact;
  final VoidCallback onAction;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    final photoPath = contact.photoPath.trim();
    final hasPhoto = photoPath.isNotEmpty && File(photoPath).existsSync();
    return LiquidGlass3DCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.card,
      blur: hasPhoto ? 0 : 8,
      enableBlur: !hasPhoto,
      bevelStrength: 0.74,
      onTap: onAction,
      semanticLabel: '${contact.actionPreference.label} ${contact.displayName}',
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  hasPhoto
                      ? Image.file(File(photoPath), fit: BoxFit.cover)
                      : _AddContactPhotoBackground(onTap: onAddImage),
            ),
            if (hasPhoto)
              const Positioned.fill(child: _EmergencyContactPhotoScrim()),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _PersonalEmergencyContactDetails(
                contact: contact,
                onPhoto: hasPhoto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddContactPhotoBackground extends StatelessWidget {
  const _AddContactPhotoBackground({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glass.primaryAccent.withValues(alpha: 0.10),
            glass.emergencyAccent.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.person_outline,
              size: 64,
              color: glass.primaryAccent.withValues(alpha: 0.78),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Semantics(
              button: true,
              label: 'Add contact photo',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glass.primaryAccent,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.82),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 21, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactPhotoScrim extends StatelessWidget {
  const _EmergencyContactPhotoScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.02),
            Colors.black.withValues(alpha: 0.16),
            Colors.black.withValues(alpha: 0.72),
          ],
          stops: const [0, 0.52, 1],
        ),
      ),
    );
  }
}

class _PersonalEmergencyContactDetails extends StatelessWidget {
  const _PersonalEmergencyContactDetails({
    required this.contact,
    required this.onPhoto,
  });

  final PersonalEmergencyContact contact;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final textColor =
        onPhoto ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final secondaryColor =
        onPhoto
            ? Colors.white.withValues(alpha: 0.88)
            : Theme.of(context).textTheme.labelMedium?.color;
    final shadow =
        onPhoto
            ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.62),
                offset: const Offset(0, 1),
                blurRadius: 6,
              ),
            ]
            : null;
    final subtitle =
        contact.relationship.trim().isEmpty
            ? PhoneUtils.normalizePhoneForDisplay(contact.phone)
            : '${contact.relationship} • ${PhoneUtils.normalizePhoneForDisplay(contact.phone)}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                onPhoto
                    ? Colors.white.withValues(alpha: 0.18)
                    : glass.emergencyAccent.withValues(alpha: 0.13),
            border: Border.all(
              color:
                  onPhoto
                      ? Colors.white.withValues(alpha: 0.42)
                      : glass.emergencyAccent.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(
            contact.actionPreference == EmergencyContactActionPreference.text
                ? Icons.sms_outlined
                : Icons.call_outlined,
            color: onPhoto ? Colors.white : glass.emergencyAccent,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  shadows: shadow,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: secondaryColor,
                  shadows: shadow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not open local directory data.\n\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
