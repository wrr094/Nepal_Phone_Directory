import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/emergency_contacts.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../features/contacts/data/contact_query.dart';
import '../../../features/contacts/domain/contact.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/contact_list_tile.dart';
import '../../../shared/widgets/emergency_call_card.dart';
import '../../../shared/widgets/liquid_glass.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  static const routeName = '/emergency';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryValue = ref.watch(contactRepositoryProvider);

    final glass = LiquidGlassTheme.of(context);

    return LiquidGlassScaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LiquidGlassCard(
              borderRadius: AppRadii.panel,
              blur: 10,
              strong: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: glass.emergencyAccent,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'For immediate emergencies, use national emergency numbers first.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: nationalEmergencyContacts.length,
            itemBuilder: (context, index) {
              return EmergencyCallCard(
                contact: nationalEmergencyContacts[index],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
            child: Text(
              'Emergency contacts from local data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          repositoryValue.when(
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error:
                (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(error.toString()),
                ),
            data:
                (repository) => FutureBuilder<List<Contact>>(
                  future: repository.search(
                    const ContactQuery(emergencyOnly: true, limit: 50),
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
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(AppConstants.disclaimer),
          ),
        ],
      ),
    );
  }
}
