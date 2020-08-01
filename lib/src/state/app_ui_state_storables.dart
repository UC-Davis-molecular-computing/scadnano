import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';

import '../state/local_storage_design_choice.dart';
import '../serializers.dart';
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

  bool get invert_yz;

  bool get warn_on_exit_if_unsaved;

  bool get show_helix_circles_main_view;

  bool get show_grid_coordinates_side_view;

  bool get default_crossover_type_scaffold_for_setting_helix_rolls;

  bool get default_crossover_type_staple_for_setting_helix_rolls;

  LocalStorageDesignChoice get local_storage_design_choice;

  String get displayed_group_name;

  static void _initializeBuilder(AppUIStateStorablesBuilder b) {
    // This ensures that even if these keys are not in localStorage (e.g., due to upgrading),
    // then they will be populated with a default value instead of raising an exception.
    b.edit_modes = SetBuilder<EditModeChoice>([EditModeChoice.select]);
    b.select_mode_state = DEFAULT_SelectModeStateBuilder;
    b.side_selected_helix_idxs = SetBuilder<int>();
    b.autofit = true;
    b.show_dna = false;
    b.show_modifications = true;
    b.show_mismatches = false;
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
    b.invert_yz = false;
    b.warn_on_exit_if_unsaved = true;
    b.show_helix_circles_main_view = true;
    b.show_grid_coordinates_side_view = false;
    b.default_crossover_type_scaffold_for_setting_helix_rolls = true;
    b.default_crossover_type_staple_for_setting_helix_rolls = true;
    b.displayed_group_name = constants.default_group_name;
    b.local_storage_design_choice = LocalStorageDesignChoice().toBuilder();
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
