import 'package:redux/redux.dart';

import '../model/model.dart';
import 'export_svg_middleware.dart';
import 'local_storage_middleware.dart';

final List<Middleware<Model>> all_middleware = List<Middleware<Model>>.unmodifiable([
  local_storage_middleware,
  export_svg_main_middleware,
  export_svg_side_middleware,
]);
