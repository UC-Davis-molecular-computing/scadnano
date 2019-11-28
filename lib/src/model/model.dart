import 'package:built_value/built_value.dart';

import 'dna_design.dart';
import 'ui_model.dart';
import 'undo_redo.dart';

part 'model.g.dart';

//TODO: replace calls to toBuilder with replace: https://github.com/google/built_value.dart/issues/424

final DEFAULT_ModelBuilder = ModelBuilder()
  ..ui_model = DEFAULT_UIModelBuilder
  ..error_message = ""
  ..editor_content = ""
  ..undo_redo = DEFAULT_UndoRedoBuilder;

abstract class Model implements Built<Model, ModelBuilder> {
  Model._();

  factory Model([void Function(ModelBuilder) updates]) => _$Model((m) => m..replace(DEFAULT_ModelBuilder.build()));

  @nullable
  DNADesign get dna_design;

  UndoRedo get undo_redo;

  UIModel get ui_model;

  String get error_message;

  String get editor_content;

  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    Map<String,dynamic> map = {};
    map['dna_design'] = dna_design.to_json_serializable(suppress_indent: false);
    map['ui_model'] = ui_model.toJson();
    map['error_message'] = error_message;
    map['editor_content'] = editor_content;
    return map;
  }

  bool has_error() => error_message != null && error_message.length > 0;

  bool allow_main_view_pan() => ui_model.allow_pan();
}
