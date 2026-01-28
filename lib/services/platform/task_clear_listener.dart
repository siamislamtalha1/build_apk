import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';

class TaskClearListener {
  /// Determine if playback should stop when the app task is removed (swiped away)
  static Future<bool> shouldStopOnTaskClear() async {
    // Default to false (continue playing) if not specified,
    // or true if the user prefers "Stop on task clear"
    // The setting name in GlobalStrConsts is stopOnTaskClear.
    // Let's assume default is FALSE (legacy behavior usually stops, but modern players keep playing).
    // Actually, BloomeeMusicPlayer previous code forced stop.
    // If setting is true -> stop.
    // If setting is false -> don't stop.
    return await BloomeeDBService.getSettingBool(
            GlobalStrConsts.stopOnTaskClear) ??
        false;
  }
}
