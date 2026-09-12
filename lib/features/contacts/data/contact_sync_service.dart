import 'contact_repository.dart';

class ContactSyncService {
  const ContactSyncService(this._repository);

  final ContactRepository _repository;

  Future<bool> refreshFromRemote() async {
    try {
      return await _repository.sync();
    } catch (_) {
      return false;
    }
  }
}
