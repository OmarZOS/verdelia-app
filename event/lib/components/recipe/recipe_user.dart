import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'recipe_cache.dart';
import 'recipe_state.dart';

class RecipeUserManager {
  final AppUserService _userService;
  final RecipeCache _cache;
  final RecipeState _state;

  RecipeUserManager({
    required AppUserService userService,
    required RecipeCache cache,
    required RecipeState state,
  })  : _userService = userService,
        _cache = cache,
        _state = state;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<AppUser?> getById(int id, {String? callerKey}) async {
    // Check cache first
    final cached = _cache.getUser(id);
    if (cached != null && cached.idAppUser != 0) {
      return cached;
    }

    _isLoading = true;

    try {
      final user = await _userService.getAppUser(id.toString());
      if (user != null && user.idAppUser != 0) {
        _cache.cacheUser(user);
        return user;
      }
      return null;
    } catch (e) {
      throw VerdeliaException('Failed to fetch user: $e');
    } finally {
      _isLoading = false;
    }
  }

  void clearCache() {
    _cache.clearUsers();
  }
}
