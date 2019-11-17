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
import '../util.dart' as util;
import '../built_intern.dart';

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
  ..selection_box_main_view = DEFAULT_SelectionBoxBuilder
  ..selection_box_side_view = DEFAULT_SelectionBoxBuilder
  ..selectables_store = SelectablesStoreBuilder()
  ..side_selected_helices = SetBuilder<int>()
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

  /// For selected objects in main view
  SelectablesStore get selectables_store;

  /// Special case for helices, which can always be selected, but only in the side view.
  BuiltSet<int> get side_selected_helices;

  String get loaded_filename;

  String get loaded_script_filename;

  bool get show_dna;

  bool get show_mismatches;

  bool get show_editor;

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

UIModel ui_model_reducer(UIModel ui_model, action) {
  UIModel new_ui_model = ui_model.rebuild((u) => u
    ..select_mode_state = select_mode_state_reducer(ui_model.select_mode_state, action).toBuilder()
    ..show_dna = show_dna_reducer(ui_model.show_dna, action)
    ..show_mismatches = show_mismatches_reducer(ui_model.show_mismatches, action)
    ..show_editor = show_editor_reducer(ui_model.show_editor, action)
    ..side_selected_helices =
        side_selected_helices_reducer(ui_model.side_selected_helices, action).toBuilder()
    ..mouse_svg_pos_side_view = side_view_mouse_svg_pos_reducer(ui_model.mouse_svg_pos_side_view, action)
    ..selection_box_main_view =
        main_view_selection_box_reducer(ui_model.selection_box_main_view, action).toBuilder()
    ..selection_box_side_view =
        side_view_selection_box_reducer(ui_model.selection_box_side_view, action).toBuilder()
    ..mouseover_datas = mouseover_data_reducer(ui_model.mouseover_datas, action).toBuilder());

  return new_ui_model;
}

bool show_dna_reducer(bool prev_show, action) => action is actions.SetShowDNA ? action.show_dna : prev_show;

bool show_mismatches_reducer(bool prev_show, action) =>
    action is actions.SetShowMismatches ? action.show_mismatches : prev_show;

bool show_editor_reducer(bool prev_show, action) =>
    action is actions.SetShowEditor ? action.show_editor : prev_show;

///////////////////////////////////////////////////////////////////////////////////////////////////
// side_selected_helices reducer

Reducer<BuiltSet<int>> side_selected_helices_reducer = combineReducers([
  TypedReducer<BuiltSet<int>, actions.HelicesSelectedToggle>(helices_selected_toggle_reducer),
  TypedReducer<BuiltSet<int>, actions.HelicesSelectedSelect>(helices_selected_select_reducer),
  TypedReducer<BuiltSet<int>, actions.HelicesSelectedClear>(helices_selected_clear_reducer),
]);

BuiltSet<int> helices_selected_toggle_reducer(BuiltSet<int> helices, actions.HelicesSelectedToggle action) {
  var helices_to_add = SetBuilder<int>();
  var helices_to_remove = SetBuilder<int>();
  for (var helix in action.helices) {
    if (helices.contains(helix)) {
      helices_to_remove.add(helix);
    } else {
      helices_to_add.add(helix);
    }
  }
  var new_helices = helices.toBuilder();
  new_helices.removeAll(helices_to_remove.build());
  new_helices.addAll(helices_to_add.build());
  return new_helices.build().intern();
}

BuiltSet<int> helices_selected_select_reducer(BuiltSet<int> helices, actions.HelicesSelectedSelect action) {
  var new_helices = helices.toBuilder();
  new_helices.addAll(action.helices);
  return new_helices.build().intern();
}

BuiltSet<int> helices_selected_clear_reducer(BuiltSet<int> helices, actions.HelicesSelectedClear action) {
  return BuiltSet<int>().intern();
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// mouseover_data reducer

Reducer<BuiltList<MouseoverData>> mouseover_data_reducer = combineReducers([
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataClear>(mouseover_data_clear_reducer),
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataUpdate>(mouseover_data_update_reducer),
]);

BuiltList<MouseoverData> mouseover_data_clear_reducer(_, action) => BuiltList<MouseoverData>();

BuiltList<MouseoverData> mouseover_data_update_reducer(_, actions.MouseoverDataUpdate action) =>
    action.mouseover_datas;

///////////////////////////////////////////////////////////////////////////////////////////////////
// side view mouse_svg_pos reducer

Reducer<Point<num>> side_view_mouse_svg_pos_reducer = combineReducers([
  TypedReducer<Point<num>, actions.SideViewMousePositionUpdate>(side_view_mouse_svg_pos_update_reducer),
  TypedReducer<Point<num>, actions.SideViewMousePositionRemove>(side_view_mouse_svg_pos_remove_reducer),
]);

Point<num> side_view_mouse_svg_pos_update_reducer(Point<num> _, actions.SideViewMousePositionUpdate action) =>
    action.point;

Point<num> side_view_mouse_svg_pos_remove_reducer(Point<num> _, actions.SideViewMousePositionRemove action) =>
    null;

///////////////////////////////////////////////////////////////////////////////////////////////////
// side view selection box reducer

Reducer<SelectionBox> side_view_selection_box_reducer = combineReducers([
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxRemove>(side_view_selection_box_remove_reducer),
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxSizeChanged>(
      side_view_selection_box_size_changed_reducer),
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxCreateToggling>(
      side_view_selection_box_create_toggling_reducer),
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxCreateSelecting>(
      side_view_selection_box_create_selecting_reducer),
]);

SelectionBox side_view_selection_box_remove_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxRemove action) =>
    DEFAULT_SelectionBox;

SelectionBox side_view_selection_box_size_changed_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxSizeChanged action) =>
    selection_box.rebuild((s) => s..current = action.point);

SelectionBox side_view_selection_box_create_toggling_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxCreateToggling action) =>
    selection_box.start_selection(action.point, true);

SelectionBox side_view_selection_box_create_selecting_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxCreateSelecting action) =>
    selection_box.start_selection(action.point, false);

///////////////////////////////////////////////////////////////////////////////////////////////////
// main view selection box reducer

Reducer<SelectionBox> main_view_selection_box_reducer = combineReducers([
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxRemove>(main_view_selection_box_remove_reducer),
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxSizeChanged>(
      main_view_selection_box_size_changed_reducer),
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxCreateToggling>(
      main_view_selection_box_create_toggling_reducer),
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxCreateSelecting>(
      main_view_selection_box_create_selecting_reducer),
]);

SelectionBox main_view_selection_box_remove_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxRemove action) =>
    DEFAULT_SelectionBox;

SelectionBox main_view_selection_box_size_changed_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxSizeChanged action) =>
//    selection_box.rebuild((s) => s..current = action.point);
    selection_box
        .rebuild((s) => s..current = util.transform_mouse_coord_to_svg_current_panzoom(action.point, true));

SelectionBox main_view_selection_box_create_toggling_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxCreateToggling action) =>
    selection_box.start_selection(action.point, true);

SelectionBox main_view_selection_box_create_selecting_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxCreateSelecting action) =>
    selection_box.start_selection(action.point, false);
