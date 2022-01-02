import 'package:built_collection/src/map.dart';
import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'design.dart';
import 'app_ui_state.dart';
import 'undo_redo.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

part 'app_state.g.dart';

final DEFAULT_AppState = AppStateBuilder().build();

abstract class AppState implements Built<AppState, AppStateBuilder> {
  @nullable
  Design get design;

  AppUIState get ui_state;

  UndoRedo get undo_redo;

  String get error_message;

  String get editor_content;

  /// Maps helix indices to helix svg position.
  ///
  /// The helix svg position is the SVG position of the upper-left corner
  /// of the helix in the (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position as well, but svg_position will always be 2D.
  @memoized
  BuiltMap<int, Point<num>> get helix_idx_to_svg_position_map {
    var sw = Stopwatch();
    sw.start();
    BuiltMap<int, Point<num>> ret = util
        .helices_assign_svg(design.geometry, ui_state.invert_y, design.helices, design.groups)
        .build();
    print('${sw.elapsedMicroseconds} microseconds to calculate helix_idx_to_svg_position_map');
    return ret;
  }

  static void _initializeBuilder(AppStateBuilder b) {
    b.design = null;
    b.ui_state.replace(DEFAULT_AppUIState);
    b.error_message = constants.NO_DESIGN_MESSAGE;
    b.editor_content = "";
    b.undo_redo = DEFAULT_UndoRedoBuilder;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map['design'] = design?.to_json_serializable(suppress_indent: false);
    map['ui_state'] = ui_state.toJson();
    map['error_message'] = error_message;
    map['editor_content'] = editor_content;
    return map;
  }

  @memoized
  bool get has_error => error_message != null && error_message.length > 0;

  /*********************************** begin built_value boilerplate ***********************************/

  AppState._();

  factory AppState([void Function(AppStateBuilder) updates]) =>
      _$AppState((m) => m..replace(DEFAULT_AppState));

  static Serializer<AppState> get serializer => _$appStateSerializer;

  @memoized
  int get hashCode;
}
