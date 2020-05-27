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

final DEFAULT_AppUIStateBuilder = AppUIStateBuilder()
  ..edit_modes.replace([EditModeChoice.select])
  ..loaded_filename = default_filename()
  ..loaded_script_filename = default_script_filename()
  ..mouseover_datas.replace([])
  ..selection_box_displayed_main = false
  ..selection_box_displayed_side = false
  ..selectables_store = SelectablesStoreBuilder()
  ..side_selected_helix_idxs.replace([])
  ..show_dna = false
  ..show_modifications = true
  ..show_editor = false
  ..show_mismatches = true
  ..autofit = true
  ..drawing_potential_crossover = false
  ..moving_dna_ends = false
  ..changed_since_last_save = false
  ..side_view_grid_position_mouse_cursor = null
  ..side_view_position_mouse_cursor = null
  ..strands_move = null
  ..context_menu = null
  ..dialog = null
  ..strand_creation = null
  ..example_dna_designs.replace(DEFAULT_example_dna_designs)
  ..assign_complement_to_bound_strands_default = true
  ..warn_on_change_strand_dna_assign_default = true
  ..select_mode_state = DEFAULT_SelectModeStateBuilder
  ..dna_sequence_png_uri = null
  ..disable_png_cache_until_action_completes = null
  ..is_zoom_above_threshold = false
  ..only_display_selected_helices = false
  ..modification_font_size = 12
  ..modification_display_connector = true;

final DEFAULT_AppUIState = DEFAULT_AppUIStateBuilder.build();

abstract class AppUIState with BuiltJsonSerializable implements Built<AppUIState, AppUIStateBuilder> {
  AppUIState._();

  factory AppUIState.from_dna_design(DNADesign design) {
    var selectables_store = SelectablesStore();
    return DEFAULT_AppUIState.rebuild((s) => s..selectables_store.replace(selectables_store));
  }

  factory AppUIState([void Function(AppUIStateBuilder) updates]) =>
      _$AppUIState((u) => u..replace(DEFAULT_AppUIStateBuilder.build()));

  static Serializer<AppUIState> get serializer => _$appUIStateSerializer;

  /************************ end BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  /// For selected objects in main view
  SelectablesStore get selectables_store;

  /// Special case for helices, which can always be selected, but only in the side view.
  BuiltSet<int> get side_selected_helix_idxs;

  String get loaded_filename;

  String get loaded_script_filename;

  @nullable
  StrandsMove get strands_move;

  bool get show_dna;

  bool get show_modifications;

  bool get show_mismatches;

  bool get autofit;

  bool get show_editor;

  bool get drawing_potential_crossover;

  bool get moving_dna_ends;

  bool get selection_box_displayed_main;

  bool get selection_box_displayed_side;

  bool get assign_complement_to_bound_strands_default;

  bool get warn_on_change_strand_dna_assign_default;

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

  SelectModeState get select_mode_state;

  BuiltSet<EditModeChoice> get edit_modes;

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
  bool get only_display_selected_helices;

  int  get modification_font_size;
  bool get modification_display_connector;
}

const DEFAULT_FILENAME_NO_EXT = 'default_dna_filename';
const DEFAULT_SCRIPT_FILENAME_NO_EXT = 'default_script_filename';
const DEFAULT_EXT = 'dna';
const DEFAULT_SCRIPT_EXT = 'py';
const ALLOWED_EXTENSIONS_DESIGN = ['dna'];
const ALLOWED_EXTENSIONS_SCRIPT = ['py'];

default_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;

default_script_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;
