import 'package:redux/redux.dart';
import 'package:scadnano/src/middleware/edit_mode_allow_pan.dart';

import 'load_file.dart';
import 'save_file.dart';
import '../state/app_state.dart';
import 'export_svg.dart';
import 'local_storage.dart';
import 'throttle.dart';
import 'thunk.dart';
import 'helix_remove.dart';

final all_middleware = List<Middleware<AppState>>.unmodifiable([
  local_storage_middleware,
  export_svg_main_middleware,
  export_svg_side_middleware,
  save_file_middleware,
  load_file_middleware,
  throttle_middleware,
  thunk_middleware,
  edit_mode_allow_pan_middleware,
  helix_remove_middleware,
]);
