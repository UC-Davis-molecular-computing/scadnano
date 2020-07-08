import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';
import 'package:scadnano/src/actions/actions.dart';

import '../serializers.dart';
import 'context_menu.dart';
import 'dialog.dart';
import 'dna_design.dart';
import 'example_dna_designs.dart';
import 'grid_position.dart';
import 'mouseover_data.dart';
import 'select_mode_state.dart';
import 'edit_mode.dart';
import 'selectable.dart';
import 'strand_creation.dart';
import 'strands_move.dart';
import '../constants.dart' as constants;

part 'app_ui_state.g.dart';

final DEFAULT_AppUIStateStorableBuilder = AppUIStateStorableBuilder();
final DEFAULT_AppUIStateBuilder = AppUIStateBuilder();
final DEFAULT_AppUIState = DEFAULT_AppUIStateBuilder.build();
final DEFAULT_AppUIStateStorable = DEFAULT_AppUIStateStorableBuilder.build();

/// This is the portion of AppUIState that gets written into localStorage.
abstract class AppUIStateStorable
    with BuiltJsonSerializable
    implements Built<AppUIStateStorable, AppUIStateStorableBuilder> {
  SelectModeState get select_mode_state;

  BuiltSet<EditModeChoice> get edit_modes;

  bool get autofit;

  bool get show_dna;

  bool get show_modifications;

  bool get show_mismatches;

  bool get show_editor;

  /// True if only selected helices in the side view should be displayed in the
  /// main view. False means all helices should be drawn.
  bool get only_display_selected_helices;

  num get modification_font_size;

  num get major_tick_offset_font_size;

  num get major_tick_width_font_size;

  bool get modification_display_connector;

  bool get strand_paste_keep_color;

  bool get display_base_offsets_of_major_ticks;

  bool get display_base_offsets_of_major_ticks_only_first_helix;

  bool get display_major_tick_widths;

  bool get display_major_tick_widths_all_helices;

  String get loaded_filename;

  String get loaded_script_filename;

  bool get invert_y_axis;

  bool get warn_on_exit_if_unsaved;

  bool get show_helix_circles_main_view;

  bool get show_grid_coordinates_side_view;

  static void _initializeBuilder(AppUIStateStorableBuilder b) {
    // This ensures that even if these keys are not in localStorage (e.g., due to upgrading),
    // then they will be populated with a default value instead of raising an exception.
    b.edit_modes = SetBuilder<EditModeChoice>([EditModeChoice.select]);
    b.select_mode_state = DEFAULT_SelectModeStateBuilder;
    b.autofit = true;
    b.show_dna = false;
    b.show_modifications = true;
    b.show_mismatches = true;
    b.show_editor = false;
    b.only_display_selected_helices = false;
    b.modification_font_size = constants.default_modification_font_size;
    b.major_tick_offset_font_size = constants.default_major_tick_offset_font_size;
    b.major_tick_width_font_size = constants.default_major_tick_width_font_size;
    b.modification_display_connector = true;
    b.strand_paste_keep_color = true;
    b.display_base_offsets_of_major_ticks = true;
    b.display_base_offsets_of_major_ticks_only_first_helix = true;
    b.display_major_tick_widths = false;
    b.display_major_tick_widths_all_helices = false;
    b.loaded_filename = default_filename();
    b.loaded_script_filename = default_script_filename();
    b.invert_y_axis = false;
    b.warn_on_exit_if_unsaved = true;
    b.show_helix_circles_main_view = true;
    b.show_grid_coordinates_side_view = true;
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory AppUIStateStorable(bool modification_display_connector) =>
      AppUIStateStorable.from((b) => b..modification_display_connector = modification_display_connector);

  factory AppUIStateStorable.from([void Function(AppUIStateStorableBuilder) updates]) = _$AppUIStateStorable;

  AppUIStateStorable._();

  static Serializer<AppUIStateStorable> get serializer => _$appUIStateStorableSerializer;
}

abstract class AppUIState with BuiltJsonSerializable implements Built<AppUIState, AppUIStateBuilder> {
  /// For selected objects in main view
  SelectablesStore get selectables_store;

  /// Special case for helices, which can always be selected, but only in the side view.
  BuiltSet<int> get side_selected_helix_idxs;

  @nullable
  StrandsMove get strands_move;

  bool get drawing_potential_crossover;

  bool get moving_dna_ends;

  bool get selection_box_displayed_main;

  bool get selection_box_displayed_side;

  bool get assign_complement_to_bound_strands_default;

  bool get warn_on_change_strand_dna_assign_default;

  bool get helix_change_apply_to_all;

  BuiltList<MouseoverData> get mouseover_datas;

  ExampleDNADesigns get example_dna_designs;

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

  AppUIStateStorable get storables;

  /*********** below getters delegate to storables ********************/

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

  bool get invert_y_axis => storables.invert_y_axis;

  bool get warn_on_exit_if_unsaved => storables.warn_on_exit_if_unsaved;

  bool get show_helix_circles_main_view => storables.show_helix_circles_main_view;

  bool get show_grid_coordinates_side_view => storables.show_grid_coordinates_side_view;

  static void _initializeBuilder(AppUIStateBuilder b) {
    b.mouseover_datas.replace([]);
    b.selection_box_displayed_main = false;
    b.selection_box_displayed_side = false;
    b.selectables_store = SelectablesStoreBuilder();
    b.side_selected_helix_idxs.replace([]);
    b.drawing_potential_crossover = false;
    b.moving_dna_ends = false;
    b.changed_since_last_save = false;
    b.side_view_grid_position_mouse_cursor = null;
    b.side_view_position_mouse_cursor = null;
    b.strands_move = null;
    b.context_menu = null;
    b.dialog = null;
    b.strand_creation = null;
    b.helix_change_apply_to_all = false;
    b.example_dna_designs = DEFAULT_example_dna_designs_builder;
    b.assign_complement_to_bound_strands_default = true;
    b.warn_on_change_strand_dna_assign_default = true;
    b.dna_sequence_png_uri = null;
    b.disable_png_cache_until_action_completes = null;
    b.is_zoom_above_threshold = false;
    b.storables = DEFAULT_AppUIStateStorableBuilder;
  }

  /************************ begin BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  AppUIState._();

  factory AppUIState.from_dna_design(DNADesign design) {
    var selectables_store = SelectablesStore();
    return DEFAULT_AppUIState.rebuild((s) => s..selectables_store.replace(selectables_store));
  }

  factory AppUIState([void Function(AppUIStateBuilder) updates]) =>
      _$AppUIState((u) => u..replace(DEFAULT_AppUIStateBuilder.build()));

  static Serializer<AppUIState> get serializer => _$appUIStateSerializer;
}

const DEFAULT_FILENAME_NO_EXT = 'default_dna_filename';
const DEFAULT_SCRIPT_FILENAME_NO_EXT = 'default_script_filename';
const DEFAULT_EXT = 'dna';
const DEFAULT_SCRIPT_EXT = 'py';
const ALLOWED_EXTENSIONS_DESIGN = ['dna', 'json'];
const ALLOWED_EXTENSIONS_SCRIPT = ['py'];

default_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;

default_script_filename() => DEFAULT_SCRIPT_FILENAME_NO_EXT + "." + DEFAULT_SCRIPT_EXT;
