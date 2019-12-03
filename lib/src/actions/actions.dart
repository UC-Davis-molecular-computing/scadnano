@JS()
library actions2;

import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:js/js.dart';
import 'package:scadnano/src/model/selectable.dart';
import 'package:scadnano/src/model/selection_box.dart';
import 'package:w_flux/w_flux.dart';
import 'package:built_collection/built_collection.dart';

import '../serializers.dart';
import '../model/dna_design.dart';
import '../model/substrand.dart';
import '../model/app_state.dart';
import '../model/dna_design_action_packs.dart';
import '../model/select_mode.dart';
import '../model/select_mode_state.dart';
import '../model/edit_mode.dart';
import '../model/helix.dart';
import '../model/grid_position.dart';
import '../model/mouseover_data.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import '../model/loopout.dart';
import '../middleware/local_storage.dart';

part 'actions.g.dart';

//TODO: put name of loaded file in browser tab

/// [Action]s don't have to implement BuiltValue, but if they do, and they use the serialization mechanism,
/// this this toJson method will work automatically.
abstract class Action2 {
  dynamic toJson();
}

/// [Action] that can be undone via the undo stack. (typically changes to the [DNADesign])
//@BuiltValue(instantiable: false)
//abstract class UndoableAction implements Action2 {
//  @override
//  @nullable
//  bool get skip_undo;
//
//  UndoableAction rebuild(void Function(UndoableActionBuilder) updates);
//  UndoableActionBuilder toBuilder();
//}

abstract class UndoableAction extends Action2 {}

// Wrap an UndoableAction in a SkipUndo in order to apply it, but skip its effect on the undo/redo stacks.
abstract class SkipUndo with BuiltJsonSerializable implements Action2, Built<SkipUndo, SkipUndoBuilder> {
  UndoableAction get undoable_action;

  /************************ begin BuiltValue boilerplate ************************/
  factory SkipUndo(UndoableAction undoable_action) =>
      SkipUndo.from((b) => b..undoable_action = undoable_action);

  factory SkipUndo.from([void Function(SkipUndoBuilder) updates]) = _$SkipUndo;

  SkipUndo._();

  static Serializer<SkipUndo> get serializer => _$skipUndoSerializer;
}

/// [Action] that should trigger storing of certain [Storable]s to localStorage.
abstract class StorableAction extends Action2 {
  Iterable<Storable> storables();
}

/// [Action] intended for applying >= 2 other [UndoableAction]s at once,
/// which can be undone/redone in a single step by [UndoRedo].
abstract class BatchAction
    with BuiltJsonSerializable
    implements UndoableAction, Built<BatchAction, BatchActionBuilder> {
  BuiltList<UndoableAction> get actions;

  /************************ begin BuiltValue boilerplate ************************/
  factory BatchAction(Iterable<UndoableAction> actions) =>
      BatchAction.from((b) => b..actions.replace(BuiltList<UndoableAction>(actions)));

  factory BatchAction.from([void Function(BatchActionBuilder) updates]) = _$BatchAction;

  BatchAction._();

  static Serializer<BatchAction> get serializer => _$batchActionSerializer;

  @override
  dynamic toJson() => {'actions': actions.toList()};
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Select modes

abstract class ToggleSelectMode
    with BuiltJsonSerializable
    implements StorableAction, Built<ToggleSelectMode, ToggleSelectModeBuilder> {
  SelectModeChoice get select_mode_choice;

  Iterable<Storable> storables() => [Storable.select_modes];

  /************************ begin BuiltValue boilerplate ************************/
  factory ToggleSelectMode(SelectModeChoice select_mode_choice) =>
      ToggleSelectMode.from((b) => b..select_mode_choice = select_mode_choice);

  factory ToggleSelectMode.from([void Function(ToggleSelectModeBuilder) updates]) = _$ToggleSelectMode;

  ToggleSelectMode._();

  static Serializer<ToggleSelectMode> get serializer => _$toggleSelectModeSerializer;
}

abstract class SetSelectModes
    with BuiltJsonSerializable
    implements Action2, Built<SetSelectModes, SetSelectModesBuilder> {
  BuiltSet<SelectModeChoice> get select_mode_choices;

  /************************ begin BuiltValue boilerplate ************************/
  factory SetSelectModes(SetBuilder<SelectModeChoice> select_mode_choices) =>
      SetSelectModes.from((b) => b..select_mode_choices = select_mode_choices);

  factory SetSelectModes.from([void Function(SetSelectModesBuilder) updates]) = _$SetSelectModes;

  SetSelectModes._();

  static Serializer<SetSelectModes> get serializer => _$setSelectModesSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Show/hide DNA/mismatches/editor

abstract class SetShowDNA
    with BuiltJsonSerializable
    implements StorableAction, Built<SetShowDNA, SetShowDNABuilder> {
  bool get show;

  Iterable<Storable> storables() => [Storable.show_dna];

  factory SetShowDNA(bool show) => SetShowDNA.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory SetShowDNA.from([void Function(SetShowDNABuilder) updates]) = _$SetShowDNA;

  SetShowDNA._();

  static Serializer<SetShowDNA> get serializer => _$setShowDNASerializer;
}

abstract class SetShowMismatches
    with BuiltJsonSerializable
    implements StorableAction, Built<SetShowMismatches, SetShowMismatchesBuilder> {
  bool get show;

  Iterable<Storable> storables() => [Storable.show_mismatches];

  factory SetShowMismatches(bool show) => SetShowMismatches.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory SetShowMismatches.from([void Function(SetShowMismatchesBuilder) updates]) = _$SetShowMismatches;

  SetShowMismatches._();

  static Serializer<SetShowMismatches> get serializer => _$setShowMismatchesSerializer;
}

abstract class SetShowEditor
    with BuiltJsonSerializable
    implements StorableAction, Built<SetShowEditor, SetShowEditorBuilder> {
  bool get show;

  Iterable<Storable> storables() => [Storable.show_editor];

  factory SetShowEditor(bool show) => SetShowEditor.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory SetShowEditor.from([void Function(SetShowEditorBuilder) updates]) = _$SetShowEditor;

  SetShowEditor._();

  static Serializer<SetShowEditor> get serializer => _$setShowEditorSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Save/load files

abstract class SaveDNAFile
    with BuiltJsonSerializable
    implements Action2, Built<SaveDNAFile, SaveDNAFileBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SaveDNAFile([void Function(SaveDNAFileBuilder) updates]) = _$SaveDNAFile;

  SaveDNAFile._();

  static Serializer<SaveDNAFile> get serializer => _$saveDNAFileSerializer;
}

abstract class LoadDNAFile
    with BuiltJsonSerializable
    implements Action2, Built<LoadDNAFile, LoadDNAFileBuilder> {
  String get content;

  String get filename;

  /************************ begin BuiltValue boilerplate ************************/
  factory LoadDNAFile(String content, String filename) => LoadDNAFile.from((b) => b
    ..content = content
    ..filename = filename);

  factory LoadDNAFile.from([void Function(LoadDNAFileBuilder) updates]) = _$LoadDNAFile;

  LoadDNAFile._();

  static Serializer<LoadDNAFile> get serializer => _$loadDNAFileSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mouseover data (main view)

abstract class MouseoverDataClear
    with BuiltJsonSerializable
    implements Action2, Built<MouseoverDataClear, MouseoverDataClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverDataClear([void Function(MouseoverDataClearBuilder) updates]) = _$MouseoverDataClear;

  MouseoverDataClear._();

  static Serializer<MouseoverDataClear> get serializer => _$mouseoverDataClearSerializer;
}

abstract class MouseoverDataUpdate
    with BuiltJsonSerializable
    implements Action2, Built<MouseoverDataUpdate, MouseoverDataUpdateBuilder> {
  BuiltList<MouseoverData> get mouseover_datas;

  factory MouseoverDataUpdate(DNADesign dna_design, Iterable<MouseoverParams> params) {
    ListBuilder<MouseoverData> mouseover_datas_builder = MouseoverData.from_params(dna_design, params);
    return MouseoverDataUpdate.from((b) => b..mouseover_datas = mouseover_datas_builder);
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverDataUpdate.from([void Function(MouseoverDataUpdateBuilder) updates]) =
      _$MouseoverDataUpdate;

  MouseoverDataUpdate._();

  static Serializer<MouseoverDataUpdate> get serializer => _$mouseoverDataUpdateSerializer;
}

abstract class HelixRotationSet
    with BuiltJsonSerializable
    implements UndoableAction, Built<HelixRotationSet, HelixRotationSetBuilder> {
  int get helix_idx;

  double get rotation;

  int get anchor;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixRotationSet(int helix_idx, double rotation, int anchor) => HelixRotationSet.from((b) => b
    ..helix_idx = helix_idx
    ..rotation = rotation
    ..anchor = anchor);

  factory HelixRotationSet.from([void Function(HelixRotationSetBuilder) updates]) = _$HelixRotationSet;

  HelixRotationSet._();

  static Serializer<HelixRotationSet> get serializer => _$helixRotationSetSerializer;
}

// set helix rotation at anchor to point at helix_other
abstract class HelixRotationSetAtOther
    with BuiltJsonSerializable
    implements UndoableAction, Built<HelixRotationSetAtOther, HelixRotationSetAtOtherBuilder> {
  int get helix_idx;

  int get helix_other_idx;

  bool get forward;

  int get anchor;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixRotationSetAtOther(int helix_idx, int helix_other_idx, bool forward, int anchor) =>
      HelixRotationSetAtOther.from((b) => b
        ..helix_idx = helix_idx
        ..helix_other_idx = helix_other_idx
        ..forward = forward
        ..anchor = anchor);

  factory HelixRotationSetAtOther.from([void Function(HelixRotationSetAtOtherBuilder) updates]) =
      _$HelixRotationSetAtOther;

  HelixRotationSetAtOther._();

  static Serializer<HelixRotationSetAtOther> get serializer => _$helixRotationSetAtOtherSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Error message

abstract class ErrorMessageSet
    with BuiltJsonSerializable
    implements Action2, Built<ErrorMessageSet, ErrorMessageSetBuilder> {
  String get error_message;

  /************************ begin BuiltValue boilerplate ************************/
  factory ErrorMessageSet(String error_message) =>
      ErrorMessageSet.from((b) => b..error_message = error_message);

  factory ErrorMessageSet.from([void Function(ErrorMessageSetBuilder) updates]) = _$ErrorMessageSet;

  ErrorMessageSet._();

  static Serializer<ErrorMessageSet> get serializer => _$errorMessageSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Selection box (side view)

abstract class SelectionBoxCreate
    with BuiltJsonSerializable
    implements Action2, Built<SelectionBoxCreate, SelectionBoxCreateBuilder> {
  Point<num> get point;

  bool get toggle;

  bool get is_main;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxCreate(Point<num> point, bool toggle, bool is_main) => SelectionBoxCreate.from((b) => b
    ..point = point
    ..toggle = toggle
    ..is_main = is_main);

  factory SelectionBoxCreate.from([void Function(SelectionBoxCreateBuilder) updates]) = _$SelectionBoxCreate;

  SelectionBoxCreate._();

  static Serializer<SelectionBoxCreate> get serializer => _$selectionBoxCreateSerializer;
}

abstract class SelectionBoxSizeChanged
    with BuiltJsonSerializable
    implements Action2, Built<SelectionBoxSizeChanged, SelectionBoxSizeChangedBuilder> {
  Point<num> get point;

  bool get is_main;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxSizeChanged(Point<num> point, bool is_main) => SelectionBoxSizeChanged.from((b) => b
    ..point = point
    ..is_main = is_main);

  factory SelectionBoxSizeChanged.from([void Function(SelectionBoxSizeChangedBuilder) updates]) =
      _$SelectionBoxSizeChanged;

  SelectionBoxSizeChanged._();

  static Serializer<SelectionBoxSizeChanged> get serializer => _$selectionBoxSizeChangedSerializer;
}

abstract class SelectionBoxRemove
    with BuiltJsonSerializable
    implements Action2, Built<SelectionBoxRemove, SelectionBoxRemoveBuilder> {
  bool get is_main;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxRemove(bool is_main) => SelectionBoxRemove.from((b) => b..is_main = is_main);

  factory SelectionBoxRemove.from([void Function(SelectionBoxRemoveBuilder) updates]) = _$SelectionBoxRemove;

  SelectionBoxRemove._();

  static Serializer<SelectionBoxRemove> get serializer => _$selectionBoxRemoveSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Selection box (main view)

abstract class SelectionBoxCreateMain
    with BuiltJsonSerializable
    implements Action2, Built<SelectionBoxCreateMain, SelectionBoxCreateMainBuilder> {
  Point<num> get point;

  bool get toggle;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxCreateMain(Point<num> point, bool toggle) => SelectionBoxCreateMain.from((b) => b
    ..point = point
    ..toggle = toggle);

  factory SelectionBoxCreateMain.from([void Function(SelectionBoxCreateMainBuilder) updates]) =
      _$SelectionBoxCreateMain;

  SelectionBoxCreateMain._();

  static Serializer<SelectionBoxCreateMain> get serializer => _$selectionBoxCreateMainSerializer;
}

abstract class SelectionBoxSizeChangedMain
    with BuiltJsonSerializable
    implements Action2, Built<SelectionBoxSizeChangedMain, SelectionBoxSizeChangedMainBuilder> {
  Point<num> get point;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxSizeChangedMain(Point<num> point) =>
      SelectionBoxSizeChangedMain.from((b) => b..point = point);

  factory SelectionBoxSizeChangedMain.from([void Function(SelectionBoxSizeChangedMainBuilder) updates]) =
      _$SelectionBoxSizeChangedMain;

  SelectionBoxSizeChangedMain._();

  static Serializer<SelectionBoxSizeChangedMain> get serializer => _$selectionBoxSizeChangedMainSerializer;
}

abstract class SelectionBoxRemoveMain
    with BuiltJsonSerializable
    implements Action2, Built<SelectionBoxRemoveMain, SelectionBoxRemoveMainBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxRemoveMain() => SelectionBoxRemoveMain.from((b) => b);

  factory SelectionBoxRemoveMain.from([void Function(SelectionBoxRemoveMainBuilder) updates]) =
      _$SelectionBoxRemoveMain;

  SelectionBoxRemoveMain._();

  static Serializer<SelectionBoxRemoveMain> get serializer => _$selectionBoxRemoveMainSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mouse position (side view)

abstract class SideViewMousePositionUpdate
    with BuiltJsonSerializable
    implements Action2, Built<SideViewMousePositionUpdate, SideViewMousePositionUpdateBuilder> {
  Point<num> get point;

  /************************ begin BuiltValue boilerplate ************************/
  factory SideViewMousePositionUpdate(Point<num> point) =>
      SideViewMousePositionUpdate.from((b) => b..point = point);

  factory SideViewMousePositionUpdate.from([void Function(SideViewMousePositionUpdateBuilder) updates]) =
      _$SideViewMousePositionUpdate;

  SideViewMousePositionUpdate._();

  static Serializer<SideViewMousePositionUpdate> get serializer => _$sideViewMousePositionUpdateSerializer;
}

abstract class SideViewMousePositionRemove
    with BuiltJsonSerializable
    implements Action2, Built<SideViewMousePositionRemove, SideViewMousePositionRemoveBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SideViewMousePositionRemove() => SideViewMousePositionRemove.from((b) => b);

  factory SideViewMousePositionRemove.from([void Function(SideViewMousePositionRemoveBuilder) updates]) =
      _$SideViewMousePositionRemove;

  SideViewMousePositionRemove._();

  static Serializer<SideViewMousePositionRemove> get serializer => _$sideViewMousePositionRemoveSerializer;
}

abstract class SideViewMouseGridPositionUpdate
    with BuiltJsonSerializable
    implements Action2, Built<SideViewMouseGridPositionUpdate, SideViewMouseGridPositionUpdateBuilder> {
  GridPosition get grid_position;

  /************************ begin BuiltValue boilerplate ************************/
  factory SideViewMouseGridPositionUpdate(GridPosition grid_position) =>
      SideViewMouseGridPositionUpdate.from((b) => b..grid_position.replace(grid_position));

  factory SideViewMouseGridPositionUpdate.from(
      [void Function(SideViewMouseGridPositionUpdateBuilder) updates]) = _$SideViewMouseGridPositionUpdate;

  SideViewMouseGridPositionUpdate._();

  static Serializer<SideViewMouseGridPositionUpdate> get serializer =>
      _$sideViewMouseGridPositionUpdateSerializer;
}

abstract class SideViewMouseGridPositionClear
    with BuiltJsonSerializable
    implements Action2, Built<SideViewMouseGridPositionClear, SideViewMouseGridPositionClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SideViewMouseGridPositionClear() => SideViewMouseGridPositionClear.from((b) => b);

  factory SideViewMouseGridPositionClear.from(
      [void Function(SideViewMouseGridPositionClearBuilder) updates]) = _$SideViewMouseGridPositionClear;

  SideViewMouseGridPositionClear._();

  static Serializer<SideViewMouseGridPositionClear> get serializer =>
      _$sideViewMouseGridPositionClearSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Selectables

abstract class Select with BuiltJsonSerializable implements Action2, Built<Select, SelectBuilder> {
  Selectable get selectable;

  bool get toggle;

  /************************ begin BuiltValue boilerplate ************************/
  factory Select(Selectable selectable, bool toggle) => Select.from((b) => b
    ..selectable = selectable
    ..toggle = toggle);

  factory Select.from([void Function(SelectBuilder) updates]) = _$Select;

  Select._();

  static Serializer<Select> get serializer => _$selectSerializer;
}

abstract class SelectionsClear
    with BuiltJsonSerializable
    implements Action2, Built<SelectionsClear, SelectionsClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionsClear() => SelectionsClear.from((b) => b);

  factory SelectionsClear.from([void Function(SelectionsClearBuilder) updates]) = _$SelectionsClear;

  SelectionsClear._();

  static Serializer<SelectionsClear> get serializer => _$selectionsClearSerializer;
}

abstract class SelectionsAdjust
    with BuiltJsonSerializable
    implements Action2, Built<SelectionsAdjust, SelectionsAdjustBuilder> {
  bool get toggle;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionsAdjust(bool toggle) => SelectionsAdjust.from((b) => b..toggle = toggle);

  factory SelectionsAdjust.from([void Function(SelectionsAdjustBuilder) updates]) = _$SelectionsAdjust;

  SelectionsAdjust._();

  static Serializer<SelectionsAdjust> get serializer => _$selectionsAdjustSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix select (side view)

abstract class HelixSelect
    with BuiltJsonSerializable
    implements Action2, Built<HelixSelect, HelixSelectBuilder> {
  int get helix_idx;

  bool get toggle;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixSelect(int helix_idx, bool toggle) => HelixSelect.from((b) => b
    ..helix_idx = helix_idx
    ..toggle = toggle);

  factory HelixSelect.from([void Function(HelixSelectBuilder) updates]) = _$HelixSelect;

  HelixSelect._();

  static Serializer<HelixSelect> get serializer => _$helixSelectSerializer;
}

abstract class HelixSelectionsClear
    with BuiltJsonSerializable
    implements Action2, Built<HelixSelectionsClear, HelixSelectionsClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelixSelectionsClear() => HelixSelectionsClear.from((b) => b);

  factory HelixSelectionsClear.from([void Function(HelixSelectionsClearBuilder) updates]) =
      _$HelixSelectionsClear;

  HelixSelectionsClear._();

  static Serializer<HelixSelectionsClear> get serializer => _$helixSelectionsClearSerializer;
}

abstract class HelixSelectionsAdjust
    with BuiltJsonSerializable
    implements Action2, Built<HelixSelectionsAdjust, HelixSelectionsAdjustBuilder> {
  bool get toggle;

  SelectionBox get selection_box;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixSelectionsAdjust(bool toggle, SelectionBox selection_box) =>
      HelixSelectionsAdjust.from((b) => b
        ..toggle = toggle
        ..selection_box.replace(selection_box));

  factory HelixSelectionsAdjust.from([void Function(HelixSelectionsAdjustBuilder) updates]) =
      _$HelixSelectionsAdjust;

  HelixSelectionsAdjust._();

  static Serializer<HelixSelectionsAdjust> get serializer => _$helixSelectionsAdjustSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mouse position (side view)

abstract class SetShowMouseoverRect
    with BuiltJsonSerializable
    implements Action2, Built<SetShowMouseoverRect, SetShowMouseoverRectBuilder> {
  bool get show;

  /************************ begin BuiltValue boilerplate ************************/
  factory SetShowMouseoverRect(bool show) => SetShowMouseoverRect.from((b) => b..show = show);

  factory SetShowMouseoverRect.from([void Function(SetShowMouseoverRectBuilder) updates]) =
      _$SetShowMouseoverRect;

  SetShowMouseoverRect._();

  static Serializer<SetShowMouseoverRect> get serializer => _$setShowMouseoverRectSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Export SVG

abstract class ExportSvgMain
    with BuiltJsonSerializable
    implements Action2, Built<ExportSvgMain, ExportSvgMainBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory ExportSvgMain() => ExportSvgMain.from((b) => b);

  factory ExportSvgMain.from([void Function(ExportSvgMainBuilder) updates]) = _$ExportSvgMain;

  ExportSvgMain._();

  static Serializer<ExportSvgMain> get serializer => _$exportSvgMainSerializer;
}

abstract class ExportSvgSide
    with BuiltJsonSerializable
    implements Action2, Built<ExportSvgSide, ExportSvgSideBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory ExportSvgSide() => ExportSvgSide.from((b) => b);

  factory ExportSvgSide.from([void Function(ExportSvgSideBuilder) updates]) = _$ExportSvgSide;

  ExportSvgSide._();

  static Serializer<ExportSvgSide> get serializer => _$exportSvgSideSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Undo/Redo

abstract class Undo with BuiltJsonSerializable implements Action2, Built<Undo, UndoBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory Undo() => Undo.from((b) => b);

  factory Undo.from([void Function(UndoBuilder) updates]) = _$Undo;

  Undo._();

  static Serializer<Undo> get serializer => _$undoSerializer;
}

abstract class Redo with BuiltJsonSerializable implements Action2, Built<Redo, RedoBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory Redo() => Redo.from((b) => b);

  factory Redo.from([void Function(RedoBuilder) updates]) = _$Redo;

  Redo._();

  static Serializer<Redo> get serializer => _$redoSerializer;
}

abstract class UndoRedoClear
    with BuiltJsonSerializable
    implements Action2, Built<UndoRedoClear, UndoRedoClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory UndoRedoClear() => UndoRedoClear.from((b) => b);

  factory UndoRedoClear.from([void Function(UndoRedoClearBuilder) updates]) = _$UndoRedoClear;

  UndoRedoClear._();

  static Serializer<UndoRedoClear> get serializer => _$undoRedoClearSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Throttle

abstract class ThrottledAction
    with BuiltJsonSerializable
    implements Action2, Built<ThrottledAction, ThrottledActionBuilder> {
  Action2 get action;

  num get interval_sec;

  /************************ begin BuiltValue boilerplate ************************/
  factory ThrottledAction(Action2 action, num interval_sec) => ThrottledAction.from((b) => b
    ..action = action
    ..interval_sec = interval_sec);

  factory ThrottledAction.from([void Function(ThrottledActionBuilder) updates]) = _$ThrottledAction;

  ThrottledAction._();

  static Serializer<ThrottledAction> get serializer => _$throttledActionSerializer;
}

//class Actions {
//  // Save .dna file
//  *save_dna_file = Action<Null>();
//
//  // Load .dna file
//  *load_dna_file = Action<LoadDNAFileParameters>();
//
//  // Mouseover data (main view)
//  *update_mouseover_data = Action<MouseoverParameters>();
//  *remove_mouseover_data = Action<Null>();
//
//  // Side view position
//  *update_side_view_mouse_position = Action<Point<num>>();
//  *remove_side_view_mouse_position = Action<Null>();
//
//  // Helix
//  helix_use = Action<HelixUseActionParameters>();
//  set_helices = Action<List<Helix>>();
//  *set_helix_rotation = Action<SetHelixRotationActionParameters>();
//
//  // Strand
//  strand_remove = Action<Strand>();
//  strand_add = Action<Strand>();
//  strands_remove = Action<Iterable<Strand>>();
//  strands_add = Action<Iterable<Strand>>();
//
//  // Strand UI model
//  strand_select_toggle = Action<Strand>();
//  five_prime_select_toggle = Action<BoundSubstrand>();
//  three_prime_select_toggle = Action<BoundSubstrand>();
//  loopout_select_toggle = Action<Loopout>();
//  crossover_select_toggle = Action<Tuple2<BoundSubstrand, BoundSubstrand>>();
//
//  unselect_all = Action<Null>();
//  select = Action<Selectable>();
//  select_all = Action<List<Selectable>>();
//  unselect = Action<Selectable>();
//  toggle = Action<Selectable>();
//  toggle_all = Action<List<Selectable>>();
//
//  delete_all = Action<DeleteAllParameters>();
//
//  // Selection box
//  *create_selection_box_toggling = Action<Point<num>>();
//  *create_selection_box_selecting = Action<Point<num>>();
//  *selection_box_size_changed = Action<Point<num>>();
//  *remove_selection_box = Action<Null>();
//
//  // Errors (so there's no DNADesign to display, e.g., parsing error reading JSON file)
//  *set_error_message = Action<String>();
//
//  // Edit mode
//  set_edit_mode = Action<EditModeChoice>();
//
//  // Menu
//  *set_show_dna = Action<bool>();
//  *set_show_mismatches = Action<bool>();
//  *set_show_editor = Action<bool>();
//
//  // Select modes
//  *toggle_select_mode = Action<SelectModeChoice>();
//  *set_select_modes = Action<List<SelectModeChoice>>();
//
//  // all reversible dispatcher go through this Action
//  reversible_action = Action<ReversibleActionPack>();
//
//}
