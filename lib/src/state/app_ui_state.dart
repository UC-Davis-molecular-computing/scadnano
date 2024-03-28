import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';
import 'package:scadnano/src/state/design_side_rotation_data.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/copy_info.dart';
import '../actions/actions.dart' as actions;
import '../state/local_storage_design_choice.dart';

import 'app_ui_state_storables.dart';
import '../serializers.dart';
import 'base_pair_display_type.dart';
import 'context_menu.dart';
import 'dialog.dart';
import 'design.dart';
import 'dna_assign_options.dart';
import 'domains_move.dart';
import 'example_designs.dart';
import 'grid_position.dart';
import 'mouseover_data.dart';
import 'select_mode_state.dart';
import 'edit_mode.dart';
import 'selectable.dart';
import 'strand.dart';
import 'substrand.dart';
import 'strand_creation.dart';
import 'strands_move.dart';
import 'selection_rope.dart';

part 'app_ui_state.g.dart';

final DEFAULT_AppUIState = AppUIStateBuilder().build();

abstract class AppUIState with BuiltJsonSerializable implements Built<AppUIState, AppUIStateBuilder> {
  /// For selected objects in main view
  SelectablesStore get selectables_store;

  @nullable
  StrandsMove get strands_move;

  @nullable
  DomainsMove get domains_move;

  @nullable
  CopyInfo get copy_info;

  bool get potential_crossover_is_drawing;

  bool get dna_ends_are_moving;

  bool get helix_group_is_moving;

  bool get load_dialog;

  bool get slice_bar_is_moving;

  bool get selection_box_displayed_main;

  bool get selection_box_displayed_side;

  DNAAssignOptions get dna_assign_options;

  bool get helix_change_apply_to_all;

  @nullable
  SelectionRope get selection_rope;

  // last 5' modification that was added (for populating new add modification dialogs)
  @nullable
  Modification5Prime get last_mod_5p;

  // last 3' modification that was added (for populating new add modification dialogs)
  @nullable
  Modification3Prime get last_mod_3p;

  // last internal modification that was added (for populating new add modification dialogs)
  @nullable
  ModificationInternal get last_mod_int;

  BuiltList<MouseoverData> get mouseover_datas;

  ExampleDesigns get example_designs;

  @nullable
  Dialog get dialog;

  @nullable // null indicates that strand color picker is not being used
  Strand get color_picker_strand;

  @nullable // null indicates that strand color picker is not being used
  Substrand get color_picker_substrand;

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

  num get dna_sequence_png_horizontal_offset;

  num get dna_sequence_png_vertical_offset;

  /// If this is `null`, png-caching runs normally.
  /// Otherwise, disable png-caching (if a png would otherwise be used)
  /// until action is dispatched.
  @nullable
  actions.ExportSvg get export_svg_action_delayed_for_png_cache;

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

  bool get show_strand_names => storables.show_strand_names;

  bool get show_strand_labels => storables.show_strand_labels;

  bool get show_domain_names => storables.show_domain_names;

  bool get show_domain_labels => storables.show_domain_labels;

  BasePairDisplayType get base_pair_display_type => storables.base_pair_display_type;

  bool get show_base_pair_lines => storables.show_base_pair_lines;

  bool get show_base_pair_lines_with_mismatches => storables.show_base_pair_lines_with_mismatches;

  num get strand_name_font_size => storables.strand_name_font_size;

  num get strand_label_font_size => storables.strand_label_font_size;

  num get domain_name_font_size => storables.domain_name_font_size;

  num get domain_label_font_size => storables.domain_label_font_size;

  bool get show_modifications => storables.show_modifications;

  bool get show_mismatches => storables.show_mismatches;

  bool get show_domain_name_mismatches => storables.show_domain_name_mismatches;

  bool get show_unpaired_insertion_deletions => storables.show_unpaired_insertion_deletions;

  bool get show_editor => storables.show_editor;

  bool get autofit => storables.autofit;

  bool get strand_paste_keep_color => storables.strand_paste_keep_color;

  num get zoom_speed => storables.zoom_speed;

  num get major_tick_offset_font_size => storables.major_tick_offset_font_size;

  num get major_tick_width_font_size => storables.major_tick_width_font_size;

  SelectModeState get select_mode_state => storables.select_mode_state;

  BuiltSet<EditModeChoice> get edit_modes => storables.edit_modes;

  bool get invert_y => storables.invert_y;

  bool get warn_on_exit_if_unsaved => storables.warn_on_exit_if_unsaved;

  bool get show_helix_circles_main_view => storables.show_helix_circles_main_view;

  bool get show_helix_components_main_view => storables.show_helix_components_main_view;

  bool get show_edit_mode_menu => storables.show_edit_mode_menu;

  bool get show_grid_coordinates_side_view => storables.show_grid_coordinates_side_view;

  bool get show_helices_axis_arrows => storables.show_helices_axis_arrows;

  bool get show_loopout_extension_length => storables.show_loopout_extension_length;

  bool get export_svg_text_separately => storables.export_svg_text_separately;

  bool get default_crossover_type_scaffold_for_setting_helix_rolls =>
      storables.default_crossover_type_scaffold_for_setting_helix_rolls;

  bool get default_crossover_type_staple_for_setting_helix_rolls =>
      storables.default_crossover_type_staple_for_setting_helix_rolls;

  String get displayed_group_name => storables.displayed_group_name;

  LocalStorageDesignChoice get local_storage_design_choice => storables.local_storage_design_choice;

  bool get clear_helix_selection_when_loading_new_design =>
      storables.clear_helix_selection_when_loading_new_design;

  bool get show_slice_bar => storables.show_slice_bar;

  int get slice_bar_offset => storables.slice_bar_offset;

  bool get disable_png_caching_dna_sequences => storables.disable_png_caching_dna_sequences;

  bool get retain_strand_color_on_selection => storables.retain_strand_color_on_selection;

  bool get display_reverse_DNA_right_side_up => storables.display_reverse_DNA_right_side_up;

  bool get show_mouseover_data => storables.show_mouseover_data;

  bool get selection_box_intersection => storables.selection_box_intersection;

  bool get ox_export_only_selected_strands => storables.ox_export_only_selected_strands;

  static void _initializeBuilder(AppUIStateBuilder b) {
    b.copy_info = null;
    b.last_mod_5p = null;
    b.last_mod_3p = null;
    b.last_mod_int = null;
    b.mouseover_datas.replace([]);
    b.selection_box_displayed_main = false;
    b.selection_box_displayed_side = false;
    b.selectables_store = SelectablesStoreBuilder();
    b.potential_crossover_is_drawing = false;
    b.dna_ends_are_moving = false;
    b.helix_group_is_moving = false;
    b.load_dialog = false;
    b.slice_bar_is_moving = false;
    b.changed_since_last_save = false;
    b.side_view_grid_position_mouse_cursor = null;
    b.side_view_position_mouse_cursor = null;
    b.strands_move = null;
    b.context_menu = null;
    b.dialog = null;
    b.color_picker_strand = null;
    b.color_picker_substrand = null;
    b.strand_creation = null;
    b.helix_change_apply_to_all = true;
    b.example_designs = DEFAULT_example_designs_builder;
    b.dna_assign_options = DEFAULT_dna_assign_options_builder;
    b.dna_sequence_png_uri = null;
    b.dna_sequence_png_horizontal_offset = 0;
    b.dna_sequence_png_vertical_offset = 0;
    b.export_svg_action_delayed_for_png_cache = null;
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
