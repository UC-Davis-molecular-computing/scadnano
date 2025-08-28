@JS()
library actions2;

import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
import 'package:js/js.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/dna_file_type.dart';
import 'package:scadnano/src/state/dna_assign_options.dart';
import 'package:scadnano/src/state/dna_extensions_move.dart';
import 'package:scadnano/src/state/domains_move.dart';
import 'package:scadnano/src/state/export_dna_format_strand_order.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/helix_group_move.dart';
import 'package:scadnano/src/state/vendor_fields.dart';
import 'package:scadnano/src/state/linker.dart';
import 'package:scadnano/src/state/substrand.dart';
import 'package:scadnano/src/util.dart';

import '../state/address.dart';
import '../state/app_ui_state_storables.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/group.dart';
import '../state/context_menu.dart';
import '../state/crossover.dart';
import '../state/dialog.dart';
import '../state/dna_end.dart';
import '../state/dna_ends_move.dart';
import '../state/export_dna_format.dart';
import '../state/grid.dart';
import '../state/helix.dart';
import '../state/local_storage_design_choice.dart';
import '../state/loopout.dart';
import '../state/extension.dart';
import '../state/modification.dart';
import '../state/position3d.dart';
import '../state/potential_crossover.dart';
import '../state/selectable.dart';
import '../state/selection_box.dart';
import '../state/strand.dart';
import '../state/strand_part.dart';
import '../state/strands_move.dart';
import '../state/edit_mode.dart';
import '../serializers.dart';
import '../state/select_mode.dart';
import '../state/grid_position.dart';
import '../state/mouseover_data.dart';
import '../middleware/local_storage.dart';

part 'actions.g.dart';

/// [Action]s don't have to implement BuiltValue, but if they do, and they use the serialization mechanism,
/// this this toJson method will work automatically.
abstract class Action {
  dynamic toJson();
}

// Actions that affect the DNADesign (i.e., not purely UIAppState-affecting actions such as selecting items).
// Only Undo and Redo implement this directly; all others implement the subtype UndoableAction.
mixin DesignChangingAction implements StorableAction, SvgPngCacheInvalidatingAction {
  Iterable<Storable> storables() => [Storable.design];
}

/// Undoable actions, which must affect the DNADesign, and can be undone by Ctrl+Z.
/// Previously, whether an action was a subtype of UndoableAction was used to check whether to write
/// the design to localStorage. Now, we just check whether the Design changed, but print a warning
/// if the action is not a subtype of UndoableAction. However, this subtype relationship IS still
/// currently used to detect whether to affect the undo stack.
mixin UndoableAction implements DesignChangingAction {
  Iterable<Storable> storables() => [Storable.design];

  String short_description();
}

/// Fast actions are not dispatched to normal store for optimization
abstract class FastAction extends Action {}

// Wrap an UndoableAction in a SkipUndo in order to apply it, but skip its effect on the undo/redo stacks.
abstract class SkipUndo with BuiltJsonSerializable implements Action, Built<SkipUndo, SkipUndoBuilder> {
  UndoableAction get undoable_action;

  /************************ begin BuiltValue boilerplate ************************/
  factory SkipUndo(UndoableAction undoable_action) =>
      SkipUndo.from((b) => b..undoable_action = undoable_action);

  factory SkipUndo.from([void Function(SkipUndoBuilder) updates]) = _$SkipUndo;

  SkipUndo._();

  static Serializer<SkipUndo> get serializer => _$skipUndoSerializer;
}

/// [Action] that should trigger storing of certain [Storable]s to localStorage.
abstract class StorableAction extends Action {
  Iterable<Storable> storables();
}

/// [Action] that should invalidate the svg png cache.
abstract class SvgPngCacheInvalidatingAction extends Action {}

/// [Action] that should invalidate the svg png cache only if
/// `app.ui_state.only_display_selected_helices` is on.
///
/// This is useful for helix select actions because the svg-png-cache only
/// needs to be invalidated while `only_display_selected_helices` is true.
/// Otherwise, when `only_display_selected_helices` is false, the main view
/// does not get affected from selecting helices.
abstract class HelixSelectSvgPngCacheInvalidatingAction extends Action {}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Undo/Redo

abstract class Undo with BuiltJsonSerializable, DesignChangingAction implements Built<Undo, UndoBuilder> {
  int get num_undos;

  /************************ begin BuiltValue boilerplate ************************/
  factory Undo(int num_undos) => Undo.from((b) => b..num_undos = num_undos);

  factory Undo.from([void Function(UndoBuilder) updates]) = _$Undo;

  Undo._();

  static Serializer<Undo> get serializer => _$undoSerializer;
}

abstract class Redo with BuiltJsonSerializable, DesignChangingAction implements Built<Redo, RedoBuilder> {
  int get num_redos;

  /************************ begin BuiltValue boilerplate ************************/
  factory Redo(int num_redos) => Redo.from((b) => b..num_redos = num_redos);

  factory Redo.from([void Function(RedoBuilder) updates]) = _$Redo;

  Redo._();

  static Serializer<Redo> get serializer => _$redoSerializer;
}

abstract class UndoRedoClear
    with BuiltJsonSerializable
    implements Action, Built<UndoRedoClear, UndoRedoClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory UndoRedoClear() => UndoRedoClear.from((b) => b);

  factory UndoRedoClear.from([void Function(UndoRedoClearBuilder) updates]) = _$UndoRedoClear;

  UndoRedoClear._();

  static Serializer<UndoRedoClear> get serializer => _$undoRedoClearSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Batch action

/// [Action] intended for applying >= 2 other [UndoableAction]s at once,
/// which can be undone/redone in a single step by [UndoRedo].
abstract class BatchAction with UndoableAction implements Built<BatchAction, BatchActionBuilder> {
  BuiltList<UndoableAction> get actions;

  String get short_description_value;

  /************************ begin BuiltValue boilerplate ************************/
  factory BatchAction(Iterable<UndoableAction> actions, String short_description_value) => BatchAction.from(
    (b) =>
        b
          ..actions.replace(actions)
          ..short_description_value = short_description_value,
  );

  factory BatchAction.from([void Function(BatchActionBuilder) updates]) = _$BatchAction;

  BatchAction._();

  static Serializer<BatchAction> get serializer => _$batchActionSerializer;

  @override
  dynamic toJson() => {'actions': actions.toList()};

  @override
  String short_description() => short_description_value;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Throttle

//XXX: Originally all ThrottledActions were FastActions because anything that would need to be throttled
// (>= 60 fps) was too fast to be handled by the normal React/Redux store updates. Now that we have trimmed
// the rendering time significantly (https://github.com/UC-Davis-molecular-computing/scadnano/issues/87),
// this is no longer the case. But FastAction is still used to avoid
// dispatching actions to the main store. So we need ThrottledActionNonFast to throttle actions that we still
// would like to be dispatched to the main store.
abstract class ThrottledAction implements Action {
  Action get action;

  double get interval_sec;
}

abstract class ThrottledActionFast
    with BuiltJsonSerializable
    implements ThrottledAction, FastAction, Built<ThrottledActionFast, ThrottledActionFastBuilder> {
  Action get action;

  double get interval_sec;

  /************************ begin BuiltValue boilerplate ************************/
  factory ThrottledActionFast(Action action, double interval_sec) => ThrottledActionFast.from(
    (b) =>
        b
          ..action = action
          ..interval_sec = interval_sec,
  );

  factory ThrottledActionFast.from([void Function(ThrottledActionFastBuilder) updates]) =
      _$ThrottledActionFast;

  ThrottledActionFast._();

  static Serializer<ThrottledActionFast> get serializer => _$throttledActionFastSerializer;
}

abstract class ThrottledActionNonFast
    with BuiltJsonSerializable
    implements ThrottledAction, Built<ThrottledActionNonFast, ThrottledActionNonFastBuilder> {
  Action get action;

  double get interval_sec;

  /************************ begin BuiltValue boilerplate ************************/
  factory ThrottledActionNonFast(Action action, double interval_sec) => ThrottledActionNonFast.from(
    (b) =>
        b
          ..action = action
          ..interval_sec = interval_sec,
  );

  factory ThrottledActionNonFast.from([void Function(ThrottledActionNonFastBuilder) updates]) =
      _$ThrottledActionNonFast;

  ThrottledActionNonFast._();

  static Serializer<ThrottledActionNonFast> get serializer => _$throttledActionNonFastSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// set options for when to write design to localStorage

abstract class LocalStorageDesignChoiceSet
    with BuiltJsonSerializable
    implements Action, Built<LocalStorageDesignChoiceSet, LocalStorageDesignChoiceSetBuilder> {
  LocalStorageDesignChoice get choice;

  /************************ begin BuiltValue boilerplate ************************/
  factory LocalStorageDesignChoiceSet({required LocalStorageDesignChoice choice}) =
      _$LocalStorageDesignChoiceSet._;

  LocalStorageDesignChoiceSet._();

  static Serializer<LocalStorageDesignChoiceSet> get serializer => _$localStorageDesignChoiceSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// erase localStorage stored design and storable UI settings

abstract class ResetLocalStorage
    with BuiltJsonSerializable
    implements Action, Built<ResetLocalStorage, ResetLocalStorageBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory ResetLocalStorage() = _$ResetLocalStorage._;

  ResetLocalStorage._();

  static Serializer<ResetLocalStorage> get serializer => _$resetLocalStorageSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Clear helix selection when loading new design

abstract class ClearHelixSelectionWhenLoadingNewDesignSet
    with BuiltJsonSerializable
    implements
        Action,
        Built<ClearHelixSelectionWhenLoadingNewDesignSet, ClearHelixSelectionWhenLoadingNewDesignSetBuilder> {
  bool get clear;

  /************************ begin BuiltValue boilerplate ************************/
  factory ClearHelixSelectionWhenLoadingNewDesignSet({required bool clear}) =
      _$ClearHelixSelectionWhenLoadingNewDesignSet._;

  ClearHelixSelectionWhenLoadingNewDesignSet._();

  static Serializer<ClearHelixSelectionWhenLoadingNewDesignSet> get serializer =>
      _$clearHelixSelectionWhenLoadingNewDesignSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Edit modes

abstract class EditModeToggle
    with BuiltJsonSerializable
    implements Action, Built<EditModeToggle, EditModeToggleBuilder> {
  EditModeChoice get mode;

  /************************ begin BuiltValue boilerplate ************************/
  factory EditModeToggle(EditModeChoice mode) => EditModeToggle.from((b) => b..mode = mode);

  factory EditModeToggle.from([void Function(EditModeToggleBuilder) updates]) = _$EditModeToggle;

  EditModeToggle._();

  static Serializer<EditModeToggle> get serializer => _$editModeToggleSerializer;
}

abstract class EditModesSet
    with BuiltJsonSerializable
    implements Action, Built<EditModesSet, EditModesSetBuilder> {
  BuiltSet<EditModeChoice> get edit_modes;

  /************************ begin BuiltValue boilerplate ************************/
  factory EditModesSet(Iterable<EditModeChoice> edit_modes) =>
      EditModesSet.from((b) => b..edit_modes.replace(edit_modes));

  factory EditModesSet.from([void Function(EditModesSetBuilder) updates]) = _$EditModesSet;

  EditModesSet._();

  static Serializer<EditModesSet> get serializer => _$editModesSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Select modes

abstract class SelectModeToggle
    with BuiltJsonSerializable
    implements Action, Built<SelectModeToggle, SelectModeToggleBuilder> {
  SelectModeChoice get select_mode_choice;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectModeToggle(SelectModeChoice select_mode_choice) =>
      SelectModeToggle.from((b) => b..select_mode_choice = select_mode_choice);

  factory SelectModeToggle.from([void Function(SelectModeToggleBuilder) updates]) = _$SelectModeToggle;

  SelectModeToggle._();

  static Serializer<SelectModeToggle> get serializer => _$selectModeToggleSerializer;
}

abstract class SelectModesAdd
    with BuiltJsonSerializable
    implements Action, Built<SelectModesAdd, SelectModesAddBuilder> {
  BuiltList<SelectModeChoice> get modes;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectModesAdd({required BuiltList<SelectModeChoice> modes}) = _$SelectModesAdd._;

  SelectModesAdd._();

  static Serializer<SelectModesAdd> get serializer => _$selectModesAddSerializer;
}

abstract class SelectModesSet
    with BuiltJsonSerializable
    implements Action, Built<SelectModesSet, SelectModesSetBuilder> {
  BuiltSet<SelectModeChoice> get select_mode_choices;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectModesSet(Iterable<SelectModeChoice> select_mode_choices) =>
      SelectModesSet.from((b) => b..select_mode_choices.replace(select_mode_choices));

  factory SelectModesSet.from([void Function(SelectModesSetBuilder) updates]) = _$SelectModesSet;

  SelectModesSet._();

  static Serializer<SelectModesSet> get serializer => _$selectModesSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Strand/domain/loopout names/labels

// used to set or remove (set name=null to remove)
abstract class StrandNameSet
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<StrandNameSet, StrandNameSetBuilder> {
  String? get name;

  Strand get strand;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandNameSet({String? name, required Strand strand}) = _$StrandNameSet._;

  StrandNameSet._();

  static Serializer<StrandNameSet> get serializer => _$strandNameSetSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() => "set strand name";
}

// used to set or remove (set name=null to remove)
abstract class StrandLabelSet
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<StrandLabelSet, StrandLabelSetBuilder> {
  String? get label;

  Strand get strand;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandLabelSet({String? label, required Strand strand}) = _$StrandLabelSet._;

  StrandLabelSet._();

  static Serializer<StrandLabelSet> get serializer => _$strandLabelSetSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() => "set strand label";
}

// used to set or remove (set name=null to remove)
// used for Domains, Loopouts, and Extensions
abstract class SubstrandNameSet
    with BuiltJsonSerializable, UndoableAction
    implements StrandPartAction, Built<SubstrandNameSet, SubstrandNameSetBuilder> {
  String? get name;

  Substrand get substrand;

  StrandPart get strand_part => substrand;

  /************************ begin BuiltValue boilerplate ************************/
  factory SubstrandNameSet({String? name, required Substrand substrand}) = _$SubstrandNameSet._;

  SubstrandNameSet._();

  static Serializer<SubstrandNameSet> get serializer => _$substrandNameSetSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() =>
      "${this.name == null ? 'remove' : 'set'} ${substrand.type_description()} name";
}

// used to set or remove (set name=null to remove)
// used for Domains, Loopouts, and Extensions
abstract class SubstrandLabelSet
    with BuiltJsonSerializable, UndoableAction
    implements StrandPartAction, Built<SubstrandLabelSet, SubstrandLabelSetBuilder> {
  String? get label;

  Substrand get substrand;

  StrandPart get strand_part => substrand;

  /************************ begin BuiltValue boilerplate ************************/
  factory SubstrandLabelSet({String? label, required Substrand substrand}) = _$SubstrandLabelSet._;

  SubstrandLabelSet._();

  static Serializer<SubstrandLabelSet> get serializer => _$substrandLabelSetSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() =>
      "${this.label == null ? 'remove' : 'set'} ${substrand.type_description()} label";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Show/hide DNA/modifications/mismatches/domain labels/editor
abstract class SetAppUIStateStorable
    with BuiltJsonSerializable
    implements Action, Built<SetAppUIStateStorable, SetAppUIStateStorableBuilder> {
  AppUIStateStorables get storables;

  factory SetAppUIStateStorable(AppUIStateStorables storables) =>
      SetAppUIStateStorable.from((b) => b..storables = storables.toBuilder());

  /************************ begin BuiltValue boilerplate ************************/
  factory SetAppUIStateStorable.from([void Function(SetAppUIStateStorableBuilder) updates]) =
      _$SetAppUIStateStorable;

  SetAppUIStateStorable._();

  static Serializer<SetAppUIStateStorable> get serializer => _$setAppUIStateStorableSerializer;
}

abstract class ShowDNASet with BuiltJsonSerializable implements Action, Built<ShowDNASet, ShowDNASetBuilder> {
  bool get show;

  factory ShowDNASet(bool show) => ShowDNASet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowDNASet.from([void Function(ShowDNASetBuilder) updates]) = _$ShowDNASet;

  ShowDNASet._();

  static Serializer<ShowDNASet> get serializer => _$showDNASetSerializer;
}

abstract class ShowDomainNamesSet
    with BuiltJsonSerializable
    implements Action, Built<ShowDomainNamesSet, ShowDomainNamesSetBuilder> {
  bool get show;

  factory ShowDomainNamesSet(bool show) => ShowDomainNamesSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowDomainNamesSet.from([void Function(ShowDomainNamesSetBuilder) updates]) = _$ShowDomainNamesSet;

  ShowDomainNamesSet._();

  static Serializer<ShowDomainNamesSet> get serializer => _$showDomainNamesSetSerializer;
}

abstract class ShowStrandNamesSet
    with BuiltJsonSerializable
    implements Action, Built<ShowStrandNamesSet, ShowStrandNamesSetBuilder> {
  bool get show;

  factory ShowStrandNamesSet(bool show) => ShowStrandNamesSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowStrandNamesSet.from([void Function(ShowStrandNamesSetBuilder) updates]) = _$ShowStrandNamesSet;

  ShowStrandNamesSet._();

  static Serializer<ShowStrandNamesSet> get serializer => _$showStrandNamesSetSerializer;
}

abstract class ShowStrandLabelsSet
    with BuiltJsonSerializable
    implements Action, Built<ShowStrandLabelsSet, ShowStrandLabelsSetBuilder> {
  bool get show;

  factory ShowStrandLabelsSet(bool show) => ShowStrandLabelsSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowStrandLabelsSet.from([void Function(ShowStrandLabelsSetBuilder) updates]) =
      _$ShowStrandLabelsSet;

  ShowStrandLabelsSet._();

  static Serializer<ShowStrandLabelsSet> get serializer => _$showStrandLabelsSetSerializer;
}

abstract class ShowDomainLabelsSet
    with BuiltJsonSerializable
    implements Action, Built<ShowDomainLabelsSet, ShowDomainLabelsSetBuilder> {
  bool get show;

  factory ShowDomainLabelsSet(bool show) => ShowDomainLabelsSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowDomainLabelsSet.from([void Function(ShowDomainLabelsSetBuilder) updates]) =
      _$ShowDomainLabelsSet;

  ShowDomainLabelsSet._();

  static Serializer<ShowDomainLabelsSet> get serializer => _$showDomainLabelsSetSerializer;
}

abstract class ShowModificationsSet
    with BuiltJsonSerializable
    implements Action, Built<ShowModificationsSet, ShowModificationsSetBuilder> {
  bool get show;

  factory ShowModificationsSet(bool show) => ShowModificationsSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowModificationsSet.from([void Function(ShowModificationsSetBuilder) updates]) =
      _$ShowModificationsSet;

  ShowModificationsSet._();

  static Serializer<ShowModificationsSet> get serializer => _$showModificationsSetSerializer;
}

abstract class DomainNameFontSizeSet
    with BuiltJsonSerializable
    implements Action, Built<DomainNameFontSizeSet, DomainNameFontSizeSetBuilder> {
  double get font_size;

  /************************ begin BuiltValue boilerplate ************************/
  factory DomainNameFontSizeSet({required double font_size}) = _$DomainNameFontSizeSet._;

  DomainNameFontSizeSet._();

  static Serializer<DomainNameFontSizeSet> get serializer => _$domainNameFontSizeSetSerializer;
}

abstract class DomainLabelFontSizeSet
    with BuiltJsonSerializable
    implements Action, Built<DomainLabelFontSizeSet, DomainLabelFontSizeSetBuilder> {
  double get font_size;

  /************************ begin BuiltValue boilerplate ************************/
  factory DomainLabelFontSizeSet({required double font_size}) = _$DomainLabelFontSizeSet._;

  DomainLabelFontSizeSet._();

  static Serializer<DomainLabelFontSizeSet> get serializer => _$domainLabelFontSizeSetSerializer;
}

abstract class StrandNameFontSizeSet
    with BuiltJsonSerializable
    implements Action, Built<StrandNameFontSizeSet, StrandNameFontSizeSetBuilder> {
  double get font_size;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandNameFontSizeSet({required double font_size}) = _$StrandNameFontSizeSet._;

  StrandNameFontSizeSet._();

  static Serializer<StrandNameFontSizeSet> get serializer => _$strandNameFontSizeSetSerializer;
}

abstract class StrandLabelFontSizeSet
    with BuiltJsonSerializable
    implements Action, Built<StrandLabelFontSizeSet, StrandLabelFontSizeSetBuilder> {
  double get font_size;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandLabelFontSizeSet({required double font_size}) = _$StrandLabelFontSizeSet._;

  StrandLabelFontSizeSet._();

  static Serializer<StrandLabelFontSizeSet> get serializer => _$strandLabelFontSizeSetSerializer;
}

abstract class ModificationFontSizeSet
    with BuiltJsonSerializable
    implements Action, Built<ModificationFontSizeSet, ModificationFontSizeSetBuilder> {
  double get font_size;

  factory ModificationFontSizeSet(double font_size) =>
      ModificationFontSizeSet.from((b) => b..font_size = font_size);

  /************************ begin BuiltValue boilerplate ************************/
  factory ModificationFontSizeSet.from([void Function(ModificationFontSizeSetBuilder) updates]) =
      _$ModificationFontSizeSet;

  ModificationFontSizeSet._();

  static Serializer<ModificationFontSizeSet> get serializer => _$modificationFontSizeSetSerializer;
}

abstract class MajorTickOffsetFontSizeSet
    with BuiltJsonSerializable
    implements Action, Built<MajorTickOffsetFontSizeSet, MajorTickOffsetFontSizeSetBuilder> {
  double get font_size;

  factory MajorTickOffsetFontSizeSet(double font_size) =>
      MajorTickOffsetFontSizeSet.from((b) => b..font_size = font_size);

  /************************ begin BuiltValue boilerplate ************************/
  factory MajorTickOffsetFontSizeSet.from([void Function(MajorTickOffsetFontSizeSetBuilder) updates]) =
      _$MajorTickOffsetFontSizeSet;

  MajorTickOffsetFontSizeSet._();

  static Serializer<MajorTickOffsetFontSizeSet> get serializer => _$majorTickOffsetFontSizeSetSerializer;
}

abstract class MajorTickWidthFontSizeSet
    with BuiltJsonSerializable
    implements Action, Built<MajorTickWidthFontSizeSet, MajorTickWidthFontSizeSetBuilder> {
  double get font_size;

  factory MajorTickWidthFontSizeSet(double font_size) =>
      MajorTickWidthFontSizeSet.from((b) => b..font_size = font_size);

  /************************ begin BuiltValue boilerplate ************************/
  factory MajorTickWidthFontSizeSet.from([void Function(MajorTickWidthFontSizeSetBuilder) updates]) =
      _$MajorTickWidthFontSizeSet;

  MajorTickWidthFontSizeSet._();

  static Serializer<MajorTickWidthFontSizeSet> get serializer => _$majorTickWidthFontSizeSetSerializer;
}

abstract class SetModificationDisplayConnector
    with BuiltJsonSerializable
    implements Action, Built<SetModificationDisplayConnector, SetModificationDisplayConnectorBuilder> {
  bool get show;

  factory SetModificationDisplayConnector(bool show) =>
      SetModificationDisplayConnector.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory SetModificationDisplayConnector.from([
    void Function(SetModificationDisplayConnectorBuilder) updates,
  ]) = _$SetModificationDisplayConnector;

  SetModificationDisplayConnector._();

  static Serializer<SetModificationDisplayConnector> get serializer =>
      _$setModificationDisplayConnectorSerializer;
}

abstract class ShowMismatchesSet
    with BuiltJsonSerializable
    implements Action, Built<ShowMismatchesSet, ShowMismatchesSetBuilder> {
  bool get show;

  factory ShowMismatchesSet(bool show) => ShowMismatchesSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowMismatchesSet.from([void Function(ShowMismatchesSetBuilder) updates]) = _$ShowMismatchesSet;

  ShowMismatchesSet._();

  static Serializer<ShowMismatchesSet> get serializer => _$showMismatchesSetSerializer;
}

abstract class ShowDomainNameMismatchesSet
    with BuiltJsonSerializable
    implements Action, Built<ShowDomainNameMismatchesSet, ShowDomainNameMismatchesSetBuilder> {
  bool get show_domain_name_mismatches;

  factory ShowDomainNameMismatchesSet(bool show_domain_name_mismatches) =>
      ShowDomainNameMismatchesSet.from((b) => b..show_domain_name_mismatches = show_domain_name_mismatches);

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowDomainNameMismatchesSet.from([void Function(ShowDomainNameMismatchesSetBuilder) updates]) =
      _$ShowDomainNameMismatchesSet;

  ShowDomainNameMismatchesSet._();

  static Serializer<ShowDomainNameMismatchesSet> get serializer => _$showDomainNameMismatchesSetSerializer;
}

abstract class ShowUnpairedInsertionDeletionsSet
    with BuiltJsonSerializable
    implements Action, Built<ShowUnpairedInsertionDeletionsSet, ShowUnpairedInsertionDeletionsSetBuilder> {
  bool get show_unpaired_insertion_deletions;

  factory ShowUnpairedInsertionDeletionsSet(bool show_unpaired_insertion_deletions) =>
      ShowUnpairedInsertionDeletionsSet.from(
        (b) => b..show_unpaired_insertion_deletions = show_unpaired_insertion_deletions,
      );

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowUnpairedInsertionDeletionsSet.from([
    void Function(ShowUnpairedInsertionDeletionsSetBuilder) updates,
  ]) = _$ShowUnpairedInsertionDeletionsSet;

  ShowUnpairedInsertionDeletionsSet._();

  static Serializer<ShowUnpairedInsertionDeletionsSet> get serializer =>
      _$showUnpairedInsertionDeletionsSetSerializer;
}

abstract class OxviewShowSet
    with BuiltJsonSerializable
    implements Action, Built<OxviewShowSet, OxviewShowSetBuilder> {
  bool get show;

  factory OxviewShowSet(bool show) => OxviewShowSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory OxviewShowSet.from([void Function(OxviewShowSetBuilder) updates]) = _$OxviewShowSet;

  OxviewShowSet._();

  static Serializer<OxviewShowSet> get serializer => _$oxviewShowSetSerializer;
}

abstract class SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix
    with BuiltJsonSerializable
    implements
        Action,
        Built<
          SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix,
          SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelixBuilder
        > {
  bool get show;

  factory SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix(bool show) =>
      SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix.from([
    void Function(SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelixBuilder) updates,
  ]) = _$SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix;

  SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix._();

  static Serializer<SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix> get serializer =>
      _$setDisplayBaseOffsetsOfMajorTicksOnlyFirstHelixSerializer;
}

abstract class DisplayMajorTicksOffsetsSet
    with BuiltJsonSerializable
    implements Action, Built<DisplayMajorTicksOffsetsSet, DisplayMajorTicksOffsetsSetBuilder> {
  bool get show;

  factory DisplayMajorTicksOffsetsSet(bool show) => DisplayMajorTicksOffsetsSet.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory DisplayMajorTicksOffsetsSet.from([void Function(DisplayMajorTicksOffsetsSetBuilder) updates]) =
      _$DisplayMajorTicksOffsetsSet;

  DisplayMajorTicksOffsetsSet._();

  static Serializer<DisplayMajorTicksOffsetsSet> get serializer => _$displayMajorTicksOffsetsSetSerializer;
}

abstract class SetDisplayMajorTickWidthsAllHelices
    with BuiltJsonSerializable
    implements
        Action,
        Built<SetDisplayMajorTickWidthsAllHelices, SetDisplayMajorTickWidthsAllHelicesBuilder> {
  bool get show;

  factory SetDisplayMajorTickWidthsAllHelices(bool show) =>
      SetDisplayMajorTickWidthsAllHelices.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory SetDisplayMajorTickWidthsAllHelices.from([
    void Function(SetDisplayMajorTickWidthsAllHelicesBuilder) updates,
  ]) = _$SetDisplayMajorTickWidthsAllHelices;

  SetDisplayMajorTickWidthsAllHelices._();

  static Serializer<SetDisplayMajorTickWidthsAllHelices> get serializer =>
      _$setDisplayMajorTickWidthsAllHelicesSerializer;
}

abstract class SetDisplayMajorTickWidths
    with BuiltJsonSerializable
    implements Action, Built<SetDisplayMajorTickWidths, SetDisplayMajorTickWidthsBuilder> {
  bool get show;

  factory SetDisplayMajorTickWidths(bool show) => SetDisplayMajorTickWidths.from((b) => b..show = show);

  /************************ begin BuiltValue boilerplate ************************/
  factory SetDisplayMajorTickWidths.from([void Function(SetDisplayMajorTickWidthsBuilder) updates]) =
      _$SetDisplayMajorTickWidths;

  SetDisplayMajorTickWidths._();

  static Serializer<SetDisplayMajorTickWidths> get serializer => _$setDisplayMajorTickWidthsSerializer;
}

abstract class SetOnlyDisplaySelectedHelices
    with BuiltJsonSerializable
    implements
        Action,
        SvgPngCacheInvalidatingAction,
        Built<SetOnlyDisplaySelectedHelices, SetOnlyDisplaySelectedHelicesBuilder> {
  bool get only_display_selected_helices;

  factory SetOnlyDisplaySelectedHelices(bool only_display_selected_helices) =>
      SetOnlyDisplaySelectedHelices.from(
        (b) => b..only_display_selected_helices = only_display_selected_helices,
      );

  /************************ begin BuiltValue boilerplate ************************/
  factory SetOnlyDisplaySelectedHelices.from([void Function(SetOnlyDisplaySelectedHelicesBuilder) updates]) =
      _$SetOnlyDisplaySelectedHelices;

  SetOnlyDisplaySelectedHelices._();

  static Serializer<SetOnlyDisplaySelectedHelices> get serializer =>
      _$setOnlyDisplaySelectedHelicesSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// invert y-axis

abstract class InvertYSet
    with BuiltJsonSerializable
    implements Action, SvgPngCacheInvalidatingAction, Built<InvertYSet, InvertYSetBuilder> {
  bool get invert_y;

  /************************ begin BuiltValue boilerplate ************************/
  factory InvertYSet({required bool invert_y}) = _$InvertYSet._;

  InvertYSet._();

  static Serializer<InvertYSet> get serializer => _$invertYSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// dynamically update helices

abstract class DynamicHelixUpdateSet
    with BuiltJsonSerializable
    implements
        Action,
        SvgPngCacheInvalidatingAction,
        Built<DynamicHelixUpdateSet, DynamicHelixUpdateSetBuilder> {
  bool get dynamically_update_helices;

  /************************ begin BuiltValue boilerplate ************************/
  factory DynamicHelixUpdateSet({required bool dynamically_update_helices}) = _$DynamicHelixUpdateSet._;

  DynamicHelixUpdateSet._();

  static Serializer<DynamicHelixUpdateSet> get serializer => _$dynamicHelixUpdateSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// warn on exit if unsaved

abstract class WarnOnExitIfUnsavedSet
    with BuiltJsonSerializable
    implements Action, Built<WarnOnExitIfUnsavedSet, WarnOnExitIfUnsavedSetBuilder> {
  bool get warn;

  /************************ begin BuiltValue boilerplate ************************/
  factory WarnOnExitIfUnsavedSet({required bool warn}) = _$WarnOnExitIfUnsavedSet._;

  WarnOnExitIfUnsavedSet._();

  static Serializer<WarnOnExitIfUnsavedSet> get serializer => _$warnOnExitIfUnsavedSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// loading DNA files

abstract class LoadingDialogShow
    with BuiltJsonSerializable
    implements Action, Built<LoadingDialogShow, LoadingDialogShowBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory LoadingDialogShow() = _$LoadingDialogShow._;

  LoadingDialogShow._();

  static Serializer<LoadingDialogShow> get serializer => _$loadingDialogShowSerializer;
}

abstract class LoadingDialogHide
    with BuiltJsonSerializable
    implements Action, Built<LoadingDialogHide, LoadingDialogHideBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory LoadingDialogHide() = _$LoadingDialogHide._;

  LoadingDialogHide._();

  static Serializer<LoadingDialogHide> get serializer => _$loadingDialogHideSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copy SVG to clipboard

abstract class CopySelectedStandsToClipboardImage
    with BuiltJsonSerializable
    implements Action, Built<CopySelectedStandsToClipboardImage, CopySelectedStandsToClipboardImageBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory CopySelectedStandsToClipboardImage([
    void Function(CopySelectedStandsToClipboardImageBuilder) updates,
  ]) = _$CopySelectedStandsToClipboardImage;

  CopySelectedStandsToClipboardImage._();

  static Serializer<CopySelectedStandsToClipboardImage> get serializer =>
      _$copySelectedStandsToClipboardImageSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Save/load files

abstract class SaveDNAFile
    with BuiltJsonSerializable
    implements Action, Built<SaveDNAFile, SaveDNAFileBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SaveDNAFile([void Function(SaveDNAFileBuilder) updates]) = _$SaveDNAFile;

  SaveDNAFile._();

  static Serializer<SaveDNAFile> get serializer => _$saveDNAFileSerializer;
}

abstract class LoadDNAFile
    with BuiltJsonSerializable, DesignChangingAction
    implements Action, Built<LoadDNAFile, LoadDNAFileBuilder> {
  String get content;

  bool get write_local_storage;

  bool get unit_testing;

  DNAFileType get dna_file_type;

  // set to null when getting file from another source such as localStorage
  String? get filename;

  /************************ begin BuiltValue boilerplate ************************/
  factory LoadDNAFile({
    required String content,
    String? filename,
    bool write_local_storage = true,
    bool unit_testing = false,
    DNAFileType dna_file_type = DNAFileType.scadnano_file,
  }) {
    return LoadDNAFile.from(
      (b) =>
          b
            ..content = content
            ..filename = filename
            ..write_local_storage = write_local_storage
            ..unit_testing = unit_testing
            ..dna_file_type = dna_file_type,
    );
  }

  factory LoadDNAFile.from([void Function(LoadDNAFileBuilder) updates]) = _$LoadDNAFile;

  LoadDNAFile._();

  static Serializer<LoadDNAFile> get serializer => _$loadDNAFileSerializer;
}

abstract class PrepareToLoadDNAFile
    with BuiltJsonSerializable, DesignChangingAction
    implements Action, Built<PrepareToLoadDNAFile, PrepareToLoadDNAFileBuilder> {
  String get content;

  bool get write_local_storage;

  bool get unit_testing;

  DNAFileType get dna_file_type;

  // set to null when getting file from another source such as localStorage
  String? get filename;

  /************************ begin BuiltValue boilerplate ************************/
  factory PrepareToLoadDNAFile({
    required String content,
    String? filename,
    bool write_local_storage = true,
    bool unit_testing = false,
    DNAFileType dna_file_type = DNAFileType.scadnano_file,
  }) {
    return PrepareToLoadDNAFile.from(
      (b) =>
          b
            ..content = content
            ..filename = filename
            ..write_local_storage = write_local_storage
            ..unit_testing = unit_testing
            ..dna_file_type = dna_file_type,
    );
  }

  factory PrepareToLoadDNAFile.from([void Function(PrepareToLoadDNAFileBuilder) updates]) =
      _$PrepareToLoadDNAFile;

  PrepareToLoadDNAFile._();

  static Serializer<PrepareToLoadDNAFile> get serializer => _$prepareToLoadDNAFileSerializer;
}

abstract class NewDesignSet
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<NewDesignSet, NewDesignSetBuilder> {
  Design get design;

  String get short_description_value;

  /************************ begin BuiltValue boilerplate ************************/
  factory NewDesignSet(Design design, String short_description_value) {
    return NewDesignSet.from(
      (b) =>
          b
            ..design.replace(design)
            ..short_description_value = short_description_value,
    );
  }

  factory NewDesignSet.from([void Function(NewDesignSetBuilder) updates]) = _$NewDesignSet;

  NewDesignSet._();

  static Serializer<NewDesignSet> get serializer => _$newDesignSetSerializer;

  @override
  String short_description() => short_description_value;
}

abstract class ExportCadnanoFile
    with BuiltJsonSerializable
    implements Action, Built<ExportCadnanoFile, ExportCadnanoFileBuilder> {
  bool get whitespace;

  /************************ begin BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  factory ExportCadnanoFile({required bool whitespace}) = _$ExportCadnanoFile._;

  factory ExportCadnanoFile.from([void Function(ExportCadnanoFileBuilder) updates]) = _$ExportCadnanoFile;

  ExportCadnanoFile._();

  static Serializer<ExportCadnanoFile> get serializer => _$exportCadnanoFileSerializer;
}

abstract class ExportCodenanoFile
    with BuiltJsonSerializable
    implements Action, Built<ExportCodenanoFile, ExportCodenanoFileBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory ExportCodenanoFile([void Function(ExportCodenanoFileBuilder) updates]) = _$ExportCodenanoFile;

  ExportCodenanoFile._();

  static Serializer<ExportCodenanoFile> get serializer => _$exportCodenanoFileSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mouseover data (main view)

abstract class ShowMouseoverDataSet
    with BuiltJsonSerializable
    implements Action, Built<ShowMouseoverDataSet, ShowMouseoverDataSetBuilder> {
  bool get show;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowMouseoverDataSet(bool show) => ShowMouseoverDataSet.from((b) => b..show = show);

  factory ShowMouseoverDataSet.from([void Function(ShowMouseoverDataSetBuilder) updates]) =
      _$ShowMouseoverDataSet;

  ShowMouseoverDataSet._();

  static Serializer<ShowMouseoverDataSet> get serializer => _$showMouseoverDataSetSerializer;
}

abstract class MouseoverDataClear
    with BuiltJsonSerializable
    implements Action, Built<MouseoverDataClear, MouseoverDataClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverDataClear([void Function(MouseoverDataClearBuilder) updates]) = _$MouseoverDataClear;

  MouseoverDataClear._();

  static Serializer<MouseoverDataClear> get serializer => _$mouseoverDataClearSerializer;
}

abstract class MouseoverDataUpdate
    with BuiltJsonSerializable
    implements Action, Built<MouseoverDataUpdate, MouseoverDataUpdateBuilder> {
  BuiltList<MouseoverParams> get mouseover_params;

  factory MouseoverDataUpdate({required BuiltList<MouseoverParams> mouseover_params}) =
      _$MouseoverDataUpdate._;

  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverDataUpdate.from([void Function(MouseoverDataUpdateBuilder) updates]) =
      _$MouseoverDataUpdate;

  MouseoverDataUpdate._();

  static Serializer<MouseoverDataUpdate> get serializer => _$mouseoverDataUpdateSerializer;
}

// set helix roll
abstract class HelixRollSet
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixRollSet, HelixRollSetBuilder> {
  int get helix_idx;

  double get roll;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixRollSet({required int helix_idx, required double roll}) = _$HelixRollSet._;

  HelixRollSet._();

  static Serializer<HelixRollSet> get serializer => _$helixRollSetSerializer;

  @override
  String short_description() => "set helix roll";
}

// set helix roll such that rotation at anchor points at helix_other
abstract class HelixRollSetAtOther
    with BuiltJsonSerializable, UndoableAction
    implements Built<HelixRollSetAtOther, HelixRollSetAtOtherBuilder> {
  int get helix_idx;

  int get helix_other_idx;

  bool get forward;

  int get anchor;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixRollSetAtOther(int helix_idx, int helix_other_idx, bool forward, int anchor) =>
      HelixRollSetAtOther.from(
        (b) =>
            b
              ..helix_idx = helix_idx
              ..helix_other_idx = helix_other_idx
              ..forward = forward
              ..anchor = anchor,
      );

  factory HelixRollSetAtOther.from([void Function(HelixRollSetAtOtherBuilder) updates]) =
      _$HelixRollSetAtOther;

  HelixRollSetAtOther._();

  static Serializer<HelixRollSetAtOther> get serializer => _$helixRollSetAtOtherSerializer;

  @override
  String short_description() {
    return "set helix roll at other";
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// relax helix rolls

abstract class RelaxHelixRolls
    with BuiltJsonSerializable, UndoableAction
    implements Built<RelaxHelixRolls, RelaxHelixRollsBuilder> {
  bool get only_selected;

  /************************ begin BuiltValue boilerplate ************************/
  factory RelaxHelixRolls({required bool only_selected}) = _$RelaxHelixRolls._;

  RelaxHelixRolls._();

  static Serializer<RelaxHelixRolls> get serializer => _$relaxHelixRollsSerializer;

  @override
  String short_description() {
    return "set helix rolls to unstrain crossovers";
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Error message

abstract class ErrorMessageSet
    with BuiltJsonSerializable
    implements Action, Built<ErrorMessageSet, ErrorMessageSetBuilder> {
  String? get error_message;

  /************************ begin BuiltValue boilerplate ************************/
  factory ErrorMessageSet(String error_message) =>
      ErrorMessageSet.from((b) => b..error_message = error_message);

  factory ErrorMessageSet.from([void Function(ErrorMessageSetBuilder) updates]) = _$ErrorMessageSet;

  ErrorMessageSet._();

  static Serializer<ErrorMessageSet> get serializer => _$errorMessageSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Selection box

abstract class SelectionBoxCreate
    with BuiltJsonSerializable
    implements Action, Built<SelectionBoxCreate, SelectionBoxCreateBuilder> {
  Point<double> get point;

  bool get toggle;

  bool get is_main;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxCreate(Point<double> point, bool toggle, bool is_main) => SelectionBoxCreate.from(
    (b) =>
        b
          ..point = point
          ..toggle = toggle
          ..is_main = is_main,
  );

  factory SelectionBoxCreate.from([void Function(SelectionBoxCreateBuilder) updates]) = _$SelectionBoxCreate;

  SelectionBoxCreate._();

  static Serializer<SelectionBoxCreate> get serializer => _$selectionBoxCreateSerializer;
}

abstract class SelectionBoxSizeChange
    with BuiltJsonSerializable
    implements FastAction, Built<SelectionBoxSizeChange, SelectionBoxSizeChangeBuilder> {
  Point<double> get point;

  bool get is_main;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxSizeChange(Point<double> point, bool is_main) => SelectionBoxSizeChange.from(
    (b) =>
        b
          ..point = point
          ..is_main = is_main,
  );

  factory SelectionBoxSizeChange.from([void Function(SelectionBoxSizeChangeBuilder) updates]) =
      _$SelectionBoxSizeChange;

  SelectionBoxSizeChange._();

  static Serializer<SelectionBoxSizeChange> get serializer => _$selectionBoxSizeChangeSerializer;
}

abstract class SelectionBoxRemove
    with BuiltJsonSerializable
    implements Action, Built<SelectionBoxRemove, SelectionBoxRemoveBuilder> {
  bool get is_main;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxRemove(bool is_main) => SelectionBoxRemove.from((b) => b..is_main = is_main);

  factory SelectionBoxRemove.from([void Function(SelectionBoxRemoveBuilder) updates]) = _$SelectionBoxRemove;

  SelectionBoxRemove._();

  static Serializer<SelectionBoxRemove> get serializer => _$selectionBoxRemoveSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Selection rope (polygon that user can create by holding Ctrl or Shift key in rope select mode
//                 while clicking several points to draw a polygon)

// This doesn't actually create any points yet, it just sets up listening.
// When the first point is clicked, we can start populating,
// and also know whether it's the main or side view.
abstract class SelectionRopeCreate
    with BuiltJsonSerializable
    implements Action, Built<SelectionRopeCreate, SelectionRopeCreateBuilder> {
  bool get toggle;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionRopeCreate({required bool toggle}) = _$SelectionRopeCreate._;

  SelectionRopeCreate._();

  static Serializer<SelectionRopeCreate> get serializer => _$selectionRopeCreateSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectionRopeMouseMove
    with BuiltJsonSerializable
    implements FastAction, Built<SelectionRopeMouseMove, SelectionRopeMouseMoveBuilder> {
  Point<double> get point;

  bool get is_main_view;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionRopeMouseMove({required Point<double> point, required bool is_main_view}) =
      _$SelectionRopeMouseMove._;

  SelectionRopeMouseMove._();

  static Serializer<SelectionRopeMouseMove> get serializer => _$selectionRopeMouseMoveSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectionRopeAddPoint
    with BuiltJsonSerializable
    implements Action, Built<SelectionRopeAddPoint, SelectionRopeAddPointBuilder> {
  Point<double> get point;

  bool get is_main_view;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionRopeAddPoint({required Point<double> point, required bool is_main_view}) =
      _$SelectionRopeAddPoint._;

  SelectionRopeAddPoint._();

  static Serializer<SelectionRopeAddPoint> get serializer => _$selectionRopeAddPointSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectionRopeRemove
    with BuiltJsonSerializable
    implements Action, Built<SelectionRopeRemove, SelectionRopeRemoveBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionRopeRemove() = _$SelectionRopeRemove._;

  SelectionRopeRemove._();

  static Serializer<SelectionRopeRemove> get serializer => _$selectionRopeRemoveSerializer;

  @memoized
  int get hashCode;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mouse position/grid position (side view)

abstract class MouseGridPositionSideUpdate
    with BuiltJsonSerializable
    implements Action, Built<MouseGridPositionSideUpdate, MouseGridPositionSideUpdateBuilder> {
  GridPosition get grid_position;

  /************************ begin BuiltValue boilerplate ************************/
  factory MouseGridPositionSideUpdate(GridPosition grid_position) =>
      MouseGridPositionSideUpdate.from((b) => b..grid_position.replace(grid_position));

  factory MouseGridPositionSideUpdate.from([void Function(MouseGridPositionSideUpdateBuilder) updates]) =
      _$MouseGridPositionSideUpdate;

  MouseGridPositionSideUpdate._();

  static Serializer<MouseGridPositionSideUpdate> get serializer => _$mouseGridPositionSideUpdateSerializer;
}

abstract class MouseGridPositionSideClear
    with BuiltJsonSerializable
    implements Action, Built<MouseGridPositionSideClear, MouseGridPositionSideClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory MouseGridPositionSideClear() => MouseGridPositionSideClear.from((b) => b);

  factory MouseGridPositionSideClear.from([void Function(MouseGridPositionSideClearBuilder) updates]) =
      _$MouseGridPositionSideClear;

  MouseGridPositionSideClear._();

  static Serializer<MouseGridPositionSideClear> get serializer => _$mouseGridPositionSideClearSerializer;
}

abstract class MousePositionSideUpdate
    with BuiltJsonSerializable
    implements Action, Built<MousePositionSideUpdate, MousePositionSideUpdateBuilder> {
  Point<double> get svg_pos;

  /************************ begin BuiltValue boilerplate ************************/
  factory MousePositionSideUpdate({required Point<double> svg_pos}) = _$MousePositionSideUpdate._;

  MousePositionSideUpdate._();

  static Serializer<MousePositionSideUpdate> get serializer => _$mousePositionSideUpdateSerializer;
}

abstract class MousePositionSideClear
    with BuiltJsonSerializable
    implements Action, Built<MousePositionSideClear, MousePositionSideClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory MousePositionSideClear() = _$MousePositionSideClear;

  MousePositionSideClear._();

  static Serializer<MousePositionSideClear> get serializer => _$mousePositionSideClearSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// geometry

abstract class GeometrySet
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<GeometrySet, GeometrySetBuilder> {
  Geometry get geometry;

  /************************ begin BuiltValue boilerplate ************************/
  factory GeometrySet({required Geometry geometry}) = _$GeometrySet._;

  GeometrySet._();

  static Serializer<GeometrySet> get serializer => _$geometrySetSerializer;

  @override
  String short_description() => "set geometric parameters";
}

abstract class GeometryHelixGroupSet
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<GeometryHelixGroupSet, GeometryHelixGroupSetBuilder> {
  String get group_name;

  Geometry get geometry;

  /************************ begin BuiltValue boilerplate ************************/
  factory GeometryHelixGroupSet({required String group_name, required Geometry geometry}) =
      _$GeometryHelixGroupSet._;

  GeometryHelixGroupSet._();

  static Serializer<GeometryHelixGroupSet> get serializer => _$geometryHelixGroupSetSerializer;

  @override
  String short_description() => "set helix group geometric parameters ";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Selectables

// If intersect is true, then any object intersecting the selection box is selected.
// If intersect is false, then any object contained in the selectin box is selected.
abstract class SelectionBoxIntersectionRuleSet
    with BuiltJsonSerializable
    implements Action, Built<SelectionBoxIntersectionRuleSet, SelectionBoxIntersectionRuleSetBuilder> {
  bool get intersect;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionBoxIntersectionRuleSet({required bool intersect}) = _$SelectionBoxIntersectionRuleSet._;

  SelectionBoxIntersectionRuleSet._();

  static Serializer<SelectionBoxIntersectionRuleSet> get serializer =>
      _$selectionBoxIntersectionRuleSetSerializer;

  @memoized
  int get hashCode;
}

abstract class Select with BuiltJsonSerializable implements Action, Built<Select, SelectBuilder> {
  Selectable get selectable;

  // if true, negate current selection status; otherwise set to be selected irrespective of previous status
  bool get toggle;

  // if true, deselect all other items and select only this object; otherwise leave other selections alone
  bool get only;

  /************************ begin BuiltValue boilerplate ************************/
  factory Select(Selectable selectable, {required bool toggle, bool only = false}) => Select.from(
    (b) =>
        b
          ..selectable = selectable
          ..toggle = toggle
          ..only = only,
  );

  factory Select.from([void Function(SelectBuilder) updates]) = _$Select;

  Select._();

  static Serializer<Select> get serializer => _$selectSerializer;
}

abstract class SelectionsClear
    with BuiltJsonSerializable
    implements Action, Built<SelectionsClear, SelectionsClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionsClear() => SelectionsClear.from((b) => b);

  factory SelectionsClear.from([void Function(SelectionsClearBuilder) updates]) = _$SelectionsClear;

  SelectionsClear._();

  static Serializer<SelectionsClear> get serializer => _$selectionsClearSerializer;
}

// dispatched in response to Selection box being done drawing (i.e., mouse button goes up),
// but needs to be intercepted by middleware, which queries the DOM to see what Selectable
// SVG objects intersect the box, and then constructs a SelectOrToggleAll action with those objects
abstract class SelectionsAdjustMainView
    with BuiltJsonSerializable
    implements Action, Built<SelectionsAdjustMainView, SelectionsAdjustMainViewBuilder> {
  bool get toggle;

  // if true, use selection box to calculate selected items, otherwise use selection rope
  bool get box;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectionsAdjustMainView({required bool toggle, required bool box}) = _$SelectionsAdjustMainView._;

  factory SelectionsAdjustMainView.from([void Function(SelectionsAdjustMainViewBuilder) updates]) =
      _$SelectionsAdjustMainView;

  SelectionsAdjustMainView._();

  static Serializer<SelectionsAdjustMainView> get serializer => _$selectionsAdjustMainViewSerializer;
}

abstract class SelectOrToggleItems
    with BuiltJsonSerializable
    implements Action, Built<SelectOrToggleItems, SelectOrToggleItemsBuilder> {
  BuiltList<Selectable> get items;

  bool get toggle;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectOrToggleItems({required BuiltList<Selectable> items, required bool toggle}) =
      _$SelectOrToggleItems._;

  SelectOrToggleItems._();

  static Serializer<SelectOrToggleItems> get serializer => _$selectOrToggleItemsSerializer;
}

// This selects all that are specified in constructor. SelectAllSelectable selects all selectable items
// in the whole design.
abstract class SelectAll with BuiltJsonSerializable implements Action, Built<SelectAll, SelectAllBuilder> {
  BuiltList<Selectable> get selectables;

  // if true, deselect all other items and select only this object; otherwise leave other selections alone
  bool get only;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectAll({required BuiltList<Selectable> selectables, required bool only}) = _$SelectAll._;

  SelectAll._();

  static Serializer<SelectAll> get serializer => _$selectAllSerializer;
}

// Selects all selectable items in the whole design.
abstract class SelectAllSelectable
    with BuiltJsonSerializable
    implements Action, Built<SelectAllSelectable, SelectAllSelectableBuilder> {
  bool get current_helix_group_only;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectAllSelectable({bool current_helix_group_only = false}) {
    return SelectAllSelectable.from((b) => b..current_helix_group_only = current_helix_group_only);
  }

  SelectAllSelectable._();

  factory SelectAllSelectable.from([void Function(SelectAllSelectableBuilder) updates]) =
      _$SelectAllSelectable;

  static Serializer<SelectAllSelectable> get serializer => _$selectAllSelectableSerializer;
}

// used to select all strands (and maybe someday extended to other objects like Domains)
// with the same "trait" (e.g., name, label, color) as already selected strand(s)
abstract class SelectAllStrandsWithSameAsSelected
    with BuiltJsonSerializable
    implements Action, Built<SelectAllStrandsWithSameAsSelected, SelectAllStrandsWithSameAsSelectedBuilder> {
  BuiltList<Strand> get template_strands;

  BuiltList<SelectableTrait> get traits;

  bool get exclude_scaffolds;

  /************************ begin BuiltValue boilerplate ************************/
  factory SelectAllStrandsWithSameAsSelected({
    required BuiltList<Strand> template_strands,
    required BuiltList<SelectableTrait> traits,
    required bool exclude_scaffolds,
  }) = _$SelectAllStrandsWithSameAsSelected._;

  SelectAllStrandsWithSameAsSelected._();

  static Serializer<SelectAllStrandsWithSameAsSelected> get serializer =>
      _$selectAllStrandsWithSameAsSelectedSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Delete selected non-helix items

abstract class DeleteAllSelected
    with BuiltJsonSerializable, UndoableAction
    implements Built<DeleteAllSelected, DeleteAllSelectedBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory DeleteAllSelected() => DeleteAllSelected.from((b) => b);

  factory DeleteAllSelected.from([void Function(DeleteAllSelectedBuilder) updates]) = _$DeleteAllSelected;

  DeleteAllSelected._();

  static Serializer<DeleteAllSelected> get serializer => _$deleteAllSelectedSerializer;

  @override
  String short_description() => "remove all selected items";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix add/remove

abstract class HelixAdd
    with BuiltJsonSerializable, UndoableAction
    implements Built<HelixAdd, HelixAddBuilder> {
  GridPosition? get grid_position;

  Position3D? get position;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixAdd({GridPosition? grid_position = null, Position3D? position = null}) {
    if (grid_position != null) {
      return HelixAdd.from((b) => b..grid_position = grid_position.toBuilder());
    } else if (position != null) {
      return HelixAdd.from((b) => b..position = position.toBuilder());
    } else {
      if (grid_position == null && position == null) {
        throw AssertionError('cannot have both grid_position and position null in HelixAdd');
      } else {
        throw AssertionError('cannot have both grid_position and position non-null in HelixAdd');
      }
    }
  }

  factory HelixAdd.from([void Function(HelixAddBuilder) updates]) = _$HelixAdd;

  HelixAdd._();

  static Serializer<HelixAdd> get serializer => _$helixAddSerializer;

  @override
  String short_description() => "create helix";
}

abstract class HelixRemove
    with BuiltJsonSerializable, UndoableAction
    implements Built<HelixRemove, HelixRemoveBuilder> {
  int get helix_idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixRemove(int helix_idx) => HelixRemove.from((b) => b..helix_idx = helix_idx);

  factory HelixRemove.from([void Function(HelixRemoveBuilder) updates]) = _$HelixRemove;

  HelixRemove._();

  static Serializer<HelixRemove> get serializer => _$helixRemoveSerializer;

  @override
  String short_description() => "delete helix";
}

abstract class HelixRemoveAllSelected
    with BuiltJsonSerializable, UndoableAction
    implements Built<HelixRemoveAllSelected, HelixRemoveAllSelectedBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelixRemoveAllSelected() => HelixRemoveAllSelected.from();

  factory HelixRemoveAllSelected.from([void Function(HelixRemoveAllSelectedBuilder) updates]) =
      _$HelixRemoveAllSelected;

  HelixRemoveAllSelected._();

  static Serializer<HelixRemoveAllSelected> get serializer => _$helixRemoveAllSelectedSerializer;

  @override
  String short_description() => "delete all selected helices";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix select (side view)

abstract class HelixSelect
    with BuiltJsonSerializable
    implements Action, HelixSelectSvgPngCacheInvalidatingAction, Built<HelixSelect, HelixSelectBuilder> {
  int get helix_idx;

  bool get toggle;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixSelect(int helix_idx, bool toggle) => HelixSelect.from(
    (b) =>
        b
          ..helix_idx = helix_idx
          ..toggle = toggle,
  );

  factory HelixSelect.from([void Function(HelixSelectBuilder) updates]) = _$HelixSelect;

  HelixSelect._();

  static Serializer<HelixSelect> get serializer => _$helixSelectSerializer;
}

abstract class HelixSelectionsClear
    with BuiltJsonSerializable
    implements
        Action,
        HelixSelectSvgPngCacheInvalidatingAction,
        Built<HelixSelectionsClear, HelixSelectionsClearBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelixSelectionsClear() => HelixSelectionsClear.from((b) => b);

  factory HelixSelectionsClear.from([void Function(HelixSelectionsClearBuilder) updates]) =
      _$HelixSelectionsClear;

  HelixSelectionsClear._();

  static Serializer<HelixSelectionsClear> get serializer => _$helixSelectionsClearSerializer;
}

abstract class HelixSelectionsAdjust
    with BuiltJsonSerializable
    implements
        Action,
        HelixSelectSvgPngCacheInvalidatingAction,
        Built<HelixSelectionsAdjust, HelixSelectionsAdjustBuilder> {
  bool get toggle;

  SelectionBox get selection_box;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixSelectionsAdjust(bool toggle, SelectionBox selection_box) => HelixSelectionsAdjust.from(
    (b) =>
        b
          ..toggle = toggle
          ..selection_box.replace(selection_box),
  );

  factory HelixSelectionsAdjust.from([void Function(HelixSelectionsAdjustBuilder) updates]) =
      _$HelixSelectionsAdjust;

  HelixSelectionsAdjust._();

  static Serializer<HelixSelectionsAdjust> get serializer => _$helixSelectionsAdjustSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix change major ticks

abstract class HelixIndividualAction implements Action {
  int get helix_idx;
}

abstract class HelixMajorTickDistanceChange
    with BuiltJsonSerializable, UndoableAction
    implements
        HelixIndividualAction,
        Built<HelixMajorTickDistanceChange, HelixMajorTickDistanceChangeBuilder> {
  int get helix_idx;

  int get major_tick_distance;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTickDistanceChange({required int helix_idx, required int major_tick_distance}) =
      _$HelixMajorTickDistanceChange._;

  HelixMajorTickDistanceChange._();

  static Serializer<HelixMajorTickDistanceChange> get serializer => _$helixMajorTickDistanceChangeSerializer;

  @override
  String short_description() => "change helix major tick distance";
}

abstract class HelixMajorTickDistanceChangeAll
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<HelixMajorTickDistanceChangeAll, HelixMajorTickDistanceChangeAllBuilder> {
  int get major_tick_distance;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTickDistanceChangeAll({required int major_tick_distance}) =
      _$HelixMajorTickDistanceChangeAll._;

  HelixMajorTickDistanceChangeAll._();

  static Serializer<HelixMajorTickDistanceChangeAll> get serializer =>
      _$helixMajorTickDistanceChangeAllSerializer;

  @override
  String short_description() => "change all helix major tick distance";
}

abstract class HelixMajorTickStartChange
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixMajorTickStartChange, HelixMajorTickStartChangeBuilder> {
  int get helix_idx;

  int get major_tick_start;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTickStartChange({required int helix_idx, required int major_tick_start}) =
      _$HelixMajorTickStartChange._;

  HelixMajorTickStartChange._();

  static Serializer<HelixMajorTickStartChange> get serializer => _$helixMajorTickStartChangeSerializer;

  @override
  String short_description() => "change helix major tick start";
}

abstract class HelixMajorTickStartChangeAll
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<HelixMajorTickStartChangeAll, HelixMajorTickStartChangeAllBuilder> {
  int get major_tick_start;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTickStartChangeAll({required int major_tick_start}) = _$HelixMajorTickStartChangeAll._;

  HelixMajorTickStartChangeAll._();

  static Serializer<HelixMajorTickStartChangeAll> get serializer => _$helixMajorTickStartChangeAllSerializer;

  @override
  String short_description() => "change all helix major tick start";
}

abstract class HelixMajorTicksChange
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixMajorTicksChange, HelixMajorTicksChangeBuilder> {
  int get helix_idx;

  BuiltList<int> get major_ticks;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTicksChange({required int helix_idx, required BuiltList<int> major_ticks}) =
      _$HelixMajorTicksChange._;

  HelixMajorTicksChange._();

  static Serializer<HelixMajorTicksChange> get serializer => _$helixMajorTicksChangeSerializer;

  @override
  String short_description() => "change helix major ticks";
}

abstract class HelixMajorTicksChangeAll
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<HelixMajorTicksChangeAll, HelixMajorTicksChangeAllBuilder> {
  BuiltList<int> get major_ticks;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTicksChangeAll({required BuiltList<int> major_ticks}) = _$HelixMajorTicksChangeAll._;

  HelixMajorTicksChangeAll._();

  static Serializer<HelixMajorTicksChangeAll> get serializer => _$helixMajorTicksChangeAllSerializer;

  @override
  String short_description() => "change all helix major ticks";
}

// For simplicity this action also changes major_tick_start, which is paired with major_tick_distances
abstract class HelixMajorTickPeriodicDistancesChange
    with BuiltJsonSerializable, UndoableAction
    implements
        HelixIndividualAction,
        Built<HelixMajorTickPeriodicDistancesChange, HelixMajorTickPeriodicDistancesChangeBuilder> {
  int get helix_idx;

  BuiltList<int> get major_tick_periodic_distances;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTickPeriodicDistancesChange({
    required int helix_idx,
    required BuiltList<int> major_tick_periodic_distances,
  }) = _$HelixMajorTickPeriodicDistancesChange._;

  HelixMajorTickPeriodicDistancesChange._();

  static Serializer<HelixMajorTickPeriodicDistancesChange> get serializer =>
      _$helixMajorTickPeriodicDistancesChangeSerializer;

  @override
  String short_description() => "change helix major tick periodic distances";
}

// For simplicity this action also changes major_tick_start, which is paired with major_tick_distances
abstract class HelixMajorTickPeriodicDistancesChangeAll
    with BuiltJsonSerializable, UndoableAction
    implements
        Action,
        Built<HelixMajorTickPeriodicDistancesChangeAll, HelixMajorTickPeriodicDistancesChangeAllBuilder> {
  BuiltList<int> get major_tick_periodic_distances;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMajorTickPeriodicDistancesChangeAll({required BuiltList<int> major_tick_periodic_distances}) =
      _$HelixMajorTickPeriodicDistancesChangeAll._;

  HelixMajorTickPeriodicDistancesChangeAll._();

  static Serializer<HelixMajorTickPeriodicDistancesChangeAll> get serializer =>
      _$helixMajorTickPeriodicDistancesChangeAllSerializer;

  @override
  String short_description() => "change all helix major tick periodic distances";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix change index

abstract class HelixIdxsChange
    with BuiltJsonSerializable, UndoableAction
    implements Built<HelixIdxsChange, HelixIdxsChangeBuilder> {
  BuiltMap<int, int> get idx_replacements;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixIdxsChange({required Map<int, int> idx_replacements}) =>
      HelixIdxsChange.from((b) => b..idx_replacements.replace(idx_replacements));

  factory HelixIdxsChange.from(void Function(HelixIdxsChangeBuilder) updates) = _$HelixIdxsChange;

  HelixIdxsChange._();

  static Serializer<HelixIdxsChange> get serializer => _$helixIdxsChangeSerializer;

  @override
  String short_description() => "set helix idx";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix change min/max offsets

abstract class HelixOffsetChange
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixOffsetChange, HelixOffsetChangeBuilder> {
  int get helix_idx;

  int? get min_offset;

  int? get max_offset;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixOffsetChange({required int helix_idx, int? min_offset, int? max_offset}) =
      _$HelixOffsetChange._;

  HelixOffsetChange._();

  static Serializer<HelixOffsetChange> get serializer => _$helixOffsetChangeSerializer;

  @override
  String short_description() => "change helix offset";
}

abstract class HelixMinOffsetSetByDomains
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixMinOffsetSetByDomains, HelixMinOffsetSetByDomainsBuilder> {
  int get helix_idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMinOffsetSetByDomains({required int helix_idx}) = _$HelixMinOffsetSetByDomains._;

  HelixMinOffsetSetByDomains._();

  static Serializer<HelixMinOffsetSetByDomains> get serializer => _$helixMinOffsetSetByDomainsSerializer;

  @override
  String short_description() => "set helix min offset";
}

abstract class HelixMaxOffsetSetByDomains
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixMaxOffsetSetByDomains, HelixMaxOffsetSetByDomainsBuilder> {
  int get helix_idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMaxOffsetSetByDomains({required int helix_idx}) = _$HelixMaxOffsetSetByDomains._;

  HelixMaxOffsetSetByDomains._();

  static Serializer<HelixMaxOffsetSetByDomains> get serializer => _$helixMaxOffsetSetByDomainsSerializer;

  @override
  String short_description() => "set helix min offset";
}

abstract class HelixMinOffsetSetByDomainsAll
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<HelixMinOffsetSetByDomainsAll, HelixMinOffsetSetByDomainsAllBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMinOffsetSetByDomainsAll() = _$HelixMinOffsetSetByDomainsAll;

  HelixMinOffsetSetByDomainsAll._();

  static Serializer<HelixMinOffsetSetByDomainsAll> get serializer =>
      _$helixMinOffsetSetByDomainsAllSerializer;

  @override
  String short_description() => "set helix min offset";
}

// when we want each helix to have its own max based on its domains
abstract class HelixMaxOffsetSetByDomainsAll
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<HelixMaxOffsetSetByDomainsAll, HelixMaxOffsetSetByDomainsAllBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMaxOffsetSetByDomainsAll() = _$HelixMaxOffsetSetByDomainsAll;

  HelixMaxOffsetSetByDomainsAll._();

  static Serializer<HelixMaxOffsetSetByDomainsAll> get serializer =>
      _$helixMaxOffsetSetByDomainsAllSerializer;

  @override
  String short_description() => "set helix max offset";
}

// when we want the same max to be applied to all helices
abstract class HelixMaxOffsetSetByDomainsAllSameMax
    with BuiltJsonSerializable, UndoableAction
    implements
        Action,
        Built<HelixMaxOffsetSetByDomainsAllSameMax, HelixMaxOffsetSetByDomainsAllSameMaxBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelixMaxOffsetSetByDomainsAllSameMax() = _$HelixMaxOffsetSetByDomainsAllSameMax;

  HelixMaxOffsetSetByDomainsAllSameMax._();

  static Serializer<HelixMaxOffsetSetByDomainsAllSameMax> get serializer =>
      _$helixMaxOffsetSetByDomainsAllSameMaxSerializer;

  @override
  String short_description() => "set helix max offset";
}

abstract class HelixOffsetChangeAll
    with BuiltJsonSerializable, UndoableAction
    implements Built<HelixOffsetChangeAll, HelixOffsetChangeAllBuilder> {
  int? get min_offset;

  int? get max_offset;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixOffsetChangeAll({int? min_offset, int? max_offset}) = _$HelixOffsetChangeAll._;

  HelixOffsetChangeAll._();

  static Serializer<HelixOffsetChangeAll> get serializer => _$helixOffsetChangeAllSerializer;

  @override
  String short_description() => "change all helix offsets";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Show mouseover box (side view)

abstract class ShowMouseoverRectSet
    with BuiltJsonSerializable
    implements Action, Built<ShowMouseoverRectSet, ShowMouseoverRectSetBuilder> {
  bool get show;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowMouseoverRectSet(bool show) => ShowMouseoverRectSet.from((b) => b..show = show);

  factory ShowMouseoverRectSet.from([void Function(ShowMouseoverRectSetBuilder) updates]) =
      _$ShowMouseoverRectSet;

  ShowMouseoverRectSet._();

  static Serializer<ShowMouseoverRectSet> get serializer => _$showMouseoverRectSetSerializer;
}

abstract class ShowMouseoverRectToggle
    with BuiltJsonSerializable
    implements Action, Built<ShowMouseoverRectToggle, ShowMouseoverRectToggleBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory ShowMouseoverRectToggle() => ShowMouseoverRectToggle.from((b) => b);

  factory ShowMouseoverRectToggle.from([void Function(ShowMouseoverRectToggleBuilder) updates]) =
      _$ShowMouseoverRectToggle;

  ShowMouseoverRectToggle._();

  static Serializer<ShowMouseoverRectToggle> get serializer => _$showMouseoverRectToggleSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Export DNA

abstract class ExportDNA with BuiltJsonSerializable implements Action, Built<ExportDNA, ExportDNABuilder> {
  bool get include_scaffold;

  bool get include_only_selected_strands;

  bool get exclude_selected_strands;

  ExportDNAFormat get export_dna_format;

  StrandOrder? get strand_order;

  bool get column_major_strand;

  bool get column_major_plate;

  String get delimiter;

  String get domain_delimiter;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExportDNA({
    required bool include_scaffold,
    required bool include_only_selected_strands,
    required bool exclude_selected_strands,
    required ExportDNAFormat export_dna_format,
    required String delimiter,
    required String domain_delimiter,
    StrandOrder? strand_order = null,
    bool column_major_strand = true,
    bool column_major_plate = true,
  }) {
    assert(!(include_only_selected_strands && exclude_selected_strands));
    return ExportDNA.from(
      (b) =>
          b
            ..include_scaffold = include_scaffold
            ..include_only_selected_strands = include_only_selected_strands
            ..exclude_selected_strands = exclude_selected_strands
            ..export_dna_format = export_dna_format
            ..delimiter = delimiter
            ..domain_delimiter = domain_delimiter
            ..strand_order = strand_order
            ..column_major_strand = column_major_strand
            ..column_major_plate = column_major_plate,
    );
  }

  factory ExportDNA.from([void Function(ExportDNABuilder) updates]) = _$ExportDNA;

  ExportDNA._();

  static Serializer<ExportDNA> get serializer => _$exportDNASerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Export CanDo CSV DNA

abstract class ExportCanDoDNA
    with BuiltJsonSerializable
    implements Action, Built<ExportCanDoDNA, ExportCanDoDNABuilder> {
  factory ExportCanDoDNA() {
    return ExportCanDoDNA.from((b) => b);
  }

  factory ExportCanDoDNA.from([void Function(ExportCanDoDNABuilder) updates]) = _$ExportCanDoDNA;

  ExportCanDoDNA._();

  static Serializer<ExportCanDoDNA> get serializer => _$exportCanDoDNASerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Export SVG

enum ExportSvgType { main, side, both, selected }

abstract class ExportSvg with BuiltJsonSerializable implements Action, Built<ExportSvg, ExportSvgBuilder> {
  factory ExportSvg.from([void Function(ExportSvgBuilder) updates]) = _$ExportSvg;

  ExportSvg._();

  static Serializer<ExportSvg> get serializer => _$exportSvgSerializer;

  /************************ end BuiltValue boilerplate ************************/
  factory ExportSvg({required ExportSvgType type}) = _$ExportSvg._;

  ExportSvgType get type;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Export every text in a DNA sequence separately

abstract class ExportSvgTextSeparatelySet
    with BuiltJsonSerializable
    implements Action, Built<ExportSvgTextSeparatelySet, ExportSvgTextSeparatelySetBuilder> {
  bool get export_svg_text_separately;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExportSvgTextSeparatelySet(bool export_svg_text_separately) =>
      ExportSvgTextSeparatelySet.from((b) => b..export_svg_text_separately = export_svg_text_separately);

  /************************ begin BuiltValue boilerplate ************************/
  factory ExportSvgTextSeparatelySet.from([void Function(ExportSvgTextSeparatelySetBuilder) updates]) =
      _$ExportSvgTextSeparatelySet;

  ExportSvgTextSeparatelySet._();

  static Serializer<ExportSvgTextSeparatelySet> get serializer => _$exportSvgTextSeparatelySetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Strand part action

// reducer takes a part of a strand and looks up the strand it's in by strand_id,
// then applies reducer to strand
// action may not have the strand itself
abstract class StrandPartAction extends Action {
  StrandPart get strand_part;
}

abstract class ExtensionDisplayLengthAngleSet
    with BuiltJsonSerializable, UndoableAction
    implements
        StrandPartAction,
        Built<ExtensionDisplayLengthAngleSet, ExtensionDisplayLengthAngleSetBuilder> {
  Extension get ext;

  double get display_length;

  double get display_angle;

  StrandPart get strand_part => ext;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExtensionDisplayLengthAngleSet({
    required Extension ext,
    required double display_length,
    required double display_angle,
  }) => ExtensionDisplayLengthAngleSet.from(
    (b) =>
        b
          ..ext.replace(ext)
          ..display_length = display_length
          ..display_angle = display_angle,
  );

  factory ExtensionDisplayLengthAngleSet.from([
    void Function(ExtensionDisplayLengthAngleSetBuilder) updates,
  ]) = _$ExtensionDisplayLengthAngleSet;

  ExtensionDisplayLengthAngleSet._();

  static Serializer<ExtensionDisplayLengthAngleSet> get serializer =>
      _$extensionDisplayLengthAngleSetSerializer;

  @override
  String short_description() => "change extension display length/angle";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// add extension to strand

abstract class ExtensionAdd
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<ExtensionAdd, ExtensionAddBuilder> {
  Strand get strand;

  bool get is_5p;

  int get num_bases;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExtensionAdd({required Strand strand, required bool is_5p, required int num_bases}) =>
      ExtensionAdd.from(
        (b) =>
            b
              ..strand.replace(strand)
              ..is_5p = is_5p
              ..num_bases = num_bases,
      );

  factory ExtensionAdd.from([void Function(ExtensionAddBuilder) updates]) = _$ExtensionAdd;

  ExtensionAdd._();

  static Serializer<ExtensionAdd> get serializer => _$extensionAddSerializer;

  @override
  String short_description() => "add extension to strand";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// loopout/extension length change

abstract class ExtensionNumBasesChange
    with BuiltJsonSerializable, UndoableAction
    implements StrandPartAction, Built<ExtensionNumBasesChange, ExtensionNumBasesChangeBuilder> {
  Extension get ext;

  int get num_bases;

  StrandPart get strand_part => ext;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExtensionNumBasesChange(Extension ext, int num_bases) => ExtensionNumBasesChange.from(
    (b) =>
        b
          ..ext.replace(ext)
          ..num_bases = num_bases,
  );

  factory ExtensionNumBasesChange.from([void Function(ExtensionNumBasesChangeBuilder) updates]) =
      _$ExtensionNumBasesChange;

  ExtensionNumBasesChange._();

  static Serializer<ExtensionNumBasesChange> get serializer => _$extensionNumBasesChangeSerializer;

  @override
  String short_description() => "change extension number of bases";
}

abstract class ExtensionsNumBasesChange
    with BuiltJsonSerializable, UndoableAction
    implements Built<ExtensionsNumBasesChange, ExtensionsNumBasesChangeBuilder> {
  BuiltList<Extension> get extensions;

  int get num_bases;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExtensionsNumBasesChange(Iterable<Extension> extensions, int num_bases) =>
      ExtensionsNumBasesChange.from(
        (b) =>
            b
              ..extensions.replace(extensions)
              ..num_bases = num_bases,
      );

  factory ExtensionsNumBasesChange.from([void Function(ExtensionsNumBasesChangeBuilder) updates]) =
      _$ExtensionsNumBasesChange;

  ExtensionsNumBasesChange._();

  static Serializer<ExtensionsNumBasesChange> get serializer => _$extensionsNumBasesChangeSerializer;

  @override
  String short_description() => "change extensions number of bases";
}

abstract class LoopoutLengthChange
    with BuiltJsonSerializable, UndoableAction
    implements StrandPartAction, Built<LoopoutLengthChange, LoopoutLengthChangeBuilder> {
  Loopout get loopout;

  int get num_bases;

  StrandPart get strand_part => loopout;

  /************************ begin BuiltValue boilerplate ************************/
  factory LoopoutLengthChange(Loopout loopout, int num_bases) => LoopoutLengthChange.from(
    (b) =>
        b
          ..loopout.replace(loopout)
          ..num_bases = num_bases,
  );

  factory LoopoutLengthChange.from([void Function(LoopoutLengthChangeBuilder) updates]) =
      _$LoopoutLengthChange;

  LoopoutLengthChange._();

  static Serializer<LoopoutLengthChange> get serializer => _$loopoutLengthChangeSerializer;

  @override
  String short_description() => "change loopout length";
}

abstract class LoopoutsLengthChange
    with BuiltJsonSerializable, UndoableAction
    implements Built<LoopoutsLengthChange, LoopoutsLengthChangeBuilder> {
  BuiltList<Loopout> get loopouts;

  int get length;

  /************************ begin BuiltValue boilerplate ************************/
  factory LoopoutsLengthChange(Iterable<Loopout> loopouts, int length) => LoopoutsLengthChange.from(
    (b) =>
        b
          ..loopouts.replace(loopouts)
          ..length = length,
  );

  factory LoopoutsLengthChange.from([void Function(LoopoutsLengthChangeBuilder) updates]) =
      _$LoopoutsLengthChange;

  LoopoutsLengthChange._();

  static Serializer<LoopoutsLengthChange> get serializer => _$loopoutsLengthChangeSerializer;

  @override
  String short_description() => "change loopouts length";
}

abstract class ConvertCrossoverToLoopout
    with BuiltJsonSerializable, UndoableAction
    implements StrandPartAction, Built<ConvertCrossoverToLoopout, ConvertCrossoverToLoopoutBuilder> {
  Crossover get crossover;

  int get length;

  String? get dna_sequence;

  StrandPart get strand_part => crossover;

  /************************ begin BuiltValue boilerplate ************************/
  factory ConvertCrossoverToLoopout(Crossover crossover, int length, [String? dna_sequence = null]) =>
      ConvertCrossoverToLoopout.from(
        (b) =>
            b
              ..crossover.replace(crossover)
              ..length = length
              ..dna_sequence = dna_sequence,
      );

  factory ConvertCrossoverToLoopout.from([void Function(ConvertCrossoverToLoopoutBuilder) updates]) =
      _$ConvertCrossoverToLoopout;

  ConvertCrossoverToLoopout._();

  static Serializer<ConvertCrossoverToLoopout> get serializer => _$convertCrossoverToLoopoutSerializer;

  @override
  String short_description() => "convert crossover to loopout";
}

abstract class ConvertCrossoversToLoopouts
    with BuiltJsonSerializable, UndoableAction
    implements Built<ConvertCrossoversToLoopouts, ConvertCrossoversToLoopoutsBuilder> {
  BuiltList<Crossover> get crossovers;

  int get length;

  /************************ begin BuiltValue boilerplate ************************/
  factory ConvertCrossoversToLoopouts(Iterable<Crossover> crossovers, int length) =>
      ConvertCrossoversToLoopouts.from(
        (b) =>
            b
              ..crossovers.replace(crossovers)
              ..length = length,
      );

  factory ConvertCrossoversToLoopouts.from([void Function(ConvertCrossoversToLoopoutsBuilder) updates]) =
      _$ConvertCrossoversToLoopouts;

  ConvertCrossoversToLoopouts._();

  static Serializer<ConvertCrossoversToLoopouts> get serializer => _$convertCrossoversToLoopoutsSerializer;

  @override
  String short_description() => "convert crossovers to loopouts";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// nick/join

abstract class Nick with BuiltJsonSerializable, UndoableAction implements Built<Nick, NickBuilder> {
  Domain get domain;

  int get offset;

  /************************ begin BuiltValue boilerplate ************************/
  factory Nick({required Domain domain, required int offset}) = _$Nick._;

  Nick._();

  static Serializer<Nick> get serializer => _$nickSerializer;

  @override
  String short_description() => "nick";
}

abstract class Ligate with BuiltJsonSerializable, UndoableAction implements Built<Ligate, LigateBuilder> {
  DNAEnd get dna_end;

  /************************ begin BuiltValue boilerplate ************************/
  factory Ligate({required DNAEnd dna_end}) = _$Ligate._;

  Ligate._();

  static Serializer<Ligate> get serializer => _$ligateSerializer;

  @override
  String short_description() => "ligate";
}

abstract class JoinStrandsByCrossover
    with BuiltJsonSerializable, UndoableAction
    implements Built<JoinStrandsByCrossover, JoinStrandsByCrossoverBuilder> {
  DNAEnd get dna_end_first_click;

  DNAEnd get dna_end_second_click;

  /************************ begin BuiltValue boilerplate ************************/
  factory JoinStrandsByCrossover({
    required DNAEnd dna_end_first_click,
    required DNAEnd dna_end_second_click,
  }) = _$JoinStrandsByCrossover._;

  JoinStrandsByCrossover._();

  static Serializer<JoinStrandsByCrossover> get serializer => _$joinStrandsByCrossoverSerializer;

  @override
  String short_description() => "add crossover";
}

// used to move a linker (crossover or loopout, stored as potential_crossover.linker)
// so that one end stays fixed (stored in potential_crossover.dna_end_first_clicked)
// while the other end moves to dna_end_second_click, editing two strands
//
// https://github.com/UC-Davis-molecular-computing/scadnano/issues/716
abstract class MoveLinker
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<MoveLinker, MoveLinkerBuilder> {
  PotentialCrossover get potential_crossover;

  DNAEnd get dna_end_second_click;

  /************************ begin BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  factory MoveLinker({
    required PotentialCrossover potential_crossover,
    required DNAEnd dna_end_second_click,
  }) = _$MoveLinker._;

  factory MoveLinker.from([void Function(MoveLinkerBuilder) updates]) = _$MoveLinker;

  MoveLinker._();

  static Serializer<MoveLinker> get serializer => _$moveLinkerSerializer;

  @override
  String short_description() {
    Linker? l = potential_crossover.linker;
    String linker_description;
    if (l is Crossover) {
      linker_description = "crossover";
    } else if (l is Loopout) {
      linker_description = "loopout";
    } else {
      throw AssertionError("${potential_crossover.linker} is not crossover nor looput");
    }

    return "move ${linker_description}";
  }
}

// JoinStrandsByCrossover cannot be in a BatchAction since the reducer for it looks up strands
// from the Design, which are invalidated as the Design is modified.
// Also, to keep the complex logic in the reducer and out of the view code,
// we don't pass any information into the action; the global reducer looks up the selected ends.
abstract class JoinStrandsByMultipleCrossovers
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<JoinStrandsByMultipleCrossovers, JoinStrandsByMultipleCrossoversBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory JoinStrandsByMultipleCrossovers() = _$JoinStrandsByMultipleCrossovers;

  JoinStrandsByMultipleCrossovers._();

  static Serializer<JoinStrandsByMultipleCrossovers> get serializer =>
      _$joinStrandsByMultipleCrossoversSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() => "join strands by multiple crossovers";
}

abstract class StrandsReflect
    with BuiltJsonSerializable
    implements Action, Built<StrandsReflect, StrandsReflectBuilder> {
  BuiltList<Strand> get strands;

  bool get horizontal;

  bool get reverse_polarity;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandsReflect({
    required BuiltList<Strand> strands,
    required bool horizontal,
    required bool reverse_polarity,
  }) = _$StrandsReflect._;

  StrandsReflect._();

  static Serializer<StrandsReflect> get serializer => _$strandsReflectSerializer;
}

abstract class ReplaceStrands
    with BuiltJsonSerializable, UndoableAction
    implements Built<ReplaceStrands, ReplaceStrandsBuilder> {
  // maps index of old strand to new strand
  BuiltMap<int, Strand> get new_strands;

  /************************ begin BuiltValue boilerplate ************************/
  factory ReplaceStrands({required BuiltMap<int, Strand> new_strands}) = _$ReplaceStrands._;

  ReplaceStrands._();

  static Serializer<ReplaceStrands> get serializer => _$replaceStrandsSerializer;

  @override
  String short_description() => "replace strands";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// create new Strand with a single Domain with no deletions or insertions

abstract class StrandCreateStart
    with BuiltJsonSerializable
    implements Action, Built<StrandCreateStart, StrandCreateStartBuilder> {
  Address get address;

  Color get color;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandCreateStart({required Address address, required Color color}) = _$StrandCreateStart._;

  StrandCreateStart._();

  static Serializer<StrandCreateStart> get serializer => _$strandCreateStartSerializer;
}

abstract class StrandCreateAdjustOffset
    with BuiltJsonSerializable
    implements Action, Built<StrandCreateAdjustOffset, StrandCreateAdjustOffsetBuilder> {
  int get offset;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandCreateAdjustOffset({required int offset}) = _$StrandCreateAdjustOffset._;

  StrandCreateAdjustOffset._();

  static Serializer<StrandCreateAdjustOffset> get serializer => _$strandCreateAdjustOffsetSerializer;
}

abstract class StrandCreateStop
    with BuiltJsonSerializable
    implements Action, Built<StrandCreateStop, StrandCreateStopBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory StrandCreateStop() = _$StrandCreateStop;

  StrandCreateStop._();

  static Serializer<StrandCreateStop> get serializer => _$strandCreateStopSerializer;
}

abstract class StrandCreateCommit
    with BuiltJsonSerializable, UndoableAction
    implements Built<StrandCreateCommit, StrandCreateCommitBuilder> {
  int get helix_idx;

  int get start;

  int get end;

  bool get forward;

  Color get color;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandCreateCommit({
    required int helix_idx,
    required bool forward,
    required int start,
    required int end,
    required Color color,
  }) = _$StrandCreateCommit._;

  StrandCreateCommit._();

  static Serializer<StrandCreateCommit> get serializer => _$strandCreateCommitSerializer;

  @override
  String short_description() => "create strand";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// potential crossover and linking strands by crossover

abstract class PotentialCrossoverCreate
    with BuiltJsonSerializable
    implements Action, Built<PotentialCrossoverCreate, PotentialCrossoverCreateBuilder> {
  PotentialCrossover get potential_crossover;

  /************************ begin BuiltValue boilerplate ************************/
  factory PotentialCrossoverCreate({required PotentialCrossover potential_crossover}) =
      _$PotentialCrossoverCreate._;

  PotentialCrossoverCreate._();

  static Serializer<PotentialCrossoverCreate> get serializer => _$potentialCrossoverCreateSerializer;
}

abstract class PotentialCrossoverMove
    with BuiltJsonSerializable
    implements FastAction, Built<PotentialCrossoverMove, PotentialCrossoverMoveBuilder> {
  Point<double> get point;

  /************************ begin BuiltValue boilerplate ************************/
  factory PotentialCrossoverMove({required Point<double> point}) = _$PotentialCrossoverMove._;

  PotentialCrossoverMove._();

  static Serializer<PotentialCrossoverMove> get serializer => _$potentialCrossoverMoveSerializer;
}

abstract class PotentialCrossoverRemove
    with BuiltJsonSerializable
    implements Action, Built<PotentialCrossoverRemove, PotentialCrossoverRemoveBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory PotentialCrossoverRemove() = _$PotentialCrossoverRemove;

  PotentialCrossoverRemove._();

  static Serializer<PotentialCrossoverRemove> get serializer => _$potentialCrossoverRemoveSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// strands move/copy

// This triggers to request the strands info from the clipboard.
// Because that can only be done asynchronously, we intercept the action in middleware, and on
// completion of reading the strands info, we then dispatch a second action, StrandsMoveStart,
// to begin the pasting.
abstract class ManualPasteInitiate
    with BuiltJsonSerializable
    implements Action, Built<ManualPasteInitiate, ManualPasteInitiateBuilder> {
  String get clipboard_content;

  bool get in_browser;

  /************************ begin BuiltValue boilerplate ************************/
  factory ManualPasteInitiate({required String clipboard_content, bool in_browser = true}) =>
      ManualPasteInitiate.from(
        (b) =>
            b
              ..clipboard_content = clipboard_content
              ..in_browser = in_browser,
      );

  ManualPasteInitiate._();

  factory ManualPasteInitiate.from([void Function(ManualPasteInitiateBuilder) updates]) =
      _$ManualPasteInitiate;

  static Serializer<ManualPasteInitiate> get serializer => _$manualPasteInitiateSerializer;

  @memoized
  int get hashCode;
}

abstract class AutoPasteInitiate
    with BuiltJsonSerializable
    implements Action, Built<AutoPasteInitiate, AutoPasteInitiateBuilder> {
  String get clipboard_content;

  bool get in_browser;

  /************************ begin BuiltValue boilerplate ************************/
  factory AutoPasteInitiate({required String clipboard_content, bool in_browser = true}) =>
      AutoPasteInitiate.from(
        (b) =>
            b
              ..clipboard_content = clipboard_content
              ..in_browser = in_browser,
      );

  AutoPasteInitiate._();

  factory AutoPasteInitiate.from([void Function(AutoPasteInitiateBuilder) updates]) = _$AutoPasteInitiate;

  static Serializer<AutoPasteInitiate> get serializer => _$autoPasteInitiateSerializer;

  @memoized
  int get hashCode;
}

// This is dispatched on Ctrl+C to copy the strands. What is done with it depends on what
// type of paste we use (manual or auto)
abstract class CopySelectedStrands
    with BuiltJsonSerializable
    implements Action, Built<CopySelectedStrands, CopySelectedStrandsBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory CopySelectedStrands() = _$CopySelectedStrands;

  CopySelectedStrands._();

  static Serializer<CopySelectedStrands> get serializer => _$copySelectedStrandsSerializer;
}

// This is a poor name for the action; it is used when we want to copy strands
// (used similarly to StrandsMoveStartSelectedStrands, but the latter is when we want to move strands)
abstract class StrandsMoveStart
    with BuiltJsonSerializable
    implements Action, Built<StrandsMoveStart, StrandsMoveStartBuilder> {
  BuiltList<Strand> get strands;

  Address get address;

  bool get copy;

  BuiltMap<int, int> get original_helices_view_order_inverse;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandsMoveStart({
    required BuiltList<Strand> strands,
    required Address address,
    required bool copy,
    required BuiltMap<int, int> original_helices_view_order_inverse,
  }) = _$StrandsMoveStart._;

  StrandsMoveStart._();

  static Serializer<StrandsMoveStart> get serializer => _$strandsMoveStartSerializer;
}

abstract class StrandsMoveStartSelectedStrands
    with BuiltJsonSerializable
    implements Action, Built<StrandsMoveStartSelectedStrands, StrandsMoveStartSelectedStrandsBuilder> {
  Address get address;

  bool get copy;

  BuiltMap<int, int> get original_helices_view_order_inverse;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandsMoveStartSelectedStrands({
    required Address address,
    required bool copy,
    required BuiltMap<int, int> original_helices_view_order_inverse,
  }) = _$StrandsMoveStartSelectedStrands._;

  StrandsMoveStartSelectedStrands._();

  static Serializer<StrandsMoveStartSelectedStrands> get serializer =>
      _$strandsMoveStartSelectedStrandsSerializer;
}

abstract class StrandsMoveStop
    with BuiltJsonSerializable
    implements Action, Built<StrandsMoveStop, StrandsMoveStopBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory StrandsMoveStop() = _$StrandsMoveStop;

  StrandsMoveStop._();

  static Serializer<StrandsMoveStop> get serializer => _$strandsMoveStopSerializer;
}

abstract class StrandsMoveAdjustAddress
    with BuiltJsonSerializable
    implements Action, Built<StrandsMoveAdjustAddress, StrandsMoveAdjustAddressBuilder> {
  Address get address;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandsMoveAdjustAddress({required Address address}) = _$StrandsMoveAdjustAddress._;

  StrandsMoveAdjustAddress._();

  static Serializer<StrandsMoveAdjustAddress> get serializer => _$strandsMoveAdjustAddressSerializer;
}

// Used for both moving strands and pasting them (in both manual and autopaste)
abstract class StrandsMoveCommit
    with BuiltJsonSerializable, UndoableAction
    implements Built<StrandsMoveCommit, StrandsMoveCommitBuilder> {
  StrandsMove get strands_move;

  bool get autopaste;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandsMoveCommit({required StrandsMove strands_move, required bool autopaste}) =
      _$StrandsMoveCommit._;

  StrandsMoveCommit._();

  static Serializer<StrandsMoveCommit> get serializer => _$strandsMoveCommitSerializer;

  @override
  String short_description() => "move strands";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// domains move

abstract class DomainsMoveStartSelectedDomains
    with BuiltJsonSerializable
    implements Action, Built<DomainsMoveStartSelectedDomains, DomainsMoveStartSelectedDomainsBuilder> {
  Address get address;

  BuiltMap<int, int> get original_helices_view_order_inverse;

  /************************ begin BuiltValue boilerplate ************************/
  factory DomainsMoveStartSelectedDomains({
    required Address address,
    required BuiltMap<int, int> original_helices_view_order_inverse,
  }) = _$DomainsMoveStartSelectedDomains._;

  DomainsMoveStartSelectedDomains._();

  static Serializer<DomainsMoveStartSelectedDomains> get serializer =>
      _$domainsMoveStartSelectedDomainsSerializer;
}

abstract class DomainsMoveStop
    with BuiltJsonSerializable
    implements Action, Built<DomainsMoveStop, DomainsMoveStopBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory DomainsMoveStop() = _$DomainsMoveStop;

  DomainsMoveStop._();

  static Serializer<DomainsMoveStop> get serializer => _$domainsMoveStopSerializer;
}

abstract class DomainsMoveAdjustAddress
    with BuiltJsonSerializable
    implements Action, Built<DomainsMoveAdjustAddress, DomainsMoveAdjustAddressBuilder> {
  Address get address;

  /************************ begin BuiltValue boilerplate ************************/
  factory DomainsMoveAdjustAddress({required Address address}) = _$DomainsMoveAdjustAddress._;

  DomainsMoveAdjustAddress._();

  static Serializer<DomainsMoveAdjustAddress> get serializer => _$domainsMoveAdjustAddressSerializer;
}

abstract class DomainsMoveCommit
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<DomainsMoveCommit, DomainsMoveCommitBuilder> {
  DomainsMove get domains_move;

  /************************ begin BuiltValue boilerplate ************************/
  factory DomainsMoveCommit({required DomainsMove domains_move}) = _$DomainsMoveCommit._;

  DomainsMoveCommit._();

  static Serializer<DomainsMoveCommit> get serializer => _$domainsMoveCommitSerializer;

  @override
  String short_description() => "move domains";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// dna ends move

/// Interpreted in main store to just set state.ui_state.dna_ends_are_moving to true.
/// An optimized store specifically for moving [DNAEnd]s handles updating as the mouse is moved
/// by dispatching [DNAEndsMoveAdjustOffset].
/// Also triggers middleware to look up set of selected ends, which then dispatches
/// [DNAEndsMoveSetSelectedEnds] (since the DNAEnd itself that is clicked to dispatch [DNAEndsMoveStart]
/// doesn't know what are all the other selected DNAEnds).
abstract class DNAEndsMoveStart
    with BuiltJsonSerializable
    implements Action, Built<DNAEndsMoveStart, DNAEndsMoveStartBuilder> {
  int get offset;

  Helix get helix;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAEndsMoveStart({required int offset, required Helix helix}) = _$DNAEndsMoveStart._;

  DNAEndsMoveStart._();

  static Serializer<DNAEndsMoveStart> get serializer => _$dNAEndsMoveStartSerializer;
}

/// This action is needed because [DNAEndsMoveStart] doesn't have enough information to find the set
/// of selected ends, and because we process the subsequent actions as a [FactAction] with an
/// optimized store, it doesn't have access to the full store either. So middleware on the full store
/// processes the [DNAEndsMoveStart] in order to find the selected ends and put them into the
/// [DNAEndMove]'s of this action.
abstract class DNAEndsMoveSetSelectedEnds
    with BuiltJsonSerializable
    implements Action, Built<DNAEndsMoveSetSelectedEnds, DNAEndsMoveSetSelectedEndsBuilder> {
  BuiltList<DNAEndMove> get moves;

  int get original_offset;

  Helix get helix;

  BuiltSet<Strand> get strands_affected;

  Geometry get geometry;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAEndsMoveSetSelectedEnds({
    required BuiltList<DNAEndMove> moves,
    required int original_offset,
    required Helix helix,
    required BuiltSet<Strand> strands_affected,
    required Geometry geometry,
  }) = _$DNAEndsMoveSetSelectedEnds._;

  DNAEndsMoveSetSelectedEnds._();

  static Serializer<DNAEndsMoveSetSelectedEnds> get serializer => _$dNAEndsMoveSetSelectedEndsSerializer;
}

abstract class DNAEndsMoveAdjustOffset
    with BuiltJsonSerializable
    implements FastAction, Built<DNAEndsMoveAdjustOffset, DNAEndsMoveAdjustOffsetBuilder> {
  int get offset;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAEndsMoveAdjustOffset({required int offset}) = _$DNAEndsMoveAdjustOffset._;

  DNAEndsMoveAdjustOffset._();

  static Serializer<DNAEndsMoveAdjustOffset> get serializer => _$dNAEndsMoveAdjustOffsetSerializer;
}

abstract class DNAEndsMoveStop
    with BuiltJsonSerializable
    implements Action, Built<DNAEndsMoveStop, DNAEndsMoveStopBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory DNAEndsMoveStop() = _$DNAEndsMoveStop._;

  DNAEndsMoveStop._();

  static Serializer<DNAEndsMoveStop> get serializer => _$dNAEndsMoveStopSerializer;
}

abstract class DNAEndsMoveCommit
    with BuiltJsonSerializable, UndoableAction
    implements Built<DNAEndsMoveCommit, DNAEndsMoveCommitBuilder> {
  DNAEndsMove get dna_ends_move;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAEndsMoveCommit({required DNAEndsMove dna_ends_move}) = _$DNAEndsMoveCommit._;

  DNAEndsMoveCommit._();

  static Serializer<DNAEndsMoveCommit> get serializer => _$dNAEndsMoveCommitSerializer;

  @override
  String short_description() => "move DNA ends";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// dna extensions move

abstract class DNAExtensionsMoveStart
    with BuiltJsonSerializable
    implements Action, Built<DNAExtensionsMoveStart, DNAExtensionsMoveStartBuilder> {
  Point<double> get start_point;

  Helix get helix;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAExtensionsMoveStart({required Point<double> start_point, required Helix helix}) =
      _$DNAExtensionsMoveStart._;

  DNAExtensionsMoveStart._();

  static Serializer<DNAExtensionsMoveStart> get serializer => _$dNAExtensionsMoveStartSerializer;
}

abstract class DNAExtensionsMoveSetSelectedExtensionEnds
    with BuiltJsonSerializable
    implements
        Action,
        Built<DNAExtensionsMoveSetSelectedExtensionEnds, DNAExtensionsMoveSetSelectedExtensionEndsBuilder> {
  BuiltList<DNAExtensionMove> get moves;

  Point<double> get original_point;

  BuiltSet<Strand> get strands_affected;

  Helix get helix;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAExtensionsMoveSetSelectedExtensionEnds({
    required BuiltList<DNAExtensionMove> moves,
    required Point<double> original_point,
    required BuiltSet<Strand> strands_affected,
    required Helix helix,
  }) = _$DNAExtensionsMoveSetSelectedExtensionEnds._;

  DNAExtensionsMoveSetSelectedExtensionEnds._();

  static Serializer<DNAExtensionsMoveSetSelectedExtensionEnds> get serializer =>
      _$dNAExtensionsMoveSetSelectedExtensionEndsSerializer;
}

abstract class DNAExtensionsMoveAdjustPosition
    with BuiltJsonSerializable
    implements FastAction, Built<DNAExtensionsMoveAdjustPosition, DNAExtensionsMoveAdjustPositionBuilder> {
  Point<double> get position;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAExtensionsMoveAdjustPosition({required Point<double> position}) =
      _$DNAExtensionsMoveAdjustPosition._;

  DNAExtensionsMoveAdjustPosition._();

  static Serializer<DNAExtensionsMoveAdjustPosition> get serializer =>
      _$dNAExtensionsMoveAdjustPositionSerializer;
}

abstract class DNAExtensionsMoveStop
    with BuiltJsonSerializable
    implements Action, Built<DNAExtensionsMoveStop, DNAExtensionsMoveStopBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory DNAExtensionsMoveStop() = _$DNAExtensionsMoveStop._;

  DNAExtensionsMoveStop._();

  static Serializer<DNAExtensionsMoveStop> get serializer => _$dNAExtensionsMoveStopSerializer;
}

abstract class DNAExtensionsMoveCommit
    with BuiltJsonSerializable, UndoableAction
    implements Built<DNAExtensionsMoveCommit, DNAExtensionsMoveCommitBuilder> {
  DNAExtensionsMove get dna_extensions_move;

  /************************ begin BuiltValue boilerplate ************************/
  factory DNAExtensionsMoveCommit({required DNAExtensionsMove dna_extensions_move}) =
      _$DNAExtensionsMoveCommit._;

  DNAExtensionsMoveCommit._();

  static Serializer<DNAExtensionsMoveCommit> get serializer => _$dNAExtensionsMoveCommitSerializer;

  @override
  String short_description() => "move DNA extensions";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// move helix group by dragging

// don't need any info about name because it's always the currently selected group
// This is triggered by clicking in design main view when in helix move mode.
abstract class HelixGroupMoveStart
    with BuiltJsonSerializable
    implements Action, Built<HelixGroupMoveStart, HelixGroupMoveStartBuilder> {
  Point<double> get mouse_point;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixGroupMoveStart({required Point<double> mouse_point}) = _$HelixGroupMoveStart._;

  HelixGroupMoveStart._();

  static Serializer<HelixGroupMoveStart> get serializer => _$helixGroupMoveStartSerializer;
}

// This is created by middleware in response to HelixGroupMoveStart to set up the store.
abstract class HelixGroupMoveCreate
    with BuiltJsonSerializable
    implements Action, Built<HelixGroupMoveCreate, HelixGroupMoveCreateBuilder> {
  HelixGroupMove get helix_group_move;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixGroupMoveCreate({required HelixGroupMove helix_group_move}) = _$HelixGroupMoveCreate._;

  HelixGroupMoveCreate._();

  static Serializer<HelixGroupMoveCreate> get serializer => _$helixGroupMoveCreateSerializer;
}

abstract class HelixGroupMoveAdjustTranslation
    with BuiltJsonSerializable
    implements FastAction, Built<HelixGroupMoveAdjustTranslation, HelixGroupMoveAdjustTranslationBuilder> {
  Point<double> get mouse_point;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixGroupMoveAdjustTranslation({required Point<double> mouse_point}) =
      _$HelixGroupMoveAdjustTranslation._;

  HelixGroupMoveAdjustTranslation._();

  static Serializer<HelixGroupMoveAdjustTranslation> get serializer =>
      _$helixGroupMoveAdjustTranslationSerializer;
}

abstract class HelixGroupMoveStop
    with BuiltJsonSerializable
    implements Action, Built<HelixGroupMoveStop, HelixGroupMoveStopBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelixGroupMoveStop() = _$HelixGroupMoveStop;

  HelixGroupMoveStop._();

  static Serializer<HelixGroupMoveStop> get serializer => _$helixGroupMoveStopSerializer;
}

abstract class HelixGroupMoveCommit
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<HelixGroupMoveCommit, HelixGroupMoveCommitBuilder> {
  HelixGroupMove get helix_group_move;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixGroupMoveCommit({required HelixGroupMove helix_group_move}) = _$HelixGroupMoveCommit._;

  HelixGroupMoveCommit._();

  static Serializer<HelixGroupMoveCommit> get serializer => _$helixGroupMoveCommitSerializer;

  @override
  String short_description() => "move helix group";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// assign/remove dna

abstract class AssignDNA
    with BuiltJsonSerializable, UndoableAction
    implements Built<AssignDNA, AssignDNABuilder> {
  Strand get strand;

  DNAAssignOptions get dna_assign_options;

  // convenience getters since we already have a lot of code referencing some of these from the old
  // design of this Action
  String get dna_sequence => dna_assign_options.dna_sequence;

  bool get use_predefined_dna_sequence => dna_assign_options.use_predefined_dna_sequence;

  bool get assign_complements => dna_assign_options.assign_complements;

  bool get disable_change_sequence_bound_strand => dna_assign_options.disable_change_sequence_bound_strand;

  int get m13_rotation => dna_assign_options.m13_rotation;

  /************************ begin BuiltValue boilerplate ************************/
  factory AssignDNA({required Strand strand, required DNAAssignOptions dna_assign_options}) = _$AssignDNA._;

  AssignDNA._();

  static Serializer<AssignDNA> get serializer => _$assignDNASerializer;

  @override
  String short_description() => "assign DNA sequence";
}

/// used when other strands have DNA already assigned, and are bound to this one, and we want to
/// assign/replace its DNA with the complement of those
abstract class AssignDNAComplementFromBoundStrands
    with BuiltJsonSerializable, UndoableAction
    implements Built<AssignDNAComplementFromBoundStrands, AssignDNAComplementFromBoundStrandsBuilder> {
  BuiltList<Strand> get strands;

  /************************ begin BuiltValue boilerplate ************************/
  factory AssignDNAComplementFromBoundStrands(Iterable<Strand> strands) {
    return AssignDNAComplementFromBoundStrands.from((b) => b..strands.replace(strands));
  }

  factory AssignDNAComplementFromBoundStrands.from([
    void Function(AssignDNAComplementFromBoundStrandsBuilder) updates,
  ]) = _$AssignDNAComplementFromBoundStrands;

  AssignDNAComplementFromBoundStrands._();

  static Serializer<AssignDNAComplementFromBoundStrands> get serializer =>
      _$assignDNAComplementFromBoundStrandsSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() => "add DNA complement from bound strands";
}

abstract class AssignDomainNameComplementFromBoundStrands
    with BuiltJsonSerializable, UndoableAction
    implements
        Built<AssignDomainNameComplementFromBoundStrands, AssignDomainNameComplementFromBoundStrandsBuilder> {
  BuiltList<Strand> get strands;

  /************************ begin BuiltValue boilerplate ************************/
  factory AssignDomainNameComplementFromBoundStrands(Iterable<Strand> strands) {
    return AssignDomainNameComplementFromBoundStrands.from((b) => b..strands.replace(strands));
  }

  factory AssignDomainNameComplementFromBoundStrands.from(
    void Function(AssignDomainNameComplementFromBoundStrandsBuilder) updates,
  ) = _$AssignDomainNameComplementFromBoundStrands;

  AssignDomainNameComplementFromBoundStrands._();

  static Serializer<AssignDomainNameComplementFromBoundStrands> get serializer =>
      _$assignDomainNameComplementFromBoundStrandsSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() => "assign domain name complement from bound strands";
}

abstract class AssignDomainNameComplementFromBoundDomains
    with BuiltJsonSerializable, UndoableAction
    implements
        Built<AssignDomainNameComplementFromBoundDomains, AssignDomainNameComplementFromBoundDomainsBuilder> {
  BuiltList<Domain> get domains;

  /************************ begin BuiltValue boilerplate ************************/
  factory AssignDomainNameComplementFromBoundDomains(Iterable<Domain> domains) {
    return AssignDomainNameComplementFromBoundDomains.from((b) => b..domains.replace(domains));
  }

  factory AssignDomainNameComplementFromBoundDomains.from([
    void Function(AssignDomainNameComplementFromBoundDomainsBuilder) updates,
  ]) = _$AssignDomainNameComplementFromBoundDomains;

  AssignDomainNameComplementFromBoundDomains._();

  static Serializer<AssignDomainNameComplementFromBoundDomains> get serializer =>
      _$assignDomainNameComplementFromBoundDomainsSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() => "assign domain name complement from bound domains";
}

abstract class RemoveDNA
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<RemoveDNA, RemoveDNABuilder> {
  Strand get strand;

  bool get remove_complements;

  bool get remove_all;

  /************************ begin BuiltValue boilerplate ************************/
  factory RemoveDNA({required Strand strand, required bool remove_complements, required bool remove_all}) =
      _$RemoveDNA._;

  RemoveDNA._();

  static Serializer<RemoveDNA> get serializer => _$removeDNASerializer;

  @override
  String short_description() => "remove DNA sequence";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// insertion/deletion

abstract class InsertionOrDeletionAction implements UndoableAction, StrandPartAction {
  Domain get domain;

  int get offset;

  bool get all_helices;

  StrandPart get strand_part; // => substrand;

  InsertionOrDeletionAction clone_for_other_domain(Domain other_domain);
}

abstract class InsertionAdd
    with BuiltJsonSerializable, UndoableAction
    implements InsertionOrDeletionAction, Built<InsertionAdd, InsertionAddBuilder> {
  Domain get domain;

  int get offset;

  bool get all_helices;

  StrandPart get strand_part => domain;

  InsertionAdd clone_for_other_domain(Domain domain) => rebuild((b) => b..domain.replace(domain));

  /************************ begin BuiltValue boilerplate ************************/
  factory InsertionAdd({required Domain domain, required int offset, required bool all_helices}) =
      _$InsertionAdd._;

  InsertionAdd._();

  static Serializer<InsertionAdd> get serializer => _$insertionAddSerializer;

  @override
  String short_description() => "add insertion";
}

abstract class InsertionLengthChange
    with BuiltJsonSerializable, UndoableAction
    implements InsertionOrDeletionAction, Built<InsertionLengthChange, InsertionLengthChangeBuilder> {
  Domain get domain;

  Insertion get insertion;

  int get length;

  bool get all_helices;

  int get offset => insertion.offset;

  StrandPart get strand_part => domain;

  InsertionLengthChange clone_for_other_domain(Domain other_domain) => InsertionLengthChange(
    domain: other_domain,
    insertion: other_domain.insertions.firstWhere((i) => i.offset == offset),
    length: length,
  );

  /************************ begin BuiltValue boilerplate ************************/
  factory InsertionLengthChange({required Domain domain, required Insertion insertion, required int length}) {
    return InsertionLengthChange.from(
      (b) =>
          b
            ..domain.replace(domain)
            ..insertion.replace(insertion)
            ..length = length
            ..all_helices = false,
    );
  }

  factory InsertionLengthChange.from([void Function(InsertionLengthChangeBuilder) updates]) =
      _$InsertionLengthChange;

  // factory InsertionLengthChange({Domain domain, Insertion insertion, int length}) = _$InsertionLengthChange._;

  InsertionLengthChange._();

  static Serializer<InsertionLengthChange> get serializer => _$insertionLengthChangeSerializer;

  @override
  String short_description() => "change insertion length";
}

abstract class InsertionsLengthChange
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<InsertionsLengthChange, InsertionsLengthChangeBuilder> {
  BuiltList<Insertion> get insertions;

  BuiltList<Domain> get domains;

  int get length;

  bool get all_helices;

  /************************ begin BuiltValue boilerplate ************************/
  factory InsertionsLengthChange({
    required Iterable<Insertion> insertions,
    required Iterable<Domain> domains,
    required int length,
  }) {
    return InsertionsLengthChange.from(
      (b) =>
          b
            ..insertions.replace(insertions)
            ..domains.replace(domains)
            ..length = length
            ..all_helices = false,
    );
  }

  factory InsertionsLengthChange.from([void Function(InsertionsLengthChangeBuilder) updates]) =
      _$InsertionsLengthChange;

  InsertionsLengthChange._();

  static Serializer<InsertionsLengthChange> get serializer => _$insertionsLengthChangeSerializer;

  @override
  String short_description() => "change insertions length";
}

abstract class DeletionAdd
    with BuiltJsonSerializable, UndoableAction
    implements InsertionOrDeletionAction, Built<DeletionAdd, DeletionAddBuilder> {
  Domain get domain;

  int get offset;

  bool get all_helices;

  StrandPart get strand_part => domain;

  DeletionAdd clone_for_other_domain(Domain domain) => rebuild((b) => b..domain.replace(domain));

  /************************ begin BuiltValue boilerplate ************************/
  factory DeletionAdd({required Domain domain, required int offset, required bool all_helices}) =
      _$DeletionAdd._;

  DeletionAdd._();

  static Serializer<DeletionAdd> get serializer => _$deletionAddSerializer;

  @override
  String short_description() => "add deletion";
}

abstract class InsertionRemove
    with BuiltJsonSerializable, UndoableAction
    implements InsertionOrDeletionAction, Built<InsertionRemove, InsertionRemoveBuilder> {
  Domain get domain;

  Insertion get insertion;

  bool get all_helices;

  int get offset => insertion.offset;

  StrandPart get strand_part => domain;

  InsertionRemove clone_for_other_domain(Domain other_domain) => InsertionRemove(
    domain: other_domain,
    insertion: other_domain.insertions.firstWhere((i) => i.offset == offset),
  );

  /************************ begin BuiltValue boilerplate ************************/
  factory InsertionRemove({required Domain domain, required Insertion insertion}) {
    return InsertionRemove.from(
      (b) =>
          b
            ..domain.replace(domain)
            ..insertion.replace(insertion)
            ..all_helices = false,
    );
  }

  factory InsertionRemove.from([void Function(InsertionRemoveBuilder) updates]) = _$InsertionRemove;

  InsertionRemove._();

  static Serializer<InsertionRemove> get serializer => _$insertionRemoveSerializer;

  @override
  String short_description() => "remove insertion";
}

abstract class DeletionRemove
    with BuiltJsonSerializable, UndoableAction
    implements InsertionOrDeletionAction, Built<DeletionRemove, DeletionRemoveBuilder> {
  Domain get domain;

  int get offset;

  bool get all_helices;

  StrandPart get strand_part => domain;

  DeletionRemove clone_for_other_domain(Domain other_domain) =>
      DeletionRemove(domain: other_domain, offset: offset);

  /************************ begin BuiltValue boilerplate ************************/
  factory DeletionRemove({required Domain domain, required int offset}) {
    return DeletionRemove.from(
      (b) =>
          b
            ..domain.replace(domain)
            ..offset = offset
            ..all_helices = false,
    );
  }

  factory DeletionRemove.from([void Function(DeletionRemoveBuilder) updates]) = _$DeletionRemove;

  // factory DeletionRemove({Domain domain, int offset}) = _$DeletionRemove._;

  DeletionRemove._();

  static Serializer<DeletionRemove> get serializer => _$deletionRemoveSerializer;

  @override
  String short_description() => "remove deletion";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// assign scale/purification vendor fields of strands
abstract class ScalePurificationVendorFieldsAssign
    with BuiltJsonSerializable, UndoableAction
    implements
        SingleStrandAction,
        Built<ScalePurificationVendorFieldsAssign, ScalePurificationVendorFieldsAssignBuilder> {
  Strand get strand;

  VendorFields get vendor_fields;

  /************************ begin BuiltValue boilerplate ************************/
  factory ScalePurificationVendorFieldsAssign({required Strand strand, required VendorFields vendor_fields}) =
      _$ScalePurificationVendorFieldsAssign._;

  ScalePurificationVendorFieldsAssign._();

  static Serializer<ScalePurificationVendorFieldsAssign> get serializer =>
      _$scalePurificationVendorFieldsAssignSerializer;

  @override
  String short_description() => "assign scale purification vendor fields";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// assign plate/well IDT fields of strands
abstract class PlateWellVendorFieldsAssign
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<PlateWellVendorFieldsAssign, PlateWellVendorFieldsAssignBuilder> {
  Strand get strand;

  VendorFields get vendor_fields;

  /************************ begin BuiltValue boilerplate ************************/
  factory PlateWellVendorFieldsAssign({required Strand strand, required VendorFields vendor_fields}) =
      _$PlateWellVendorFieldsAssign._;

  PlateWellVendorFieldsAssign._();

  static Serializer<PlateWellVendorFieldsAssign> get serializer => _$plateWellVendorFieldsAssignSerializer;

  @override
  String short_description() => "assign plate well vendor fields";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// remove plate/well vendor fields of strands
abstract class PlateWellVendorFieldsRemove
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<PlateWellVendorFieldsRemove, PlateWellVendorFieldsRemoveBuilder> {
  Strand get strand;

  /************************ begin BuiltValue boilerplate ************************/
  factory PlateWellVendorFieldsRemove({required Strand strand}) = _$PlateWellVendorFieldsRemove._;

  PlateWellVendorFieldsRemove._();

  static Serializer<PlateWellVendorFieldsRemove> get serializer => _$plateWellVendorFieldsRemoveSerializer;

  @override
  String short_description() => "remove plate well vendor fields";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// remove vendor fields of strands
abstract class VendorFieldsRemove
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<VendorFieldsRemove, VendorFieldsRemoveBuilder> {
  Strand get strand;

  /************************ begin BuiltValue boilerplate ************************/
  factory VendorFieldsRemove({required Strand strand}) = _$VendorFieldsRemove._;

  VendorFieldsRemove._();

  static Serializer<VendorFieldsRemove> get serializer => _$vendorFieldsRemoveSerializer;

  @override
  String short_description() => "remove vendor fields";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// modification add
abstract class ModificationAdd
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<ModificationAdd, ModificationAddBuilder> {
  Strand get strand;

  Modification get modification;

  int? get strand_dna_idx; // only specified if internal modification

  /************************ begin BuiltValue boilerplate ************************/
  factory ModificationAdd({required Strand strand, required Modification modification, int? strand_dna_idx}) =
      _$ModificationAdd._;

  ModificationAdd._();

  static Serializer<ModificationAdd> get serializer => _$modificationAddSerializer;

  @override
  String short_description() => "add modification";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// modification remove
abstract class ModificationRemove
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<ModificationRemove, ModificationRemoveBuilder> {
  Strand get strand;

  Modification get modification;

  int? get strand_dna_idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory ModificationRemove({
    required Strand strand,
    required Modification modification,
    int? strand_dna_idx,
  }) = _$ModificationRemove._;

  ModificationRemove._();

  static Serializer<ModificationRemove> get serializer => _$modificationRemoveSerializer;

  @override
  String short_description() => "remove modification";
}

abstract class ModificationConnectorLengthSet
    with BuiltJsonSerializable
    implements Action, Built<ModificationConnectorLengthSet, ModificationConnectorLengthSetBuilder> {
  Strand get strand;

  Modification get modification;

  int get connector_length;

  /************************ begin BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  factory ModificationConnectorLengthSet({
    required Strand strand,
    required Modification modification,
    required int connector_length,
  }) = _$ModificationConnectorLengthSet._;

  factory ModificationConnectorLengthSet.from([
    void Function(ModificationConnectorLengthSetBuilder) updates,
  ]) = _$ModificationConnectorLengthSet;

  ModificationConnectorLengthSet._();

  static Serializer<ModificationConnectorLengthSet> get serializer =>
      _$modificationConnectorLengthSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// modification edit

abstract class ModificationEdit
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<ModificationEdit, ModificationEditBuilder> {
  Strand get strand;

  Modification get modification;

  int? get strand_dna_idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory ModificationEdit({
    required Strand strand,
    required Modification modification,
    int? strand_dna_idx,
  }) = _$ModificationEdit._;

  ModificationEdit._();

  static Serializer<ModificationEdit> get serializer => _$modificationEditSerializer;

  @override
  String short_description() => "edit modification";
}

abstract class Modifications5PrimeEdit
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<Modifications5PrimeEdit, Modifications5PrimeEditBuilder> {
  BuiltList<SelectableModification5Prime> get modifications;

  Modification5Prime get new_modification;

  /************************ begin BuiltValue boilerplate ************************/
  factory Modifications5PrimeEdit({
    required Iterable<SelectableModification5Prime> modifications,
    required Modification5Prime new_modification,
  }) {
    return Modifications5PrimeEdit.from(
      (b) =>
          b
            ..modifications.replace(modifications)
            ..new_modification.replace(new_modification),
    );
  }

  factory Modifications5PrimeEdit.from([void Function(Modifications5PrimeEditBuilder) updates]) =
      _$Modifications5PrimeEdit;

  Modifications5PrimeEdit._();

  static Serializer<Modifications5PrimeEdit> get serializer => _$modifications5PrimeEditSerializer;

  @override
  String short_description() => "edit 5' modifications";
}

abstract class Modifications3PrimeEdit
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<Modifications3PrimeEdit, Modifications3PrimeEditBuilder> {
  BuiltList<SelectableModification3Prime> get modifications;

  Modification3Prime get new_modification;

  /************************ begin BuiltValue boilerplate ************************/
  factory Modifications3PrimeEdit({
    required Iterable<SelectableModification3Prime> modifications,
    required Modification3Prime new_modification,
  }) {
    return Modifications3PrimeEdit.from(
      (b) =>
          b
            ..modifications.replace(modifications)
            ..new_modification.replace(new_modification),
    );
  }

  factory Modifications3PrimeEdit.from([void Function(Modifications3PrimeEditBuilder) updates]) =
      _$Modifications3PrimeEdit;

  Modifications3PrimeEdit._();

  static Serializer<Modifications3PrimeEdit> get serializer => _$modifications3PrimeEditSerializer;

  @override
  String short_description() => "edit 3' modifications";
}

abstract class ModificationsInternalEdit
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<ModificationsInternalEdit, ModificationsInternalEditBuilder> {
  BuiltList<SelectableModificationInternal> get modifications;

  ModificationInternal get new_modification;

  /************************ begin BuiltValue boilerplate ************************/
  factory ModificationsInternalEdit({
    required Iterable<SelectableModificationInternal> modifications,
    required ModificationInternal new_modification,
  }) {
    return ModificationsInternalEdit.from(
      (b) =>
          b
            ..modifications.replace(modifications)
            ..new_modification.replace(new_modification),
    );
  }

  factory ModificationsInternalEdit.from([void Function(ModificationsInternalEditBuilder) updates]) =
      _$ModificationsInternalEdit;

  ModificationsInternalEdit._();

  static Serializer<ModificationsInternalEdit> get serializer => _$modificationsInternalEditSerializer;

  @override
  String short_description() => "edit internal modifications";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// grid change

abstract class GridChange
    with BuiltJsonSerializable, UndoableAction
    implements Built<GridChange, GridChangeBuilder> {
  Grid get grid;

  String get group_name;

  /************************ begin BuiltValue boilerplate ************************/
  factory GridChange({required Grid grid, required String group_name}) = _$GridChange._;

  GridChange._();

  static Serializer<GridChange> get serializer => _$gridChangeSerializer;

  @override
  String short_description() => "change grid";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// changes to Helix groups

abstract class GroupDisplayedChange
    with BuiltJsonSerializable
    implements Action, Built<GroupDisplayedChange, GroupDisplayedChangeBuilder> {
  String get group_name;

  /************************ begin BuiltValue boilerplate ************************/
  factory GroupDisplayedChange({required String group_name}) = _$GroupDisplayedChange._;

  GroupDisplayedChange._();

  static Serializer<GroupDisplayedChange> get serializer => _$groupDisplayedChangeSerializer;
}

abstract class GroupAdd
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<GroupAdd, GroupAddBuilder> {
  String get name;

  HelixGroup get group;

  /************************ begin BuiltValue boilerplate ************************/
  factory GroupAdd({required String name, required HelixGroup group}) = _$GroupAdd._;

  GroupAdd._();

  static Serializer<GroupAdd> get serializer => _$groupAddSerializer;

  @override
  String short_description() => "create new helix group";
}

abstract class GroupRemove
    with BuiltJsonSerializable, UndoableAction
    implements Built<GroupRemove, GroupRemoveBuilder> {
  String get name;

  /************************ begin BuiltValue boilerplate ************************/
  factory GroupRemove({required String name}) = _$GroupRemove._;

  GroupRemove._();

  static Serializer<GroupRemove> get serializer => _$groupRemoveSerializer;

  @override
  String short_description() => "remove group";
}

//FIXME: warning: should not change the grid through this action; dispatch GridChange instead
// used to change properties of an existing HelixGroup (except grid); new properties are stored as
// a whole new HelixGroup called new_group
abstract class GroupChange
    with BuiltJsonSerializable, UndoableAction
    implements Built<GroupChange, GroupChangeBuilder> {
  String get old_name;

  String get new_name;

  HelixGroup get new_group;

  /************************ begin BuiltValue boilerplate ************************/
  factory GroupChange({required String old_name, required String new_name, required HelixGroup new_group}) =
      _$GroupChange._;

  GroupChange._();

  static Serializer<GroupChange> get serializer => _$groupChangeSerializer;

  @override
  String short_description() => "adjust helix group";
}

// moves existing helices to another existing group
abstract class MoveHelicesToGroup
    with BuiltJsonSerializable, UndoableAction
    implements Built<MoveHelicesToGroup, MoveHelicesToGroupBuilder> {
  BuiltList<int> get helix_idxs;

  String get group_name;

  /************************ begin BuiltValue boilerplate ************************/
  factory MoveHelicesToGroup({required BuiltList<int> helix_idxs, required String group_name}) =
      _$MoveHelicesToGroup._;

  MoveHelicesToGroup._();

  static Serializer<MoveHelicesToGroup> get serializer => _$moveHelicesToGroupSerializer;

  @memoized
  int get hashCode;

  @override
  String short_description() => "move helices to group";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// interactive dialog

abstract class DialogShow with BuiltJsonSerializable implements Action, Built<DialogShow, DialogShowBuilder> {
  Dialog get dialog;

  /************************ begin BuiltValue boilerplate ************************/
  factory DialogShow({required Dialog dialog}) = _$DialogShow._;

  DialogShow._();

  static Serializer<DialogShow> get serializer => _$dialogShowSerializer;
}

abstract class DialogHide with BuiltJsonSerializable implements Action, Built<DialogHide, DialogHideBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory DialogHide() = _$DialogHide;

  DialogHide._();

  static Serializer<DialogHide> get serializer => _$dialogHideSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// context menu

abstract class ContextMenuShow
    with BuiltJsonSerializable
    implements Action, Built<ContextMenuShow, ContextMenuShowBuilder> {
  ContextMenu get context_menu;

  /************************ begin BuiltValue boilerplate ************************/
  factory ContextMenuShow({required ContextMenu context_menu}) = _$ContextMenuShow._;

  ContextMenuShow._();

  static Serializer<ContextMenuShow> get serializer => _$contextMenuShowSerializer;
}

abstract class ContextMenuHide
    with BuiltJsonSerializable
    implements Action, Built<ContextMenuHide, ContextMenuHideBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory ContextMenuHide() = _$ContextMenuHide;

  ContextMenuHide._();

  static Serializer<ContextMenuHide> get serializer => _$contextMenuHideSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// color pickers

abstract class StrandOrSubstrandColorPickerShow
    with BuiltJsonSerializable
    implements Action, Built<StrandOrSubstrandColorPickerShow, StrandOrSubstrandColorPickerShowBuilder> {
  Strand get strand;

  Substrand? get substrand;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandOrSubstrandColorPickerShow({required Strand strand, Substrand? substrand}) =
      _$StrandOrSubstrandColorPickerShow._;

  StrandOrSubstrandColorPickerShow._();

  static Serializer<StrandOrSubstrandColorPickerShow> get serializer =>
      _$strandOrSubstrandColorPickerShowSerializer;
}

abstract class StrandOrSubstrandColorPickerHide
    with BuiltJsonSerializable
    implements Action, Built<StrandOrSubstrandColorPickerHide, StrandOrSubstrandColorPickerHideBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory StrandOrSubstrandColorPickerHide() => StrandOrSubstrandColorPickerHide.from((b) => b);

  factory StrandOrSubstrandColorPickerHide.from([
    void Function(StrandOrSubstrandColorPickerHideBuilder) updates,
  ]) = _$StrandOrSubstrandColorPickerHide;

  StrandOrSubstrandColorPickerHide._();

  static Serializer<StrandOrSubstrandColorPickerHide> get serializer =>
      _$strandOrSubstrandColorPickerHideSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// abstract supertype of actions that operate on a single strand

abstract class SingleStrandAction implements Action {
  Strand get strand;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// scaffold set/unset

abstract class ScaffoldSet
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<ScaffoldSet, ScaffoldSetBuilder> {
  Strand get strand;

  bool get is_scaffold;

  /************************ begin BuiltValue boilerplate ************************/
  factory ScaffoldSet({required Strand strand, required bool is_scaffold}) = _$ScaffoldSet._;

  ScaffoldSet._();

  static Serializer<ScaffoldSet> get serializer => _$scaffoldSetSerializer;

  @override
  String short_description() => "set scaffold";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Strand color set

abstract class StrandOrSubstrandColorSet
    with BuiltJsonSerializable, UndoableAction
    implements SingleStrandAction, Built<StrandOrSubstrandColorSet, StrandOrSubstrandColorSetBuilder> {
  Strand get strand;

  Substrand? get substrand;

  Color? get color;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandOrSubstrandColorSet({required Strand strand, Substrand? substrand, Color? color}) =
      _$StrandOrSubstrandColorSet._;

  StrandOrSubstrandColorSet._();

  static Serializer<StrandOrSubstrandColorSet> get serializer => _$strandOrSubstrandColorSetSerializer;

  @override
  String short_description() => "set strand or substrand color";
}

abstract class StrandPasteKeepColorSet
    with BuiltJsonSerializable
    implements Action, Built<StrandPasteKeepColorSet, StrandPasteKeepColorSetBuilder> {
  bool get keep;

  /************************ begin BuiltValue boilerplate ************************/
  factory StrandPasteKeepColorSet({required bool keep}) = _$StrandPasteKeepColorSet._;

  StrandPasteKeepColorSet._();

  static Serializer<StrandPasteKeepColorSet> get serializer => _$strandPasteKeepColorSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// example DNA design

abstract class ExampleDesignsLoad
    with BuiltJsonSerializable
    implements Action, Built<ExampleDesignsLoad, ExampleDesignsLoadBuilder> {
  int get selected_idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExampleDesignsLoad({required int selected_idx}) = _$ExampleDesignsLoad._;

  ExampleDesignsLoad._();

  static Serializer<ExampleDesignsLoad> get serializer => _$exampleDesignsLoadSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// pair lines display

abstract class BasePairTypeSet
    with BuiltJsonSerializable
    implements Action, Built<BasePairTypeSet, BasePairTypeSetBuilder> {
  int get selected_idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory BasePairTypeSet({required int selected_idx}) = _$BasePairTypeSet._;

  BasePairTypeSet._();

  static Serializer<BasePairTypeSet> get serializer => _$basePairTypeSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// change helix position

abstract class HelixPositionSet
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixPositionSet, HelixPositionSetBuilder> {
  int get helix_idx;

  Position3D get position;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixPositionSet({required int helix_idx, required Position3D position}) = _$HelixPositionSet._;

  HelixPositionSet._();

  static Serializer<HelixPositionSet> get serializer => _$helixPositionSetSerializer;

  @override
  String short_description() => "set helix position";
}

abstract class HelixGridPositionSet
    with BuiltJsonSerializable, UndoableAction
    implements HelixIndividualAction, Built<HelixGridPositionSet, HelixGridPositionSetBuilder> {
  Helix get helix;

  GridPosition get grid_position;

  int get helix_idx => helix.idx;

  /************************ begin BuiltValue boilerplate ************************/
  factory HelixGridPositionSet({required Helix helix, required GridPosition grid_position}) =
      _$HelixGridPositionSet._;

  HelixGridPositionSet._();

  static Serializer<HelixGridPositionSet> get serializer => _$helixGridPositionSetSerializer;

  @override
  String short_description() => "set helix grid position";
}

// NOTE: not an undoable action because it merely triggers middleware to gather data to send actions
// that actually change the Design, but it causes no change itself
abstract class HelicesPositionsSetBasedOnCrossovers
    with BuiltJsonSerializable
    implements
        Action,
        Built<HelicesPositionsSetBasedOnCrossovers, HelicesPositionsSetBasedOnCrossoversBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory HelicesPositionsSetBasedOnCrossovers() = _$HelicesPositionsSetBasedOnCrossovers;

  HelicesPositionsSetBasedOnCrossovers._();

  static Serializer<HelicesPositionsSetBasedOnCrossovers> get serializer =>
      _$helicesPositionsSetBasedOnCrossoversSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// inline insertions and deletions

abstract class InlineInsertionsDeletions
    with BuiltJsonSerializable, UndoableAction
    implements Action, Built<InlineInsertionsDeletions, InlineInsertionsDeletionsBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory InlineInsertionsDeletions() = _$InlineInsertionsDeletions;

  InlineInsertionsDeletions._();

  static Serializer<InlineInsertionsDeletions> get serializer => _$inlineInsertionsDeletionsSerializer;

  @override
  String short_description() => "inline insertions/deletions";
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// which crossovers to default to when setting helix positions/rolls based on crossover

abstract class DefaultCrossoverTypeForSettingHelixRollsSet
    with BuiltJsonSerializable
    implements
        Action,
        Built<
          DefaultCrossoverTypeForSettingHelixRollsSet,
          DefaultCrossoverTypeForSettingHelixRollsSetBuilder
        > {
  bool get scaffold;

  bool get staple;

  /************************ begin BuiltValue boilerplate ************************/
  factory DefaultCrossoverTypeForSettingHelixRollsSet({required bool scaffold, required bool staple}) =
      _$DefaultCrossoverTypeForSettingHelixRollsSet._;

  DefaultCrossoverTypeForSettingHelixRollsSet._();

  static Serializer<DefaultCrossoverTypeForSettingHelixRollsSet> get serializer =>
      _$defaultCrossoverTypeForSettingHelixRollsSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// center on load

abstract class AutofitSet with BuiltJsonSerializable implements Action, Built<AutofitSet, AutofitSetBuilder> {
  bool get autofit;

  /************************ begin BuiltValue boilerplate ************************/
  factory AutofitSet({required bool autofit}) = _$AutofitSet._;

  AutofitSet._();

  static Serializer<AutofitSet> get serializer => _$autofitSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// show or hide helix circles/text, or entire helix (including offset lines) in main view

abstract class ShowHelixCirclesMainViewSet
    with BuiltJsonSerializable
    implements Action, Built<ShowHelixCirclesMainViewSet, ShowHelixCirclesMainViewSetBuilder> {
  bool get show_helix_circles_main_view;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowHelixCirclesMainViewSet({required bool show_helix_circles_main_view}) =
      _$ShowHelixCirclesMainViewSet._;

  ShowHelixCirclesMainViewSet._();

  static Serializer<ShowHelixCirclesMainViewSet> get serializer => _$showHelixCirclesMainViewSetSerializer;
}

abstract class ShowHelixComponentsMainViewSet
    with BuiltJsonSerializable
    implements Action, Built<ShowHelixComponentsMainViewSet, ShowHelixComponentsMainViewSetBuilder> {
  bool get show_helix_components;

  /************************ begin BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  factory ShowHelixComponentsMainViewSet({required bool show_helix_components}) =
      _$ShowHelixComponentsMainViewSet._;

  factory ShowHelixComponentsMainViewSet.from([
    void Function(ShowHelixComponentsMainViewSetBuilder) updates,
  ]) = _$ShowHelixComponentsMainViewSet;

  ShowHelixComponentsMainViewSet._();

  static Serializer<ShowHelixComponentsMainViewSet> get serializer =>
      _$showHelixComponentsMainViewSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// show or hide the edit menu

abstract class ShowEditMenuToggle
    with BuiltJsonSerializable
    implements Action, Built<ShowEditMenuToggle, ShowEditMenuToggleBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory ShowEditMenuToggle() = _$ShowEditMenuToggle._;

  ShowEditMenuToggle._();

  static Serializer<ShowEditMenuToggle> get serializer => _$showEditMenuToggleSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// show or hide grid coordinates in side view

abstract class ShowGridCoordinatesSideViewSet
    with BuiltJsonSerializable
    implements Action, Built<ShowGridCoordinatesSideViewSet, ShowGridCoordinatesSideViewSetBuilder> {
  bool get show_grid_coordinates_side_view;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowGridCoordinatesSideViewSet({required bool show_grid_coordinates_side_view}) =
      _$ShowGridCoordinatesSideViewSet._;

  ShowGridCoordinatesSideViewSet._();

  static Serializer<ShowGridCoordinatesSideViewSet> get serializer =>
      _$showGridCoordinatesSideViewSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// show or hide helix axis arrows

abstract class ShowAxisArrowsSet
    with BuiltJsonSerializable
    implements Action, Built<ShowAxisArrowsSet, ShowAxisArrowsSetBuilder> {
  bool get show_helices_axis_arrows;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowAxisArrowsSet({required bool show_helices_axis_arrows}) = _$ShowAxisArrowsSet._;

  ShowAxisArrowsSet._();

  static Serializer<ShowAxisArrowsSet> get serializer => _$showAxisArrowsSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// show or hide loopout and extension lengths displayed next to the substrand

abstract class ShowLoopoutExtensionLengthSet
    with BuiltJsonSerializable
    implements Action, Built<ShowLoopoutExtensionLengthSet, ShowLoopoutExtensionLengthSetBuilder> {
  bool get show_length;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowLoopoutExtensionLengthSet({required bool show_length}) = _$ShowLoopoutExtensionLengthSet._;

  ShowLoopoutExtensionLengthSet._();

  static Serializer<ShowLoopoutExtensionLengthSet> get serializer =>
      _$showLoopoutExtensionLengthSetSerializer;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// load dna sequence png

abstract class LoadDnaSequenceImageUri
    with BuiltJsonSerializable
    implements Action, Built<LoadDnaSequenceImageUri, LoadDnaSequenceImageUriBuilder> {
  String? get uri;

  double get dna_sequence_png_horizontal_offset;

  double get dna_sequence_png_vertical_offset;

  /************************ begin BuiltValue boilerplate ************************/
  factory LoadDnaSequenceImageUri(
    String? uri,
    double dna_sequence_png_horizontal_offset,
    double dna_sequence_png_vertical_offset,
  ) => LoadDnaSequenceImageUri.from(
    (b) =>
        b
          ..uri = uri
          ..dna_sequence_png_horizontal_offset = dna_sequence_png_horizontal_offset
          ..dna_sequence_png_vertical_offset = dna_sequence_png_vertical_offset,
  );

  factory LoadDnaSequenceImageUri.from(void Function(LoadDnaSequenceImageUriBuilder) updates) =
      _$LoadDnaSequenceImageUri;

  LoadDnaSequenceImageUri._();

  static Serializer<LoadDnaSequenceImageUri> get serializer => _$loadDnaSequenceImageUriSerializer;
}

abstract class SetIsZoomAboveThreshold
    with BuiltJsonSerializable
    implements Action, Built<SetIsZoomAboveThreshold, SetIsZoomAboveThresholdBuilder> {
  bool get is_zoom_above_threshold;

  /************************ begin BuiltValue boilerplate ************************/
  factory SetIsZoomAboveThreshold(bool is_zoom_above_threshold) =>
      SetIsZoomAboveThreshold.from((b) => b..is_zoom_above_threshold = is_zoom_above_threshold);

  factory SetIsZoomAboveThreshold.from(void Function(SetIsZoomAboveThresholdBuilder) updates) =
      _$SetIsZoomAboveThreshold;

  SetIsZoomAboveThreshold._();

  static Serializer<SetIsZoomAboveThreshold> get serializer => _$setIsZoomAboveThresholdSerializer;
}

abstract class SetExportSvgActionDelayedForPngCache
    with BuiltJsonSerializable
    implements
        Action,
        Built<SetExportSvgActionDelayedForPngCache, SetExportSvgActionDelayedForPngCacheBuilder> {
  ExportSvg? get export_svg_action_delayed_for_png_cache;

  /************************ begin BuiltValue boilerplate ************************/
  factory SetExportSvgActionDelayedForPngCache(ExportSvg? export_svg_action_delayed_for_png_cache) =>
      SetExportSvgActionDelayedForPngCache.from(
        (b) =>
            b..export_svg_action_delayed_for_png_cache = export_svg_action_delayed_for_png_cache?.toBuilder(),
      );

  factory SetExportSvgActionDelayedForPngCache.from([
    void Function(SetExportSvgActionDelayedForPngCacheBuilder) updates,
  ]) = _$SetExportSvgActionDelayedForPngCache;

  SetExportSvgActionDelayedForPngCache._();

  static Serializer<SetExportSvgActionDelayedForPngCache> get serializer =>
      _$setExportSvgActionDelayedForPngCacheSerializer;
}

abstract class ShowBasePairLinesSet
    with BuiltJsonSerializable
    implements Action, Built<ShowBasePairLinesSet, ShowBasePairLinesSetBuilder> {
  bool get show_base_pair_lines;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowBasePairLinesSet({required bool show_base_pair_lines}) = _$ShowBasePairLinesSet._;

  ShowBasePairLinesSet._();

  static Serializer<ShowBasePairLinesSet> get serializer => _$showBasePairLinesSetSerializer;

  @memoized
  int get hashCode;
}

abstract class ExportBasePairLinesIfOtherStrandNotSelectedSet
    with BuiltJsonSerializable
    implements
        Action,
        Built<
          ExportBasePairLinesIfOtherStrandNotSelectedSet,
          ExportBasePairLinesIfOtherStrandNotSelectedSetBuilder
        > {
  bool get export_base_pair_lines_if_other_strand_not_selected;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExportBasePairLinesIfOtherStrandNotSelectedSet({
    required bool export_base_pair_lines_if_other_strand_not_selected,
  }) = _$ExportBasePairLinesIfOtherStrandNotSelectedSet._;

  ExportBasePairLinesIfOtherStrandNotSelectedSet._();

  static Serializer<ExportBasePairLinesIfOtherStrandNotSelectedSet> get serializer =>
      _$exportBasePairLinesIfOtherStrandNotSelectedSetSerializer;

  @memoized
  int get hashCode;
}

abstract class ShowBasePairLinesWithMismatchesSet
    with BuiltJsonSerializable
    implements Action, Built<ShowBasePairLinesWithMismatchesSet, ShowBasePairLinesWithMismatchesSetBuilder> {
  bool get show_base_pair_lines_with_mismatches;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowBasePairLinesWithMismatchesSet({required bool show_base_pair_lines_with_mismatches}) =
      _$ShowBasePairLinesWithMismatchesSet._;

  ShowBasePairLinesWithMismatchesSet._();

  static Serializer<ShowBasePairLinesWithMismatchesSet> get serializer =>
      _$showBasePairLinesWithMismatchesSetSerializer;

  @memoized
  int get hashCode;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// slice bar

abstract class ShowSliceBarSet
    with BuiltJsonSerializable
    implements Action, Built<ShowSliceBarSet, ShowSliceBarSetBuilder> {
  bool get show;

  /************************ begin BuiltValue boilerplate ************************/
  factory ShowSliceBarSet(bool show) => ShowSliceBarSet.from((b) => b..show = show);

  factory ShowSliceBarSet.from([void Function(ShowSliceBarSetBuilder) updates]) = _$ShowSliceBarSet;

  ShowSliceBarSet._();

  static Serializer<ShowSliceBarSet> get serializer => _$showSliceBarSetSerializer;
}

abstract class SliceBarOffsetSet
    with BuiltJsonSerializable
    implements Action, Built<SliceBarOffsetSet, SliceBarOffsetSetBuilder> {
  int get offset;

  /************************ begin BuiltValue boilerplate ************************/
  factory SliceBarOffsetSet(int offset) => SliceBarOffsetSet.from((b) => b..offset = offset);

  factory SliceBarOffsetSet.from([void Function(SliceBarOffsetSetBuilder) updates]) = _$SliceBarOffsetSet;

  SliceBarOffsetSet._();

  static Serializer<SliceBarOffsetSet> get serializer => _$sliceBarOffsetSetSerializer;
}

abstract class DisablePngCachingDnaSequencesSet
    with BuiltJsonSerializable
    implements Action, Built<DisablePngCachingDnaSequencesSet, DisablePngCachingDnaSequencesSetBuilder> {
  bool get disable_png_caching_dna_sequences;

  /************************ begin BuiltValue boilerplate ************************/
  factory DisablePngCachingDnaSequencesSet(bool disable_png_caching_dna_sequences) =>
      DisablePngCachingDnaSequencesSet.from(
        (b) => b..disable_png_caching_dna_sequences = disable_png_caching_dna_sequences,
      );

  factory DisablePngCachingDnaSequencesSet.from([
    void Function(DisablePngCachingDnaSequencesSetBuilder) updates,
  ]) = _$DisablePngCachingDnaSequencesSet;

  DisablePngCachingDnaSequencesSet._();

  static Serializer<DisablePngCachingDnaSequencesSet> get serializer =>
      _$disablePngCachingDnaSequencesSetSerializer;
}

abstract class RetainStrandColorOnSelectionSet
    with BuiltJsonSerializable
    implements Action, Built<RetainStrandColorOnSelectionSet, RetainStrandColorOnSelectionSetBuilder> {
  bool get retain_strand_color_on_selection;

  /************************ begin BuiltValue boilerplate ************************/
  factory RetainStrandColorOnSelectionSet(bool retain_strand_color_on_selection) =>
      RetainStrandColorOnSelectionSet.from(
        (b) => b..retain_strand_color_on_selection = retain_strand_color_on_selection,
      );

  factory RetainStrandColorOnSelectionSet.from([
    void Function(RetainStrandColorOnSelectionSetBuilder) updates,
  ]) = _$RetainStrandColorOnSelectionSet;

  RetainStrandColorOnSelectionSet._();

  static Serializer<RetainStrandColorOnSelectionSet> get serializer =>
      _$retainStrandColorOnSelectionSetSerializer;
}

abstract class DisplayReverseDNARightSideUpSet
    with BuiltJsonSerializable
    implements Action, Built<DisplayReverseDNARightSideUpSet, DisplayReverseDNARightSideUpSetBuilder> {
  bool get display_reverse_DNA_right_side_up;

  /************************ begin BuiltValue boilerplate ************************/
  factory DisplayReverseDNARightSideUpSet(bool display_reverse_DNA_right_side_up) =>
      DisplayReverseDNARightSideUpSet.from(
        (b) => b..display_reverse_DNA_right_side_up = display_reverse_DNA_right_side_up,
      );

  factory DisplayReverseDNARightSideUpSet.from([
    void Function(DisplayReverseDNARightSideUpSetBuilder) updates,
  ]) = _$DisplayReverseDNARightSideUpSet;

  DisplayReverseDNARightSideUpSet._();

  static Serializer<DisplayReverseDNARightSideUpSet> get serializer =>
      _$displayReverseDNARightSideUpSetSerializer;
}

abstract class SliceBarMoveStart
    with BuiltJsonSerializable
    implements Action, Built<SliceBarMoveStart, SliceBarMoveStartBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SliceBarMoveStart([void Function(SliceBarMoveStartBuilder) updates]) = _$SliceBarMoveStart;

  SliceBarMoveStart._();

  static Serializer<SliceBarMoveStart> get serializer => _$sliceBarMoveStartSerializer;
}

abstract class SliceBarMoveStop
    with BuiltJsonSerializable
    implements Action, Built<SliceBarMoveStop, SliceBarMoveStopBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory SliceBarMoveStop([void Function(SliceBarMoveStopBuilder) updates]) = _$SliceBarMoveStop;

  SliceBarMoveStop._();

  static Serializer<SliceBarMoveStop> get serializer => _$sliceBarMoveStopSerializer;
}
// autostaple

abstract class Autostaple with BuiltJsonSerializable implements Action, Built<Autostaple, AutostapleBuilder> {
  /************************ begin BuiltValue boilerplate ************************/
  factory Autostaple([void Function(AutostapleBuilder) updates]) = _$Autostaple;

  Autostaple._();

  static Serializer<Autostaple> get serializer => _$autostapleSerializer;
}

abstract class Autobreak with BuiltJsonSerializable implements Action, Built<Autobreak, AutobreakBuilder> {
  int get target_length;

  int get min_length;

  int get max_length;

  int get min_distance_to_xover;

  /************************ begin BuiltValue boilerplate ************************/
  factory Autobreak({
    required int target_length,
    required int min_length,
    required int max_length,
    required int min_distance_to_xover,
  }) => Autobreak.from(
    (b) =>
        b
          ..target_length = target_length
          ..min_length = min_length
          ..max_length = max_length
          ..min_distance_to_xover = min_distance_to_xover,
  );

  factory Autobreak.from([void Function(AutobreakBuilder) updates]) = _$Autobreak;

  Autobreak._();

  static Serializer<Autobreak> get serializer => _$autobreakSerializer;
}

abstract class ZoomSpeedSet
    with BuiltJsonSerializable
    implements Action, Built<ZoomSpeedSet, ZoomSpeedSetBuilder> {
  double get speed;

  /************************ begin BuiltValue boilerplate ************************/
  factory ZoomSpeedSet({required double speed}) = _$ZoomSpeedSet._;

  ZoomSpeedSet._();

  static Serializer<ZoomSpeedSet> get serializer => _$zoomSpeedSetSerializer;

  @memoized
  int get hashCode;
}

abstract class OxdnaExport
    with BuiltJsonSerializable
    implements Action, Built<OxdnaExport, OxdnaExportBuilder> {
  bool get selected_strands_only;

  /************************ begin BuiltValue boilerplate ************************/
  factory OxdnaExport({bool selected_strands_only = false}) {
    return OxdnaExport.from((b) => b..selected_strands_only = selected_strands_only);
  }

  OxdnaExport._();

  factory OxdnaExport.from([void Function(OxdnaExportBuilder) updates]) = _$OxdnaExport;

  static Serializer<OxdnaExport> get serializer => _$oxdnaExportSerializer;

  @memoized
  int get hashCode;
}

abstract class OxviewExport
    with BuiltJsonSerializable
    implements Action, Built<OxviewExport, OxviewExportBuilder> {
  bool get selected_strands_only;

  /************************ begin BuiltValue boilerplate ************************/
  factory OxviewExport({bool selected_strands_only = false}) {
    return OxviewExport.from((b) => b..selected_strands_only = selected_strands_only);
  }

  OxviewExport._();

  factory OxviewExport.from([void Function(OxviewExportBuilder) updates]) = _$OxviewExport;

  static Serializer<OxviewExport> get serializer => _$oxviewExportSerializer;

  @memoized
  int get hashCode;
}

abstract class OxExportOnlySelectedStrandsSet
    with BuiltJsonSerializable
    implements Action, Built<OxExportOnlySelectedStrandsSet, OxExportOnlySelectedStrandsSetBuilder> {
  bool get only_selected;

  /************************ begin BuiltValue boilerplate ************************/
  factory OxExportOnlySelectedStrandsSet({required bool only_selected}) = _$OxExportOnlySelectedStrandsSet._;

  OxExportOnlySelectedStrandsSet._();

  static Serializer<OxExportOnlySelectedStrandsSet> get serializer =>
      _$oxExportOnlySelectedStrandsSetSerializer;

  @memoized
  int get hashCode;
}
