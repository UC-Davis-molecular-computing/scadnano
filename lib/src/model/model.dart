import 'dart:core';


import 'ui_model.dart';
import 'dna_design.dart';

import 'package:built_value/built_value.dart';

part 'model.g.dart';


//TODO: replace calls to toBuilder with replace: https://github.com/google/built_value.dart/issues/424

final DEFAULT_ModelBuilder = ModelBuilder()
  ..ui_model = DEFAULT_UIModelBuilder
  ..error_message = ""
  ..editor_content = "";

abstract class Model implements Built<Model, ModelBuilder> {
  Model._();

  factory Model([void Function(ModelBuilder) updates]) =>
      _$Model((m) => m..replace(DEFAULT_ModelBuilder.build()));

  @nullable
  DNADesign get dna_design;

  UIModel get ui_model;

  String get error_message;

  String get editor_content;

  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    return this.dna_design.to_json_serializable(suppress_indent: false);
  }

  bool has_error() => error_message != null && error_message.length > 0;

  bool allow_main_view_pan() => ui_model.allow_pan();
}
