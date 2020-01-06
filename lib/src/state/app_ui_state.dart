import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';

import '../serializers.dart';
import 'context_menu.dart';
import 'dna_design.dart';
import 'grid_position.dart';
import 'mouseover_data.dart';
import 'select_mode_state.dart';
import 'edit_mode.dart';
import 'selectable.dart';
import 'strand_creation.dart';
import 'strands_move.dart';

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
  ..show_editor = false
  ..show_mismatches = true
  ..drawing_potential_crossover = false
  ..moving_dna_ends = false
  ..changed_since_last_save = false
  ..side_view_grid_position_mouse_cursor = null
  ..side_view_position_mouse_cursor = null
  ..strands_move = null
  ..context_menu = null
  ..strand_creation = null
  ..select_mode_state = DEFAULT_SelectModeStateBuilder;

final DEFAULT_AppUIState = DEFAULT_AppUIStateBuilder.build();

abstract class AppUIState with BuiltJsonSerializable implements Built<AppUIState, AppUIStateBuilder> {
  AppUIState._();

  factory AppUIState.from_dna_design(DNADesign design) {
    var selectables_store = SelectablesStore();
//    selectables_store = selectables_store.register_dna_design(design);
    return DEFAULT_AppUIState.rebuild((s) => s..selectables_store.replace(selectables_store));
  }

  factory AppUIState([void Function(AppUIStateBuilder) updates]) =>
      _$AppUIState((u) => u..replace(DEFAULT_AppUIStateBuilder.build()));

  static Serializer<AppUIState> get serializer => _$appUIStateSerializer;

  /************************ end BuiltValue boilerplate ************************/

  /// For selected objects in main view
  SelectablesStore get selectables_store;

  /// Special case for helices, which can always be selected, but only in the side view.
  BuiltSet<int> get side_selected_helix_idxs;

  String get loaded_filename;

  String get loaded_script_filename;

  @nullable
  StrandsMove get strands_move;

  bool get show_dna;

  bool get show_mismatches;

  bool get show_editor;

  bool get drawing_potential_crossover;

  bool get moving_dna_ends;

  bool get selection_box_displayed_main;

  bool get selection_box_displayed_side;

  BuiltList<MouseoverData> get mouseover_datas;

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
}

const DEFAULT_FILENAME_NO_EXT = 'default_dna_filename';
const DEFAULT_SCRIPT_FILENAME_NO_EXT = 'default_script_filename';
const DEFAULT_EXT = 'dna';
const DEFAULT_SCRIPT_EXT = 'py';
const ALLOWED_EXTENSIONS_DESIGN = ['dna'];
const ALLOWED_EXTENSIONS_SCRIPT = ['py'];

default_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;

default_script_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;
