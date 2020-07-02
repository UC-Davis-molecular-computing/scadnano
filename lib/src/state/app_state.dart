import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'dna_design.dart';
import 'app_ui_state.dart';
import 'undo_redo.dart';
import '../constants.dart' as constants;

part 'app_state.g.dart';

final DEFAULT_AppStateBuilder = AppStateBuilder();
final DEFAULT_AppState = DEFAULT_AppStateBuilder.build();

abstract class AppState implements Built<AppState, AppStateBuilder> {

  @nullable
  DNADesign get dna_design;

  AppUIState get ui_state;

  UndoRedo get undo_redo;

  String get error_message;

  String get editor_content;

  static void _initializeBuilder(AppStateBuilder b) {
    b.dna_design = null;
    b.ui_state = DEFAULT_AppUIStateBuilder;
    b.error_message = constants.NO_DNA_DESIGN_MESSAGE;
    b.editor_content = "";
    b.undo_redo = DEFAULT_UndoRedoBuilder;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map['dna_design'] = dna_design?.to_json_serializable(suppress_indent: false);
    map['ui_state'] = ui_state.toJson();
    map['error_message'] = error_message;
    map['editor_content'] = editor_content;
    return map;
  }

  bool has_error() => error_message != null && error_message.length > 0;

  /*********************************** begin built_value boilerplate ***********************************/

  AppState._();

  factory AppState([void Function(AppStateBuilder) updates]) =>
      _$AppState((m) => m..replace(DEFAULT_AppState));

  static Serializer<AppState> get serializer => _$appStateSerializer;

  @memoized
  int get hashCode;

}
