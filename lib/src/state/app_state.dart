import 'package:built_collection/built_collection.dart';
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
  // This is a bit hacky. When we migrated to null safety, I didn't want to have to put
  // ! operators every time `app.state.design` is read, so I made `design` into a "true"
  // getter and let `maybe_design` be the nullable `Design`. There were a few bugs where some
  // code was checking whether `design` is null, which now didn't work (accessing the getter
  // raised an exception). But since almost all the code in this repo executes only when a
  // proper design is loaded, this is much more ergonomic. But we need to be careful in the
  // rare circumstances (loading the app initially, some testing) when `state.maybe_design`
  // might be null.
  Design? get maybe_design;

  Design get design {
    if (this.maybe_design != null) {
      return this.maybe_design!;
    } else {
      throw AssertionError("""\
You have discovered a bug in scadnano.

Please file a bug report at https://github.com/UC-Davis-molecular-computing/scadnano/issues
and include as much detail as possible, including any information currently displayed 
in the app. Thank you!""");
    }
  }

  AppUIState get ui_state;

  UndoRedo get undo_redo;

  String? get error_message;

  /// Maps helix indices to helix svg position.
  ///
  /// The helix svg position is the SVG position of the upper-left corner
  /// of the helix in the (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position as well, but svg_position will always be 2D.
  ///
  /// This is tricky to work into the design properly. The original implementation stored the SVG
  /// position as a field in each Helix. This allowed more targeted updates; the current implementation
  /// recomputes the Helix SVG positions every time the AppState updates, which is on almost every
  /// Action not going through an optimized Store. This is because the Helix SVG positions depend on data
  /// all throughout the AppState tree: helices themselves, and UI state such as invert_y and
  /// the set of selected helices (in case we are displaying only selected helices).
  /// But in a Design with 100 helices, it never seems to take more than 1 millisecond to calculate,
  /// so hopefully the waste is not really costing us performance noticably.
  ///
  /// However, this implementation, though wasteful, is less buggy. We previously had many bugs
  /// (e.g., https://github.com/UC-Davis-molecular-computing/scadnano/issues/677)
  /// that resulted from forgetting to update the Helix SVG positions when some aspect of the AppState
  /// changed that required them to be recomputed (e.g., moving helices to a new group). It was also more
  /// code to maintain; several reducers had to call util.helices_assign_svg.
  @memoized
  BuiltMap<int, Point<num>> get helix_idx_to_svg_position_map {
    // var sw = Stopwatch()..start();

    BuiltSet<int>? helix_idxs_to_calculate = ui_state.side_selected_helix_idxs;
    if (!ui_state.only_display_selected_helices) {
      helix_idxs_to_calculate = null; // let helices_assign_svg automatically set this to all helices
    }

    BuiltMap<int, Point<num>> ret = util
        .helices_assign_svg(design.geometry, ui_state.invert_y, design.helices, design.groups,
            helix_idxs_to_calculate: helix_idxs_to_calculate)
        .build();

    // print('${sw.elapsedMicroseconds} microseconds to calculate helix_idx_to_svg_position_map');

    return ret;
  }

  static void _initializeBuilder(AppStateBuilder b) {
    b.maybe_design = null;
    b.ui_state.replace(DEFAULT_AppUIState);
    b.error_message = constants.NO_DESIGN_MESSAGE_HTML;
    b.undo_redo = DEFAULT_UndoRedoBuilder;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    var design_to_store =
        this.maybe_design != null ? design.to_json_serializable(suppress_indent: false) : null;
    map['design'] = design_to_store;
    map['ui_state'] = ui_state.toJson();
    map['error_message'] = error_message;
    return map;
  }

  @memoized
  bool get has_error => error_message != null && error_message!.length > 0;

  /*********************************** begin built_value boilerplate ***********************************/

  AppState._();

  factory AppState(void Function(AppStateBuilder) updates) => _$AppState((m) => m..replace(DEFAULT_AppState));

  static Serializer<AppState> get serializer => _$appStateSerializer;

  @memoized
  int get hashCode;
}
