import '../core/constants/app_constants.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/user_model.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  Future<Result<UserModel?>> getSavedUser() async {
    try {
      final box = HiveService.getBox(AppConstants.authBoxName);
      final userJson = box.get('currentUser');
      final rememberMe = box.get('rememberMe', defaultValue: false);

      if (userJson != null && rememberMe == true) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(userJson);
        final user = UserModel.fromJson(map);
        return Success(user);
      }
      return const Success(null);
    } catch (e, stack) {
      return Failure('Failed to fetch saved session: $e', e, stack);
    }
  }

  Future<Result<bool>> saveUserSession(UserModel user, bool rememberMe) async {
    try {
      final box = HiveService.getBox(AppConstants.authBoxName);
      await box.put('currentUser', user.toJson());
      await box.put('rememberMe', rememberMe);
      return const Success(true);
    } catch (e, stack) {
      return Failure('Failed to save session: $e', e, stack);
    }
  }

  Future<Result<bool>> clearSession() async {
    try {
      final box = HiveService.getBox(AppConstants.authBoxName);
      await box.delete('currentUser');
      await box.delete('rememberMe');
      return const Success(true);
    } catch (e, stack) {
      return Failure('Failed to clear session: $e', e, stack);
    }
  }
}
