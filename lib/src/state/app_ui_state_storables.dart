import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';

import '../state/local_storage_design_choice.dart';
import '../serializers.dart';
import 'base_pair_display_type.dart';
import 'select_mode_state.dart';
import 'edit_mode.dart';
import '../constants.dart' as constants;

part 'app_ui_state_storables.g.dart';

final DEFAULT_AppUIStateStorable = AppUIStateStorablesBuilder().build();

/// This is the portion of AppUIState that gets written into localStorage.
abstract class AppUIStateStorables
    with BuiltJsonSerializable
    implements Built<AppUIStateStorables, AppUIStateStorablesBuilder> {
  SelectModeState get select_mode_state;

  BuiltSet<EditModeChoice> get edit_modes;

  BuiltSet<int> get side_selected_helix_idxs;

  bool get autofit;

  bool get show_dna;

  bool get show_strand_names;

  bool get show_strand_labels;

  bool get show_domain_names;

  bool get show_domain_labels;

  BasePairDisplayType get base_pair_display_type;

  bool get show_base_pair_lines;

  bool get export_base_pair_lines_if_other_strand_not_selected;

  bool get show_base_pair_lines_with_mismatches;

  double get strand_name_font_size;

  double get strand_label_font_size;

  double get domain_name_font_size;

  double get domain_label_font_size;

  bool get show_modifications;

  bool get show_mismatches;

  bool get show_domain_name_mismatches;

  bool get show_unpaired_insertion_deletions;

  bool get show_oxview;

  bool get show_slice_bar;

  bool get show_mouseover_data;

  /// True if only selected helices in the side view should be displayed in the
  /// main view. False means all helices should be drawn.
  bool get only_display_selected_helices;

  double get modification_font_size;

  double get major_tick_offset_font_size;

  double get major_tick_width_font_size;

  double get zoom_speed;

  bool get modification_display_connector;

  bool get strand_paste_keep_color;

  bool get display_base_offsets_of_major_ticks;

  bool get display_base_offsets_of_major_ticks_only_first_helix;

  bool get display_major_tick_widths;

  bool get display_major_tick_widths_all_helices;

  String get loaded_filename;

  String get loaded_script_filename;

  bool get invert_y;

  bool get dynamically_update_helices;

  bool get warn_on_exit_if_unsaved;

  bool get show_helix_circles_main_view;

  bool get show_helix_components_main_view;

  bool get show_edit_mode_menu;

  bool get show_grid_coordinates_side_view;

  bool get show_helices_axis_arrows;

  bool get show_loopout_extension_length;

  bool get default_crossover_type_scaffold_for_setting_helix_rolls;

  bool get default_crossover_type_staple_for_setting_helix_rolls;

  LocalStorageDesignChoice get local_storage_design_choice;

  bool get clear_helix_selection_when_loading_new_design;

  String get displayed_group_name;

  int? get slice_bar_offset;

  bool get disable_png_caching_dna_sequences;

  bool get retain_strand_color_on_selection;

  bool get display_reverse_DNA_right_side_up;

  bool get selection_box_intersection;

  bool get export_svg_text_separately;

  bool get ox_export_only_selected_strands;

  static void _initializeBuilder(AppUIStateStorablesBuilder b) {
    // This ensures that even if these keys are not in localStorage (e.g., due to upgrading),
    // then they will be populated with a default value instead of raising an exception.
    b.edit_modes = SetBuilder<EditModeChoice>([EditModeChoice.select]);
    b.select_mode_state = DEFAULT_SelectModeStateBuilder;
    b.side_selected_helix_idxs = SetBuilder<int>();
    b.autofit = true;
    b.show_dna = false;
    b.show_strand_names = false;
    b.show_strand_labels = false;
    b.show_domain_names = false;
    b.show_domain_labels = false;
    b.base_pair_display_type = BasePairDisplayType.none;
    b.show_base_pair_lines = false;
    b.export_base_pair_lines_if_other_strand_not_selected = false;
    b.show_base_pair_lines_with_mismatches = false;
    b.strand_name_font_size = constants.default_strand_name_font_size;
    b.strand_label_font_size = constants.default_strand_label_font_size;
    b.domain_name_font_size = constants.default_domain_name_font_size;
    b.domain_label_font_size = constants.default_domain_label_font_size;
    b.show_modifications = true;
    b.show_mismatches = false;
    b.show_domain_name_mismatches = false;
    b.show_unpaired_insertion_deletions = true;
    b.show_oxview = false;
    b.only_display_selected_helices = false;
    b.zoom_speed = 0.3;
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
    b.invert_y = false;
    b.dynamically_update_helices = false;
    b.warn_on_exit_if_unsaved = true;
    b.show_helix_circles_main_view = true;
    b.show_helix_components_main_view = true;
    b.show_edit_mode_menu = true;
    b.show_grid_coordinates_side_view = false;
    b.show_helices_axis_arrows = true;
    b.show_loopout_extension_length = false;
    b.default_crossover_type_scaffold_for_setting_helix_rolls = true;
    b.default_crossover_type_staple_for_setting_helix_rolls = true;
    b.displayed_group_name = constants.default_group_name;
    b.show_slice_bar = false;
    b.slice_bar_offset = null;
    b.disable_png_caching_dna_sequences = false;
    b.retain_strand_color_on_selection = false;
    b.display_reverse_DNA_right_side_up = false;
    b.local_storage_design_choice = LocalStorageDesignChoice().toBuilder();
    b.clear_helix_selection_when_loading_new_design = false;
    b.show_mouseover_data = false;
    b.selection_box_intersection = false;
    b.export_svg_text_separately = false;
    b.ox_export_only_selected_strands = false;
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory AppUIStateStorables(bool modification_display_connector) =>
      AppUIStateStorables.from((b) => b..modification_display_connector = modification_display_connector);

  factory AppUIStateStorables.from([void Function(AppUIStateStorablesBuilder) updates]) =
      _$AppUIStateStorables;

  AppUIStateStorables._();

  static Serializer<AppUIStateStorables> get serializer => _$appUIStateStorablesSerializer;

  @memoized
  int get hashCode;
}

const DEFAULT_FILENAME_NO_EXT = 'default_dna_filename';
const DEFAULT_SCRIPT_FILENAME_NO_EXT = 'default_script_filename';

default_filename() => DEFAULT_FILENAME_NO_EXT + "." + constants.default_scadnano_file_extension;

default_script_filename() => DEFAULT_SCRIPT_FILENAME_NO_EXT + "." + constants.default_script_file_extension;
