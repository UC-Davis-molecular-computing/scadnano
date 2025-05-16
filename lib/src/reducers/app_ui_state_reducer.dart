import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/reducers/design_reducer.dart';
import 'package:scadnano/src/reducers/strands_copy_info_reducer.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/base_pair_display_type.dart';
import 'package:scadnano/src/state/dna_assign_options.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/copy_info.dart';
import 'package:scadnano/src/state/substrand.dart';
import 'package:scadnano/src/util.dart';
import '../reducers/context_menu_reducer.dart';
import '../state/example_designs.dart';
import '../state/grid_position.dart';
import '../state/local_storage_design_choice.dart';

import '../state/app_state.dart';
import '../state/app_ui_state.dart';
import '../state/app_ui_state_storables.dart';
import '../state/mouseover_data.dart';
import '../reducers/select_mode_state_reducer.dart';
import '../reducers/edit_modes_reducer.dart';
import '../actions/actions.dart' as actions;
import 'dialog_reducer.dart';
import 'domains_move_reducer.dart';
import 'strand_creation_reducer.dart';
import 'strands_move_reducer.dart';
import 'util_reducer.dart';
import 'selection_reducer.dart';
import 'mouseover_datas_reducer.dart';

////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui state local reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

AppUIState ui_state_local_reducer(AppUIState ui_state, action) => ui_state.rebuild(
  (u) =>
      u
        ..storables.replace(app_ui_state_storable_local_reducer(ui_state.storables, action))
        ..changed_since_last_save = changed_since_last_save_reducer(ui_state.changed_since_last_save, action)
        ..last_mod_5p =
            TypedReducer<Modification5Prime?, actions.ModificationAdd>(last_mod_5p_modification_add_reducer)(
              ui_state.last_mod_5p,
              action,
            )?.toBuilder()
        ..last_mod_3p =
            TypedReducer<Modification3Prime?, actions.ModificationAdd>(last_mod_3p_modification_add_reducer)(
              ui_state.last_mod_3p,
              action,
            )?.toBuilder()
        ..last_mod_int =
            TypedReducer<ModificationInternal?, actions.ModificationAdd>(
              last_mod_int_modification_add_reducer,
            )(ui_state.last_mod_int, action)?.toBuilder()
        ..selection_rope = optimized_selection_rope_reducer(ui_state.selection_rope, action)?.toBuilder()
        ..drawing_potential_crossover = drawing_potential_crossover_reducer(
          ui_state.drawing_potential_crossover,
          action,
        )
        ..dna_ends_are_moving = moving_dna_ends_reducer(ui_state.dna_ends_are_moving, action)
        ..slice_bar_is_moving = slice_bar_is_moving_reducer(ui_state.slice_bar_is_moving, action)
        ..helix_group_is_moving = helix_group_is_moving_reducer(ui_state.helix_group_is_moving, action)
        ..show_load_dialog = load_dialog_reducer(ui_state.show_load_dialog, action)
        ..strands_move = strands_move_local_reducer(ui_state.strands_move, action)?.toBuilder()
        ..domains_move = domains_move_local_reducer(ui_state.domains_move, action)?.toBuilder()
        ..side_view_grid_position_mouse_cursor =
            side_view_mouse_grid_pos_reducer(
              ui_state.side_view_grid_position_mouse_cursor,
              action,
            )?.toBuilder()
        ..side_view_position_mouse_cursor = side_view_position_mouse_cursor_reducer(
          ui_state.side_view_position_mouse_cursor,
          action,
        )
        ..context_menu = context_menu_reducer(ui_state.context_menu, action)?.toBuilder()
        ..dialog = dialog_reducer(ui_state.dialog, action)?.toBuilder()
        ..color_picker_strand = color_picker_strand_reducer(ui_state.color_picker_strand, action)?.toBuilder()
        ..color_picker_substrand = color_picker_substrand_reducer(
          ui_state.color_picker_substrand,
          action,
        ) //?.toBuilder()
        ..helix_change_apply_to_all = helix_change_apply_to_all_reducer(
          ui_state.helix_change_apply_to_all,
          action,
        )
        ..example_designs.replace(
          TypedReducer<ExampleDesigns, actions.ExampleDesignsLoad>(example_designs_idx_set_reducer)(
            ui_state.example_designs,
            action,
          ),
        )
        ..dna_assign_options.replace(
          TypedReducer<DNAAssignOptions, actions.AssignDNA>(dna_assign_options_reducer)(
            ui_state.dna_assign_options,
            action,
          ),
        )
        ..mouseover_datas.replace(mouseover_data_reducer(ui_state.mouseover_datas, action))
        ..dna_sequence_png_uri = dna_sequence_png_uri_reducer(ui_state.dna_sequence_png_uri, action)
        ..dna_sequence_png_horizontal_offset = dna_sequence_horizontal_offset_reducer(
          ui_state.dna_sequence_png_horizontal_offset,
          action,
        )
        ..dna_sequence_png_vertical_offset = dna_sequence_vertical_offset_reducer(
          ui_state.dna_sequence_png_vertical_offset,
          action,
        )
        ..export_svg_action_delayed_for_png_cache =
            export_svg_action_delayed_for_png_cache_reducer(
              ui_state.export_svg_action_delayed_for_png_cache,
              action,
            )?.toBuilder()
        ..is_zoom_above_threshold = is_zoom_above_threshold_reducer(ui_state.is_zoom_above_threshold, action),
);

bool helix_change_apply_to_all_reducer(bool helix_change_apply_to_all, action) {
  if (action is actions.HelixMajorTickDistanceChange ||
      action is actions.HelixMajorTicksChange ||
      action is actions.HelixOffsetChange ||
      action is actions.HelixMajorTickPeriodicDistancesChange) {
    return false;
  } else if (action is actions.HelixMajorTickDistanceChangeAll ||
      action is actions.HelixMajorTicksChangeAll ||
      action is actions.HelixOffsetChangeAll ||
      action is actions.HelixMajorTickPeriodicDistancesChangeAll) {
    return true;
  } else {
    return helix_change_apply_to_all;
  }
}

Reducer<bool> drawing_potential_crossover_reducer = combineReducers([
  TypedReducer<bool, actions.PotentialCrossoverCreate>(potential_crossover_create_app_ui_state_reducer),
  TypedReducer<bool, actions.PotentialCrossoverRemove>(potential_crossover_remove_app_ui_state_reducer),
]);

Reducer<bool> moving_dna_ends_reducer = combineReducers([
  TypedReducer<bool, actions.DNAEndsMoveStart>(dna_ends_move_start_app_ui_state_reducer),
  TypedReducer<bool, actions.DNAEndsMoveStop>(dna_ends_move_stop_app_ui_state_reducer),
  TypedReducer<bool, actions.DNAExtensionsMoveStart>(dna_extensions_move_start_app_ui_state_reducer),
  TypedReducer<bool, actions.DNAExtensionsMoveStop>(dna_extensions_move_stop_app_ui_state_reducer),
]);

Reducer<bool> slice_bar_is_moving_reducer = combineReducers([
  TypedReducer<bool, actions.SliceBarMoveStart>(slice_bar_move_start_app_ui_state_reducer),
  TypedReducer<bool, actions.SliceBarMoveStop>(slice_bar_move_stop_app_ui_state_reducer),
]);

Reducer<bool> helix_group_is_moving_reducer = combineReducers([
  TypedReducer<bool, actions.HelixGroupMoveStart>(helix_group_move_start_app_ui_state_reducer),
  TypedReducer<bool, actions.HelixGroupMoveStop>(helix_group_move_stop_app_ui_state_reducer),
]);

Reducer<bool> load_dialog_reducer = combineReducers([
  TypedReducer<bool, actions.LoadingDialogShow>(load_dialog_show_app_ui_state_reducer),
  TypedReducer<bool, actions.LoadingDialogHide>(load_dialog_hide_app_ui_state_reducer),
]);

bool potential_crossover_create_app_ui_state_reducer(bool _, actions.PotentialCrossoverCreate action) => true;

bool potential_crossover_remove_app_ui_state_reducer(bool _, actions.PotentialCrossoverRemove action) =>
    false;

bool dna_ends_move_start_app_ui_state_reducer(bool _, actions.DNAEndsMoveStart action) => true;

bool dna_ends_move_stop_app_ui_state_reducer(bool _, actions.DNAEndsMoveStop action) => false;

bool dna_extensions_move_start_app_ui_state_reducer(bool _, actions.DNAExtensionsMoveStart action) => true;

bool dna_extensions_move_stop_app_ui_state_reducer(bool _, actions.DNAExtensionsMoveStop action) => false;

bool slice_bar_move_start_app_ui_state_reducer(bool _, actions.SliceBarMoveStart action) => true;

bool slice_bar_move_stop_app_ui_state_reducer(bool _, actions.SliceBarMoveStop action) => false;

bool helix_group_move_start_app_ui_state_reducer(bool _, actions.HelixGroupMoveStart action) => true;

bool helix_group_move_stop_app_ui_state_reducer(bool _, actions.HelixGroupMoveStop action) => false;

bool show_dna_reducer(bool _, actions.ShowDNASet action) => action.show;

bool load_dialog_show_app_ui_state_reducer(bool _, actions.LoadingDialogShow action) => true;

bool load_dialog_hide_app_ui_state_reducer(bool _, actions.LoadingDialogHide action) => false;

bool show_strand_names_reducer(bool _, actions.ShowStrandNamesSet action) => action.show;

bool show_strand_labels_reducer(bool _, actions.ShowStrandLabelsSet action) => action.show;

bool show_domain_names_reducer(bool _, actions.ShowDomainNamesSet action) => action.show;

bool show_domain_labels_reducer(bool _, actions.ShowDomainLabelsSet action) => action.show;

bool show_modifications_reducer(bool _, actions.ShowModificationsSet action) => action.show;

bool modification_display_connector_reducer(bool _, actions.SetModificationDisplayConnector action) =>
    action.show;

double modification_font_size_reducer(double _, actions.ModificationFontSizeSet action) => action.font_size;

double zoom_speed_reducer(double _, actions.ZoomSpeedSet action) => action.speed;

double strand_name_font_size_reducer(double _, actions.StrandNameFontSizeSet action) => action.font_size;

double domain_name_font_size_reducer(double _, actions.DomainNameFontSizeSet action) => action.font_size;

double strand_label_font_size_reducer(double _, actions.StrandLabelFontSizeSet action) => action.font_size;

double domain_label_font_size_reducer(double _, actions.DomainLabelFontSizeSet action) => action.font_size;

double major_tick_offset_font_size_reducer(double _, actions.MajorTickOffsetFontSizeSet action) =>
    action.font_size;

double major_tick_width_font_size_reducer(double _, actions.MajorTickWidthFontSizeSet action) =>
    action.font_size;

bool show_mismatches_reducer(bool _, actions.ShowMismatchesSet action) => action.show;

bool show_domain_name_mismatches_reducer(bool _, actions.ShowDomainNameMismatchesSet action) =>
    action.show_domain_name_mismatches;

bool show_unpaired_insertion_deletions_reducer(bool _, actions.ShowUnpairedInsertionDeletionsSet action) =>
    action.show_unpaired_insertion_deletions;

bool invert_y_reducer(bool _, actions.InvertYSet action) => action.invert_y;

bool dynamic_helix_update_reducer(bool _, actions.DynamicHelixUpdateSet action) =>
    action.dynamically_update_helices;

bool warn_on_exit_if_unsaved_reducer(bool _, actions.WarnOnExitIfUnsavedSet action) => action.warn;

bool show_helix_circles_main_view_reducer(bool _, actions.ShowHelixCirclesMainViewSet action) =>
    action.show_helix_circles_main_view;

bool show_helix_components_main_view_reducer(bool _, actions.ShowHelixComponentsMainViewSet action) =>
    action.show_helix_components;

bool show_edit_mode_menu_reducer(bool previous_show, actions.ShowEditMenuToggle action) => !previous_show;

bool show_grid_coordinates_side_view_reducer(bool _, actions.ShowGridCoordinatesSideViewSet action) =>
    action.show_grid_coordinates_side_view;

bool show_helices_axis_arrows_reducer(bool _, actions.ShowAxisArrowsSet action) =>
    action.show_helices_axis_arrows;

bool show_loopout_extension_length_reducer(bool _, actions.ShowLoopoutExtensionLengthSet action) =>
    action.show_length;

bool show_slice_bar_reducer(bool _, actions.ShowSliceBarSet action) => action.show;

int? slice_bar_offset_set_reducer(int? _, actions.SliceBarOffsetSet action) => action.offset;

bool disable_png_caching_dna_sequences_reducer(bool _, actions.DisablePngCachingDnaSequencesSet action) =>
    action.disable_png_caching_dna_sequences;

bool retain_strand_color_on_selection_reducer(bool _, actions.RetainStrandColorOnSelectionSet action) =>
    action.retain_strand_color_on_selection;

bool display_reverse_DNA_right_side_up_reducer(bool _, actions.DisplayReverseDNARightSideUpSet action) =>
    action.display_reverse_DNA_right_side_up;

bool display_base_offsets_of_major_ticks_reducer(bool _, actions.DisplayMajorTicksOffsetsSet action) =>
    action.show;

bool display_base_offsets_of_major_ticks_only_first_helix_reducer(
  bool _,
  actions.SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix action,
) => action.show;

bool display_major_tick_widths_all_helices_reducer(
  bool _,
  actions.SetDisplayMajorTickWidthsAllHelices action,
) => action.show;

BasePairDisplayType base_pair_type_idx_reducer(
  BasePairDisplayType set_base_pair_display,
  actions.BasePairTypeSet action,
) => BasePairDisplayType.types[action.selected_idx];

bool show_base_pair_lines_reducer(bool _, actions.ShowBasePairLinesSet action) => action.show_base_pair_lines;

bool export_base_pair_lines_if_other_strand_not_selected_reducer(
  bool _,
  actions.ExportBasePairLinesIfOtherStrandNotSelectedSet action,
) => action.export_base_pair_lines_if_other_strand_not_selected;

bool show_base_pair_lines_with_mismatches_reducer(
  bool _,
  actions.ShowBasePairLinesWithMismatchesSet action,
) => action.show_base_pair_lines_with_mismatches;

bool export_svg_text_separately_reducer(bool _, actions.ExportSvgTextSeparatelySet action) =>
    action.export_svg_text_separately;

bool ox_export_only_selected_strands_reducer(bool _, actions.OxExportOnlySelectedStrandsSet action) =>
    action.only_selected;

bool display_major_tick_widths_reducer(bool _, actions.SetDisplayMajorTickWidths action) => action.show;

bool strand_paste_keep_color_reducer(bool _, actions.StrandPasteKeepColorSet action) => action.keep;

bool center_on_load_reducer(bool _, actions.AutofitSet action) => action.autofit;

bool show_oxview_reducer(bool _, actions.OxviewShowSet action) => action.show;

bool show_mouseover_data_set_reducer(bool _, actions.ShowMouseoverDataSet action) => action.show;

bool only_display_selected_helices_reducer(bool _, actions.SetOnlyDisplaySelectedHelices action) =>
    action.only_display_selected_helices;

bool default_crossover_type_scaffold_for_setting_helix_rolls_reducer(
  bool _,
  actions.DefaultCrossoverTypeForSettingHelixRollsSet action,
) => action.scaffold;

bool default_crossover_type_staple_for_setting_helix_rolls_reducer(
  bool _,
  actions.DefaultCrossoverTypeForSettingHelixRollsSet action,
) => action.staple;

DNAAssignOptions dna_assign_options_reducer(DNAAssignOptions _, actions.AssignDNA action) =>
    action.dna_assign_options;

Reducer<bool> show_mousever_rect_reducer = combineReducers([
  TypedReducer<bool, actions.ShowMouseoverRectSet>(show_mouseover_rect_set_reducer),
  TypedReducer<bool, actions.ShowMouseoverRectToggle>(show_mouseover_rect_toggle_reducer),
]);

bool show_mouseover_rect_set_reducer(bool prev_show, actions.ShowMouseoverRectSet action) => action.show;

bool show_mouseover_rect_toggle_reducer(bool prev_show, actions.ShowMouseoverRectToggle action) => !prev_show;

Reducer<bool> changed_since_last_save_reducer = combineReducers([
  TypedReducer<bool, actions.UndoableAction>(changed_since_last_save_undoable_action_reducer),
  TypedReducer<bool, actions.SaveDNAFile>(changed_since_last_save_just_saved_reducer),
]);

LocalStorageDesignChoice local_storage_design_choice_reducer(
  LocalStorageDesignChoice _,
  actions.LocalStorageDesignChoiceSet action,
) => action.choice.period_seconds > 0 ? action.choice : action.choice.change_period(1);

bool clear_helix_selection_when_loading_new_design_set_reducer(
  bool _,
  actions.ClearHelixSelectionWhenLoadingNewDesignSet action,
) => action.clear;

bool changed_since_last_save_undoable_action_reducer(
  bool changed_since_last_save,
  actions.UndoableAction action,
) => true;

bool changed_since_last_save_just_saved_reducer(bool changed_since_last_save, actions.SaveDNAFile action) =>
    false;

Reducer<BuiltList<MouseoverData>> mouseover_data_reducer = combineReducers([
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataClear>(mouseover_data_clear_reducer),
]);

ExampleDesigns example_designs_idx_set_reducer(
  ExampleDesigns example_designs,
  actions.ExampleDesignsLoad action,
) => example_designs.rebuild((b) => b..selected_idx = action.selected_idx);

///////////////////////////////////////////////////////////////////////////////////////////////////
// storables global reducer

AppUIStateStorables app_ui_state_storable_global_reducer(
  AppUIStateStorables storables,
  AppState state,
  action,
) {
  // forgot why we made special case for this, but it seems appropriate since it's updating the whole
  // storables object and not just slices
  if (action is actions.SetAppUIStateStorable) {
    AppUIStateStorables storables = action.storables;
    if (state.maybe_design != null &&
        !state.design.groups.containsKey(action.storables.displayed_group_name)) {
      // if displayed_group_name does not exist, must pick a new one
      storables = storables.rebuild((b) => b..displayed_group_name = state.design.groups.keys.first);
    }
    // It's possible the the slice bar being set is not valid.
    int? slice_bar_offset = 0;
    if (state.maybe_design != null) {
      var helices_in_first_group = state.design.helices_in_group(state.design.groups.keys.first).values;
      if (helices_in_first_group.isNotEmpty) {
        slice_bar_offset = bounded_offset_in_helices_group(
          storables.slice_bar_offset,
          helices_in_first_group,
        );
      }
    }
    storables = storables.rebuild((b) => b..slice_bar_offset = slice_bar_offset);
    return storables;
  }

  return storables.rebuild(
    (b) =>
        b
          ..side_selected_helix_idxs.replace(
            side_selected_helices_global_reducer(storables.side_selected_helix_idxs, state, action),
          )
          ..displayed_group_name = TypedGlobalReducer<String, AppState, actions.GroupRemove>(
            displayed_group_name_group_remove_reducer,
          )(storables.displayed_group_name, state, action)
          ..slice_bar_offset = slice_bar_offset_global_reducer(storables.slice_bar_offset, state, action),
  );
}

// If we remove the current displayed group, we've got to pick something else to display next
String displayed_group_name_group_remove_reducer(String _, AppState state, actions.GroupRemove action) {
  String name = action.name;
  String first = state.design.groups.keys.first;
  String last = state.design.groups.keys.last;
  return name != first ? first : last;
}

GlobalReducer<int?, AppState> slice_bar_offset_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<int?, AppState, actions.ShowSliceBarSet>(slice_bar_offset_show_slice_bar_set_reducer),
  TypedGlobalReducer<int?, AppState, actions.GroupDisplayedChange>(
    slice_bar_offset_group_displayed_change_reducer,
  ),
  TypedGlobalReducer<int?, AppState, actions.GroupRemove>(slice_bar_offset_group_remove_reducer),
  TypedGlobalReducer<int?, AppState, actions.HelixOffsetChange>(slice_bar_offset_helix_offset_change_reducer),
  TypedGlobalReducer<int?, AppState, actions.HelixOffsetChangeAll>(
    slice_bar_offset_helix_offset_change_all_reducer,
  ),
]);

int? slice_bar_offset_show_slice_bar_set_reducer(
  int? offset,
  AppState state,
  actions.ShowSliceBarSet action,
) {
  if (action.show) {
    return bounded_offset_in_helices_group(
      offset,
      state.design.helices_in_group(state.ui_state.displayed_group_name).values,
    );
  } else {
    // Don't change slice bar position if user hides it. Saves value for when next time user wants to display.
    return offset;
  }
}

int? slice_bar_offset_group_displayed_change_reducer(
  int? offset,
  AppState state,
  actions.GroupDisplayedChange action,
) {
  return bounded_offset_in_helices_group(offset, state.design.helices_in_group(action.group_name).values);
}

int? slice_bar_offset_group_remove_reducer(int? offset, AppState state, actions.GroupRemove action) {
  String new_group_name = displayed_group_name_group_remove_reducer("NO GROUP NAME DISPLAYED", state, action);
  return bounded_offset_in_helices_group(offset, state.design.helices_in_group(new_group_name).values);
}

int? slice_bar_offset_helix_offset_change_reducer(
  int? offset,
  AppState state,
  actions.HelixOffsetChange action,
) {
  var new_design = design_global_reducer(state.design, state, action)!;
  return bounded_offset_in_helices_group(
    offset,
    new_design.helices_in_group(state.ui_state.displayed_group_name).values,
  );
}

int? slice_bar_offset_helix_offset_change_all_reducer(
  int? offset,
  AppState state,
  actions.HelixOffsetChangeAll action,
) {
  var new_design = design_global_reducer(state.design, state, action)!;
  return bounded_offset_in_helices_group(
    offset,
    new_design.helices_in_group(state.ui_state.displayed_group_name).values,
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// storables local reducer
AppUIStateStorables app_ui_state_storable_local_reducer(AppUIStateStorables storables, action) {
  return storables.rebuild(
    (b) =>
        b
          ..side_selected_helix_idxs.replace(
            side_selected_helices_reducer(storables.side_selected_helix_idxs, action),
          )
          ..displayed_group_name = displayed_group_name_reducer(storables.displayed_group_name, action)
          ..select_mode_state.replace(select_mode_state_reducer(storables.select_mode_state, action))
          ..edit_modes.replace(edit_modes_reducer(storables.edit_modes, action))
          ..show_dna = TypedReducer<bool, actions.ShowDNASet>(show_dna_reducer)(storables.show_dna, action)
          ..show_strand_names = TypedReducer<bool, actions.ShowStrandNamesSet>(show_strand_names_reducer)(
            storables.show_strand_names,
            action,
          )
          ..show_strand_labels = TypedReducer<bool, actions.ShowStrandLabelsSet>(show_strand_labels_reducer)(
            storables.show_strand_labels,
            action,
          )
          ..strand_name_font_size = TypedReducer<double, actions.StrandNameFontSizeSet>(
            strand_name_font_size_reducer,
          )(storables.strand_name_font_size, action)
          ..strand_label_font_size = TypedReducer<double, actions.StrandLabelFontSizeSet>(
            strand_label_font_size_reducer,
          )(storables.strand_label_font_size, action)
          ..show_domain_names = TypedReducer<bool, actions.ShowDomainNamesSet>(show_domain_names_reducer)(
            storables.show_domain_names,
            action,
          )
          ..domain_name_font_size = TypedReducer<double, actions.DomainNameFontSizeSet>(
            domain_name_font_size_reducer,
          )(storables.domain_name_font_size, action)
          ..show_domain_labels = TypedReducer<bool, actions.ShowDomainLabelsSet>(show_domain_labels_reducer)(
            storables.show_domain_labels,
            action,
          )
          ..domain_label_font_size = TypedReducer<double, actions.DomainLabelFontSizeSet>(
            domain_label_font_size_reducer,
          )(storables.domain_label_font_size, action)
          ..show_modifications = TypedReducer<bool, actions.ShowModificationsSet>(show_modifications_reducer)(
            storables.show_modifications,
            action,
          )
          ..modification_display_connector = TypedReducer<bool, actions.SetModificationDisplayConnector>(
            modification_display_connector_reducer,
          )(storables.modification_display_connector, action)
          ..modification_font_size = TypedReducer<double, actions.ModificationFontSizeSet>(
            modification_font_size_reducer,
          )(storables.modification_font_size, action)
          ..zoom_speed = TypedReducer<double, actions.ZoomSpeedSet>(zoom_speed_reducer)(
            storables.zoom_speed,
            action,
          )
          ..major_tick_offset_font_size = TypedReducer<double, actions.MajorTickOffsetFontSizeSet>(
            major_tick_offset_font_size_reducer,
          )(storables.major_tick_offset_font_size, action)
          ..major_tick_width_font_size = TypedReducer<double, actions.MajorTickWidthFontSizeSet>(
            major_tick_width_font_size_reducer,
          )(storables.major_tick_width_font_size, action)
          ..show_mismatches = TypedReducer<bool, actions.ShowMismatchesSet>(show_mismatches_reducer)(
            storables.show_mismatches,
            action,
          )
          ..show_domain_name_mismatches = TypedReducer<bool, actions.ShowDomainNameMismatchesSet>(
            show_domain_name_mismatches_reducer,
          )(storables.show_domain_name_mismatches, action)
          ..show_unpaired_insertion_deletions = TypedReducer<bool, actions.ShowUnpairedInsertionDeletionsSet>(
            show_unpaired_insertion_deletions_reducer,
          )(storables.show_unpaired_insertion_deletions, action)
          ..invert_y = TypedReducer<bool, actions.InvertYSet>(invert_y_reducer)(storables.invert_y, action)
          ..dynamically_update_helices = TypedReducer<bool, actions.DynamicHelixUpdateSet>(
            dynamic_helix_update_reducer,
          )(storables.dynamically_update_helices, action)
          ..warn_on_exit_if_unsaved = TypedReducer<bool, actions.WarnOnExitIfUnsavedSet>(
            warn_on_exit_if_unsaved_reducer,
          )(storables.warn_on_exit_if_unsaved, action)
          ..show_helix_circles_main_view = TypedReducer<bool, actions.ShowHelixCirclesMainViewSet>(
            show_helix_circles_main_view_reducer,
          )(storables.show_helix_circles_main_view, action)
          ..show_helix_components_main_view = TypedReducer<bool, actions.ShowHelixComponentsMainViewSet>(
            show_helix_components_main_view_reducer,
          )(storables.show_helix_components_main_view, action)
          ..show_edit_mode_menu = TypedReducer<bool, actions.ShowEditMenuToggle>(show_edit_mode_menu_reducer)(
            storables.show_edit_mode_menu,
            action,
          )
          ..show_grid_coordinates_side_view = TypedReducer<bool, actions.ShowGridCoordinatesSideViewSet>(
            show_grid_coordinates_side_view_reducer,
          )(storables.show_grid_coordinates_side_view, action)
          ..show_helices_axis_arrows = TypedReducer<bool, actions.ShowAxisArrowsSet>(
            show_helices_axis_arrows_reducer,
          )(storables.show_helices_axis_arrows, action)
          ..show_loopout_extension_length = TypedReducer<bool, actions.ShowLoopoutExtensionLengthSet>(
            show_loopout_extension_length_reducer,
          )(storables.show_loopout_extension_length, action)
          ..show_slice_bar = TypedReducer<bool, actions.ShowSliceBarSet>(show_slice_bar_reducer)(
            storables.show_slice_bar,
            action,
          )
          ..slice_bar_offset = TypedReducer<int?, actions.SliceBarOffsetSet>(slice_bar_offset_set_reducer)(
            storables.slice_bar_offset,
            action,
          )
          ..disable_png_caching_dna_sequences = TypedReducer<bool, actions.DisablePngCachingDnaSequencesSet>(
            disable_png_caching_dna_sequences_reducer,
          )(storables.disable_png_caching_dna_sequences, action)
          ..retain_strand_color_on_selection = TypedReducer<bool, actions.RetainStrandColorOnSelectionSet>(
            retain_strand_color_on_selection_reducer,
          )(storables.retain_strand_color_on_selection, action)
          ..display_reverse_DNA_right_side_up = TypedReducer<bool, actions.DisplayReverseDNARightSideUpSet>(
            display_reverse_DNA_right_side_up_reducer,
          )(storables.display_reverse_DNA_right_side_up, action)
          ..local_storage_design_choice =
              TypedReducer<LocalStorageDesignChoice, actions.LocalStorageDesignChoiceSet>(
                local_storage_design_choice_reducer,
              )(storables.local_storage_design_choice, action).toBuilder()
          ..clear_helix_selection_when_loading_new_design =
              TypedReducer<bool, actions.ClearHelixSelectionWhenLoadingNewDesignSet>(
                clear_helix_selection_when_loading_new_design_set_reducer,
              )(storables.clear_helix_selection_when_loading_new_design, action)
          ..strand_paste_keep_color = TypedReducer<bool, actions.StrandPasteKeepColorSet>(
            strand_paste_keep_color_reducer,
          )(storables.strand_paste_keep_color, action)
          ..autofit = TypedReducer<bool, actions.AutofitSet>(center_on_load_reducer)(
            storables.autofit,
            action,
          )
          ..show_oxview = TypedReducer<bool, actions.OxviewShowSet>(show_oxview_reducer)(
            storables.show_oxview,
            action,
          )
          ..display_base_offsets_of_major_ticks = TypedReducer<bool, actions.DisplayMajorTicksOffsetsSet>(
            display_base_offsets_of_major_ticks_reducer,
          )(storables.display_base_offsets_of_major_ticks, action)
          ..display_base_offsets_of_major_ticks_only_first_helix =
              TypedReducer<bool, actions.SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix>(
                display_base_offsets_of_major_ticks_only_first_helix_reducer,
              )(storables.display_base_offsets_of_major_ticks_only_first_helix, action)
          ..display_major_tick_widths = TypedReducer<bool, actions.SetDisplayMajorTickWidths>(
            display_major_tick_widths_reducer,
          )(storables.display_major_tick_widths, action)
          ..display_major_tick_widths_all_helices =
              TypedReducer<bool, actions.SetDisplayMajorTickWidthsAllHelices>(
                display_major_tick_widths_all_helices_reducer,
              )(storables.display_major_tick_widths_all_helices, action)
          ..base_pair_display_type = TypedReducer<BasePairDisplayType, actions.BasePairTypeSet>(
            base_pair_type_idx_reducer,
          )(storables.base_pair_display_type, action)
          ..show_base_pair_lines = TypedReducer<bool, actions.ShowBasePairLinesSet>(
            show_base_pair_lines_reducer,
          )(storables.show_base_pair_lines, action)
          ..export_base_pair_lines_if_other_strand_not_selected =
              TypedReducer<bool, actions.ExportBasePairLinesIfOtherStrandNotSelectedSet>(
                export_base_pair_lines_if_other_strand_not_selected_reducer,
              )(storables.export_base_pair_lines_if_other_strand_not_selected, action)
          ..show_base_pair_lines_with_mismatches =
              TypedReducer<bool, actions.ShowBasePairLinesWithMismatchesSet>(
                show_base_pair_lines_with_mismatches_reducer,
              )(storables.show_base_pair_lines_with_mismatches, action)
          ..export_svg_text_separately = TypedReducer<bool, actions.ExportSvgTextSeparatelySet>(
            export_svg_text_separately_reducer,
          )(storables.export_svg_text_separately, action)
          ..ox_export_only_selected_strands = TypedReducer<bool, actions.OxExportOnlySelectedStrandsSet>(
            ox_export_only_selected_strands_reducer,
          )(storables.ox_export_only_selected_strands, action)
          ..only_display_selected_helices = TypedReducer<bool, actions.SetOnlyDisplaySelectedHelices>(
            only_display_selected_helices_reducer,
          )(storables.only_display_selected_helices, action)
          ..default_crossover_type_scaffold_for_setting_helix_rolls =
              TypedReducer<bool, actions.DefaultCrossoverTypeForSettingHelixRollsSet>(
                default_crossover_type_scaffold_for_setting_helix_rolls_reducer,
              )(storables.default_crossover_type_scaffold_for_setting_helix_rolls, action)
          ..default_crossover_type_staple_for_setting_helix_rolls =
              TypedReducer<bool, actions.DefaultCrossoverTypeForSettingHelixRollsSet>(
                default_crossover_type_staple_for_setting_helix_rolls_reducer,
              )(storables.default_crossover_type_staple_for_setting_helix_rolls, action)
          ..show_mouseover_data = TypedReducer<bool, actions.ShowMouseoverDataSet>(
            show_mouseover_data_set_reducer,
          )(storables.show_mouseover_data, action)
          ..selection_box_intersection = TypedReducer<bool, actions.SelectionBoxIntersectionRuleSet>(
            selection_box_intersection_reducer,
          )(storables.selection_box_intersection, action),
  );
}

Reducer<String> displayed_group_name_reducer = combineReducers([
  TypedReducer<String, actions.GroupDisplayedChange>(displayed_group_name_change_displayed_group_reducer),
  TypedReducer<String, actions.GroupChange>(displayed_group_name_change_name_reducer),
]);

String displayed_group_name_change_displayed_group_reducer(String _, actions.GroupDisplayedChange action) =>
    action.group_name;

String displayed_group_name_change_name_reducer(String displayed_group_name, actions.GroupChange action) =>
    displayed_group_name == action.old_name ? action.new_name : displayed_group_name;

Modification5Prime? last_mod_5p_modification_add_reducer(
  Modification5Prime? modification,
  actions.ModificationAdd action,
) => action.modification is Modification5Prime ? action.modification as Modification5Prime : modification;

Modification3Prime? last_mod_3p_modification_add_reducer(
  Modification3Prime? modification,
  actions.ModificationAdd action,
) => action.modification is Modification3Prime ? action.modification as Modification3Prime : modification;

ModificationInternal? last_mod_int_modification_add_reducer(
  ModificationInternal? modification,
  actions.ModificationAdd action,
) => action.modification is ModificationInternal ? action.modification as ModificationInternal : modification;

///////////////////////////////////////////////////////////////////////////////////////////////////
// svg-png-caching

String? load_dna_sequence_image_uri(String? _, actions.LoadDnaSequenceImageUri action) {
  return action.uri;
}

double load_dna_sequence_png_horizontal_offset(double _, actions.LoadDnaSequenceImageUri action) {
  return action.dna_sequence_png_horizontal_offset;
}

double load_dna_sequence_png_vertical_offset(double _, actions.LoadDnaSequenceImageUri action) {
  return action.dna_sequence_png_vertical_offset;
}

Reducer<String?> dna_sequence_png_uri_reducer = combineReducers([
  TypedReducer<String?, actions.LoadDnaSequenceImageUri>(load_dna_sequence_image_uri),
]);

Reducer<double> dna_sequence_horizontal_offset_reducer = combineReducers([
  TypedReducer<double, actions.LoadDnaSequenceImageUri>(load_dna_sequence_png_horizontal_offset),
]);

Reducer<double> dna_sequence_vertical_offset_reducer = combineReducers([
  TypedReducer<double, actions.LoadDnaSequenceImageUri>(load_dna_sequence_png_vertical_offset),
]);

actions.ExportSvg? set_export_svg_action_delayed_for_png_cache(
  actions.ExportSvg? _,
  actions.SetExportSvgActionDelayedForPngCache action,
) {
  return action.export_svg_action_delayed_for_png_cache;
}

Reducer<actions.ExportSvg?> export_svg_action_delayed_for_png_cache_reducer = //combineReducers(([
    TypedReducer<actions.ExportSvg?, actions.SetExportSvgActionDelayedForPngCache>(
  set_export_svg_action_delayed_for_png_cache,
);
// ]));

bool set_is_zoom_above_threshold(bool _, actions.SetIsZoomAboveThreshold action) {
  return action.is_zoom_above_threshold;
}

Reducer<bool> is_zoom_above_threshold_reducer = combineReducers([
  TypedReducer<bool, actions.SetIsZoomAboveThreshold>(set_is_zoom_above_threshold),
]);

///////////////////////////////////////////////////////////////////////////////////////////////////
// side view mouse position/grid position reducers

Reducer<GridPosition?> side_view_mouse_grid_pos_reducer = combineReducers([
  TypedReducer<GridPosition?, actions.MouseGridPositionSideUpdate>(side_view_mouse_grid_pos_update_reducer),
  TypedReducer<GridPosition?, actions.MouseGridPositionSideClear>(side_view_mouse_grid_pos_clear_reducer),
]);

GridPosition? side_view_mouse_grid_pos_update_reducer(
  GridPosition? _,
  actions.MouseGridPositionSideUpdate action,
) => action.grid_position;

GridPosition? side_view_mouse_grid_pos_clear_reducer(
  GridPosition? _,
  actions.MouseGridPositionSideClear action,
) => null;

Reducer<Point<double>?> side_view_position_mouse_cursor_reducer = combineReducers([
  TypedReducer<Point<double>?, actions.MousePositionSideUpdate>(side_view_mouse_pos_update_reducer),
  TypedReducer<Point<double>?, actions.MousePositionSideClear>(side_view_mouse_pos_clear_reducer),
]);

Point<double>? side_view_mouse_pos_update_reducer(Point<double>? _, actions.MousePositionSideUpdate action) =>
    action.svg_pos;

Point<double>? side_view_mouse_pos_clear_reducer(Point<double>? _, actions.MousePositionSideClear action) =>
    null;

///////////////////////////////////////////////////////////////////////////////////////////////////
// strand color picker

Reducer<Strand?> color_picker_strand_reducer = combineReducers([
  TypedReducer<Strand?, actions.StrandOrSubstrandColorPickerShow>(color_picker_strand_show_reducer),
  TypedReducer<Strand?, actions.StrandOrSubstrandColorPickerHide>(color_picker_strand_hide_reducer),
]);

Strand? color_picker_strand_show_reducer(Strand? _, actions.StrandOrSubstrandColorPickerShow action) =>
    action.strand;

Strand? color_picker_strand_hide_reducer(Strand? _, actions.StrandOrSubstrandColorPickerHide action) => null;

Reducer<Substrand?> color_picker_substrand_reducer = combineReducers([
  TypedReducer<Substrand?, actions.StrandOrSubstrandColorPickerShow>(color_picker_substrand_show_reducer),
  TypedReducer<Substrand?, actions.StrandOrSubstrandColorPickerHide>(color_picker_substrand_hide_reducer),
]);

Substrand? color_picker_substrand_show_reducer(
  Substrand? _,
  actions.StrandOrSubstrandColorPickerShow action,
) => action.substrand;

Substrand? color_picker_substrand_hide_reducer(
  Substrand? _,
  actions.StrandOrSubstrandColorPickerHide action,
) => null;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui state global reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

AppUIState ui_state_global_reducer(AppUIState ui_state, AppState state, action) => ui_state.rebuild(
  (u) =>
      u
        ..storables.replace(app_ui_state_storable_global_reducer(ui_state.storables, state, action))
        ..selectables_store.replace(selectables_store_reducer(ui_state.selectables_store, state, action))
        ..mouseover_datas.replace(mouseover_datas_global_reducer(ui_state.mouseover_datas, state, action))
        ..strands_move = strands_move_global_reducer(ui_state.strands_move, state, action)?.toBuilder()
        ..domains_move = domains_move_global_reducer(ui_state.domains_move, state, action)?.toBuilder()
        ..strand_creation =
            strand_creation_global_reducer(ui_state.strand_creation, state, action)?.toBuilder()
        ..copy_info = copy_info_global_reducer(ui_state.copy_info, state, action)?.toBuilder()
        ..original_helix_offsets =
            original_helix_offsets_reducer(ui_state.original_helix_offsets, state, action).toBuilder(),
);

BuiltMap<int, BuiltList<int>> original_helix_offsets_reducer(
  BuiltMap<int, BuiltList<int>> original_helix_offsets,
  AppState state,
  action,
) {
  if (action is actions.StrandsMoveStartSelectedStrands || action is actions.StrandCreateStart) {
    var helix_offsets = original_helix_offsets.toMap();
    for (int key in state.design.helices.keys) {
      var helix = state.design.helices[key]!;
      helix_offsets[helix.idx] = [helix.min_offset, helix.max_offset].build();
    }
    return helix_offsets.build();
  }
  return original_helix_offsets;
}

GlobalReducer<BuiltList<MouseoverData>, AppState> mouseover_datas_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<MouseoverData>, AppState, actions.HelixRollSetAtOther>(
    helix_rotation_set_at_other_mouseover_reducer,
  ),
  TypedGlobalReducer<BuiltList<MouseoverData>, AppState, actions.MouseoverDataUpdate>(
    mouseover_data_update_reducer,
  ),
  // TypedGlobalReducer<BuiltList<MouseoverData>, AppState, actions.GroupDisplayedChange>(
  //     mouseover_data_group_displayed_change_reducer),
  // TypedGlobalReducer<BuiltList<MouseoverData>, AppState, actions.SliceBarOffsetSet>(
  //     mouseover_data_set_slice_bar_offset_reducer),
  // TypedGlobalReducer<BuiltList<MouseoverData>, AppState, actions.SetAppUIStateStorable>(
  //     mouseover_data_set_app_ui_state_storable_reducer),
]);

bool selection_box_intersection_reducer(bool _, actions.SelectionBoxIntersectionRuleSet action) =>
    action.intersect;
