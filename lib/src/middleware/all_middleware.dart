import 'package:redux/redux.dart';

import 'load_file.dart';
import 'save_file.dart';
import '../model/model.dart';
import 'export_svg.dart';
import 'local_storage.dart';

final List<Middleware<Model>> all_middleware = List<Middleware<Model>>.unmodifiable([
  local_storage_middleware,
  export_svg_main_middleware,
  export_svg_side_middleware,
  save_file_middleware,
  load_file_middleware,
]);
