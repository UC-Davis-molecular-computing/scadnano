import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';
import 'package:scadnano/src/serializers.dart';

import 'mouseover_data.dart';
import 'select_mode_state.dart';
import 'selectable.dart';

import 'selection_box.dart';

part 'ui_model.g.dart';

final DEFAULT_UIModelBuilder = UIModelBuilder()
  ..loaded_filename = default_filename()
  ..loaded_script_filename = default_script_filename()
  ..dragging = false
  ..mouseover_datas = ListBuilder<MouseoverData>()
  ..selection_box_main_view = DEFAULT_SelectionBoxBuilder
  ..selection_box_side_view = DEFAULT_SelectionBoxBuilder
  ..selectables_store = SelectablesStoreBuilder()
  ..side_selected_helix_idxs = SetBuilder<int>()
  ..show_dna = false
  ..show_editor = false
  ..show_mismatches = true
  ..show_mouseover_rect = false
  ..changed_since_last_save = false
  ..select_mode_state = DEFAULT_SelectModeStateBuilder;

abstract class UIModel with BuiltJsonSerializable implements Built<UIModel, UIModelBuilder> {
  UIModel._();

  factory UIModel([void Function(UIModelBuilder) updates]) =>
      _$UIModel((u) => u..replace(DEFAULT_UIModelBuilder.build()));

  static Serializer<UIModel> get serializer => _$uIModelSerializer;

  /************************ end BuiltValue boilerplate ************************/

  /// For selected objects in main view
  SelectablesStore get selectables_store;

  /// Special case for helices, which can always be selected, but only in the side view.
  BuiltSet<int> get side_selected_helix_idxs;

  String get loaded_filename;

  String get loaded_script_filename;

  bool get show_dna;

  bool get show_mismatches;

  bool get show_editor;

  bool get show_mouseover_rect;

  bool get dragging;

  SelectionBox get selection_box_main_view;

  SelectionBox get selection_box_side_view;

  BuiltList<MouseoverData> get mouseover_datas;

  @nullable // null when Ctrl not pressed or mouse outside of side view
  Point<num> get mouse_svg_pos_side_view;

  SelectModeState get select_mode_state;

  /// Save button is enabled iff this is true
  bool get changed_since_last_save;

  bool allow_pan() => dragging;

}

const DEFAULT_FILENAME_NO_EXT = 'default_dna_filename';
const DEFAULT_SCRIPT_FILENAME_NO_EXT = 'default_script_filename';
const DEFAULT_EXT = 'dna';
const DEFAULT_SCRIPT_EXT = 'py';
const ALLOWED_EXTENSIONS_DESIGN = ['dna'];
const ALLOWED_EXTENSIONS_SCRIPT = ['py'];

default_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;

default_script_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;
