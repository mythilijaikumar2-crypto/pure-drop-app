import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import 'base_repository.dart';

class SettingsRepository extends BaseRepository {
  Future<Result<bool>> clearLocalData() async {
    try {
      await HiveService.clearAllData();
      return const Success(true);
    } catch (e, stack) {
      return Failure('Failed to clear local data: $e', e, stack);
    }
  }
}
