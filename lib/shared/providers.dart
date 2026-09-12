import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/network/remote_contact_data_source.dart';
import '../features/contacts/data/contact_repository.dart';
import '../features/contacts/data/contact_sync_service.dart';
import '../features/contacts/data/local_contact_data_source.dart';
import '../features/corrections/data/correction_repository.dart';

final databaseProvider = FutureProvider((ref) => AppDatabase.instance.database);

final contactRepositoryProvider = FutureProvider<ContactRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  final remote = StaticJsonRemoteContactDataSource(
    manifestUrl: StaticJsonRemoteContactDataSource.environmentManifestUrl,
  );
  final repository = SqliteContactRepository(
    local: LocalContactDataSource(db),
    remote:
        remote.isConfigured ? remote : const DisabledRemoteContactDataSource(),
  );
  await repository.initialize();
  return repository;
});

final contactSyncServiceProvider = FutureProvider<ContactSyncService>((
  ref,
) async {
  final repository = await ref.watch(contactRepositoryProvider.future);
  return ContactSyncService(repository);
});

final correctionRepositoryProvider = FutureProvider<CorrectionRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return CorrectionRepository(db);
});
