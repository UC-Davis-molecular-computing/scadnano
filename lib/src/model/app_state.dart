import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'dna_design.dart';
import 'app_ui_state.dart';
import 'undo_redo.dart';

part 'app_state.g.dart';

//TODO: normalize state tree (selectables_by_id is huge) and use connect to look up parts of state by id

final DEFAULT_AppStateBuilder = AppStateBuilder()
  ..ui_state = DEFAULT_AppUIStateBuilder
  ..error_message = ""
  ..editor_content = ""
  ..undo_redo = DEFAULT_UndoRedoBuilder;


abstract class AppState implements Built<AppState, AppStateBuilder> {
  AppState._();

  factory AppState([void Function(AppStateBuilder) updates]) =>
      _$AppState((m) => m..replace(DEFAULT_AppStateBuilder.build()));

  static Serializer<AppState> get serializer => _$appStateSerializer;

  /*********************************** end built_value boilerplate ***********************************/

  @nullable
  DNADesign get dna_design;

  AppUIState get ui_state;

  UndoRedo get undo_redo;

  String get error_message;

  String get editor_content;

  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map['dna_design'] = dna_design?.to_json_serializable(suppress_indent: false);
    map['ui_state'] = ui_state.toJson();
    map['error_message'] = error_message;
    map['editor_content'] = editor_content;
    return map;
  }

  bool has_error() => error_message != null && error_message.length > 0;
}
