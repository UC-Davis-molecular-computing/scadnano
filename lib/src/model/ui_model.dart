import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:redux/redux.dart';

import 'mouseover_data.dart';
import 'select_mode_state.dart';
import 'selectable.dart';
import '../dispatcher/actions_OLD.dart';
import '../dispatcher/local_storage.dart' as local_storage;
import '../dispatcher/actions.dart' as actions;

//TODO: add ability for user to ctrl+click (or some special key click) at offset on helix to set that helix's notion
// of DNA backbones rotation, which will then be displayed in the side view on all other offsets

import 'package:built_value/built_value.dart';

import 'selection_box.dart';

part 'ui_model.g.dart';

final DEFAULT_UIModelBuilder = UIModelBuilder()
  ..loaded_filename = default_filename()
  ..loaded_script_filename = default_script_filename()
  ..dragging = false
  ..mouseover_datas = ListBuilder<MouseoverData>()
  ..selection_box = DEFAULT_SelectionBoxBuilder
  ..selection_box_side_view = DEFAULT_SelectionBoxBuilder
  ..selectables_store = SelectablesStoreBuilder()
  ..show_dna = false
  ..show_editor = false
  ..show_mismatches = true
  ..changed_since_last_save = false
  ..select_mode_state = DEFAULT_SelectModeStateBuilder;

abstract class UIModel implements Built<UIModel, UIModelBuilder> {
  UIModel._();

  factory UIModel([void Function(UIModelBuilder) updates]) =>
      _$UIModel((u) => u..replace(DEFAULT_UIModelBuilder.build()));

  static Serializer<UIModel> get serializer => _$uIModelSerializer;

  /************************ end BuiltValue boilerplate ************************/

  SelectablesStore get selectables_store;

  String get loaded_filename;

  String get loaded_script_filename;

  bool get show_dna;

  bool get show_mismatches;

  bool get show_editor;

  bool get dragging;

  SelectionBox get selection_box;

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

UIModel ui_model_reducer(UIModel ui_model, action) {
  UIModel new_ui_model = ui_model.rebuild((u) => u
    ..select_mode_state = select_mode_state_reducer(ui_model.select_mode_state, action).toBuilder()
    ..show_dna = show_dna_reducer(ui_model.show_dna, action)
    ..show_mismatches = show_mismatches_reducer(ui_model.show_mismatches, action)
    ..show_editor = show_editor_reducer(ui_model.show_editor, action)
    ..mouseover_datas = mouseover_data_reducer(ui_model.mouseover_datas, action).toBuilder());

  return new_ui_model;
}

bool show_dna_reducer(bool prev_show, action) => action is actions.SetShowDNA ? action.show_dna : prev_show;

bool show_mismatches_reducer(bool prev_show, action) =>
    action is actions.SetShowMismatches ? action.show_mismatches : prev_show;

bool show_editor_reducer(bool prev_show, action) =>
    action is actions.SetShowEditor ? action.show_editor : prev_show;

Reducer<BuiltList<MouseoverData>> mouseover_data_reducer = combineReducers([
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataClear>(mouseover_data_clear_reducer),
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataUpdate>(mouseover_data_update_reducer),
]);

BuiltList<MouseoverData> mouseover_data_clear_reducer(_, action) => BuiltList<MouseoverData>();

BuiltList<MouseoverData> mouseover_data_update_reducer(_, actions.MouseoverDataUpdate action) =>
    action.mouseover_datas;
