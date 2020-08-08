import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';
import '../actions/actions.dart';
import '../state/local_storage_design_choice.dart';

import 'app_ui_state_storables.dart';
import '../serializers.dart';
import 'context_menu.dart';
import 'dialog.dart';
import 'design.dart';
import 'domains_move.dart';
import 'example_designs.dart';
import 'grid_position.dart';
import 'mouseover_data.dart';
import 'select_mode_state.dart';
import 'edit_mode.dart';
import 'selectable.dart';
import 'strand_creation.dart';
import 'strands_move.dart';
import 'helix_group_move.dart';

part 'app_ui_state.g.dart';

final DEFAULT_AppUIState = AppUIStateBuilder().build();

abstract class AppUIState with BuiltJsonSerializable implements Built<AppUIState, AppUIStateBuilder> {
  /// For selected objects in main view
  SelectablesStore get selectables_store;

  @nullable
  StrandsMove get strands_move;

  @nullable
  DomainsMove get domains_move;

  bool get potential_crossover_is_drawing;

  bool get dna_ends_are_moving;

  bool get helix_group_is_moving;

  bool get selection_box_displayed_main;

  bool get selection_box_displayed_side;

  bool get assign_complement_to_bound_strands_default;

  bool get warn_on_change_strand_dna_assign_default;

  bool get helix_change_apply_to_all;

  BuiltList<MouseoverData> get mouseover_datas;

  ExampleDesigns get example_designs;

  @nullable
  Dialog get dialog;

  @nullable
  StrandCreation get strand_creation;

  @nullable // null when mouse outside of side view or helix edit mode not enabled
  GridPosition get side_view_grid_position_mouse_cursor;

  @nullable // null when mouse outside of side view or helix edit mode not enabled
  Point<num> get side_view_position_mouse_cursor;

  @nullable
  ContextMenu get context_menu;

  /// Save button is enabled iff this is true
  bool get changed_since_last_save;

  /// PNG image of dna sequence used for svg caching
  @nullable
  String get dna_sequence_png_uri;

  /// If this is `null`, png-caching runs normally.
  /// Otherwise, disable png-caching (if a png would otherwise be used)
  /// until action is dispatched.
  @nullable
  Action get disable_png_cache_until_action_completes;

  /// PNG image should be used (if available) if false.
  bool get is_zoom_above_threshold;

  /// True if only selected helices in the side view should be displayed in the
  /// main view. False means all helices should be drawn.
  bool get only_display_selected_helices => storables.only_display_selected_helices;

  num get modification_font_size => storables.modification_font_size;

  bool get modification_display_connector => storables.modification_display_connector;

  bool get display_base_offsets_of_major_ticks => storables.display_base_offsets_of_major_ticks;

  bool get display_base_offsets_of_major_ticks_only_first_helix =>
      storables.display_base_offsets_of_major_ticks_only_first_helix;

  bool get display_major_tick_widths => storables.display_major_tick_widths;

  bool get display_major_tick_widths_all_helices => storables.display_major_tick_widths_all_helices;

  AppUIStateStorables get storables;

  /*********** below getters delegate to storables ********************/

  /// Special case for helices, which can always be selected, but only in the side view.
  BuiltSet<int> get side_selected_helix_idxs => storables.side_selected_helix_idxs;

  String get loaded_filename => storables.loaded_filename;

  String get loaded_script_filename => storables.loaded_script_filename;

  bool get show_dna => storables.show_dna;

  bool get show_modifications => storables.show_modifications;

  bool get show_mismatches => storables.show_mismatches;

  bool get show_editor => storables.show_editor;

  bool get autofit => storables.autofit;

  bool get strand_paste_keep_color => storables.strand_paste_keep_color;

  num get major_tick_offset_font_size => storables.major_tick_offset_font_size;

  num get major_tick_width_font_size => storables.major_tick_width_font_size;

  SelectModeState get select_mode_state => storables.select_mode_state;

  BuiltSet<EditModeChoice> get edit_modes => storables.edit_modes;

  bool get invert_yz => storables.invert_yz;

  bool get warn_on_exit_if_unsaved => storables.warn_on_exit_if_unsaved;

  bool get show_helix_circles_main_view => storables.show_helix_circles_main_view;

  bool get show_grid_coordinates_side_view => storables.show_grid_coordinates_side_view;

  bool get show_loopout_length_main_view => storables.show_loopout_length_main_view;

  bool get default_crossover_type_scaffold_for_setting_helix_rolls =>
      storables.default_crossover_type_scaffold_for_setting_helix_rolls;

  bool get default_crossover_type_staple_for_setting_helix_rolls =>
      storables.default_crossover_type_staple_for_setting_helix_rolls;

  String get displayed_group_name => storables.displayed_group_name;

  LocalStorageDesignChoice get local_storage_design_choice => storables.local_storage_design_choice;

  static void _initializeBuilder(AppUIStateBuilder b) {
    b.mouseover_datas.replace([]);
    b.selection_box_displayed_main = false;
    b.selection_box_displayed_side = false;
    b.selectables_store = SelectablesStoreBuilder();
    b.potential_crossover_is_drawing = false;
    b.dna_ends_are_moving = false;
    b.helix_group_is_moving = false;
    b.changed_since_last_save = false;
    b.side_view_grid_position_mouse_cursor = null;
    b.side_view_position_mouse_cursor = null;
    b.strands_move = null;
    b.context_menu = null;
    b.dialog = null;
    b.strand_creation = null;
    b.helix_change_apply_to_all = false;
    b.example_designs = DEFAULT_example_designs_builder;
    b.assign_complement_to_bound_strands_default = true;
    b.warn_on_change_strand_dna_assign_default = true;
    b.dna_sequence_png_uri = null;
    b.disable_png_cache_until_action_completes = null;
    b.is_zoom_above_threshold = false;
    b.storables.replace(DEFAULT_AppUIStateStorable);
  }

  /************************ begin BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  AppUIState._();

  factory AppUIState.from_design(Design design) {
    var selectables_store = SelectablesStore();
    return DEFAULT_AppUIState.rebuild((s) => s..selectables_store.replace(selectables_store));
  }

  factory AppUIState([void Function(AppUIStateBuilder) updates]) =>
      _$AppUIState((u) => u..replace(DEFAULT_AppUIState));

  static Serializer<AppUIState> get serializer => _$appUIStateSerializer;
}
