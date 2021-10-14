import 'dart:math';
import 'dart:convert' as convert;

import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:color/color.dart';
import 'package:tuple/tuple.dart';

import 'state/domains_move.dart';
import 'state/helix_group_move.dart';
import 'state/copy_info.dart';
import 'state/address.dart';
import 'state/substrand.dart'; // analyzer says this is not used, but if deleted it breaks the code generation

import 'state/group.dart';
import 'actions/actions.dart';
import 'dna_sequence_constants.dart';
import 'state/local_storage_design_choice.dart';
import 'state/context_menu.dart';
import 'state/dialog.dart';
import 'state/design.dart';
import 'state/dna_end.dart';
import 'state/dna_ends_move.dart';
import 'state/edit_mode.dart';
import 'state/example_designs.dart';
import 'state/export_dna_format.dart';
import 'state/export_dna_format_strand_order.dart';
import 'state/geometry.dart';
import 'state/modification.dart';
import 'state/potential_crossover.dart';
import 'state/potential_vertical_crossover.dart';
import 'state/selectable.dart';
import 'state/app_ui_state.dart';
import 'state/app_ui_state_storables.dart';
import 'state/strand_creation.dart';
import 'state/strands_move.dart';
import 'state/grid.dart';
import 'state/helix.dart';
import 'state/idt_fields.dart';
import 'state/loopout.dart';
import 'state/mouseover_data.dart';
import 'state/position3d.dart';
import 'state/select_mode.dart';
import 'state/domain.dart';
import 'state/grid_position.dart';
import 'state/selection_box.dart';
import 'state/selection_rope.dart';
import 'state/select_mode_state.dart';
import 'state/strand.dart';
import 'state/crossover.dart';
import 'state/design_side_rotation_data.dart';
import 'state/domain_name_mismatch.dart';

part 'serializers.g.dart';

@SerializersFor([
  ShowEditMenuToggle,
  ShowAxisArrowsSet,
  IDTFieldsRemove,
  PlateWellIDTFieldsRemove,
  PlateWellIDTFieldsAssign,
  ScalePurificationIDTFieldsAssign,
  StrandNameSet,
  SubstrandNameSet,
  DomainNameMismatch,
  ShowDomainNameMismatchesSet,
  ModificationEdit,
  Modifications5PrimeEdit,
  Modifications3PrimeEdit,
  ModificationsInternalEdit,
  ModificationRemove,
  ModificationAdd,
  ShowLoopoutLengthSet,
  HelixGroupMove,
  HelixGroupMoveStart,
  HelixGroupMoveCreate,
  HelixGroupMoveAdjustTranslation,
  HelixGroupMoveStop,
  HelixGroupMoveCommit,
  GroupDisplayedChange,
  GroupAdd,
  GroupRemove,
  GroupChange,
  LocalStorageDesignOption,
  LocalStorageDesignChoice,
  LocalStorageDesignChoiceSet,
  ClearHelixSelectionWhenLoadingNewDesignSet,
  StrandsReflect,
  ReplaceStrands,
  ShowGridCoordinatesSideViewSet,
  ShowHelixCirclesMainViewSet,
  SelectModeToggle,
  SelectModesSet,
  SelectModesAdd,
  SelectionBox,
  ShowDNASet,
  ShowDomainNamesSet,
  ShowStrandNamesSet,
  ShowModificationsSet,
  ShowMismatchesSet,
  SetShowEditor,
  SaveDNAFile,
  LoadDNAFile,
  ExportCadnanoFile,
  ExportCodenanoFile,
  MouseoverDataClear,
  MouseoverDataUpdate,
  SelectionBoxCreate,
  SelectionBoxSizeChange,
  SelectionBoxRemove,
  SelectionRope,
  Line,
  SelectionRopeCreate,
  SelectionRopeMouseMove,
  SelectionRopeAddPoint,
  SelectionRopeRemove,
  MouseoverParams,
  DesignSideRotationParams,
  DesignSideRotationData,
  Helix,
  HelixGroup,
  Domain,
  Strand,
  Geometry,
  Crossover,
  DNAEnd,
  IDTFields,
  GridPosition,
  Position3D,
  Point,
  AppUIState,
  AppUIStateStorables,
  SelectablesStore,
  SelectionBox,
  SelectModeChoice,
  SelectModeState,
  ShowMouseoverRectSet,
  ShowMouseoverRectToggle,
  MouseoverDataUpdate,
  MouseoverDataClear,
  Grid,
  BatchAction,
  Undo,
  Redo,
  UndoRedoClear,
  MouseGridPositionSideUpdate,
  MouseGridPositionSideClear,
  MousePositionSideUpdate,
  MousePositionSideClear,
  HelixSelectionsAdjust,
  HelixSelectionsClear,
  HelixSelect,
  SelectionsAdjustMainView,
  SelectionsClear,
  SelectOrToggleItems,
  DeleteAllSelected,
  SelectAll,
  SelectAllSelectable,
  Select,
  Loopout,
  LoopoutLengthChange,
  LoopoutsLengthChange,
  ConvertCrossoverToLoopout,
  ConvertCrossoversToLoopouts,
  EditModeChoice,
  EditModeToggle,
  EditModesSet,
  GeometrySet,
  HelixAdd,
  HelixRemove,
  HelixRemoveAllSelected,
  HelixMinOffsetSetByDomains,
  HelixMaxOffsetSetByDomains,
  HelixMinOffsetSetByDomainsAll,
  HelixMaxOffsetSetByDomainsAll,
  HelixOffsetChange,
  HelixOffsetChangeAll,
  HelixIdxsChange,
  HelixMajorTickDistanceChange,
  HelixMajorTickDistanceChangeAll,
  HelixMajorTicksChange,
  HelixMajorTicksChangeAll,
  HelixMajorTickPeriodicDistancesChange,
  HelixMajorTickPeriodicDistancesChangeAll,
  HelixMajorTickStartChange,
  HelixMajorTickStartChangeAll,
  HelixRollSet,
  HelixRollSetAtOther,
  DefaultCrossoverTypeForSettingHelixRollsSet,
  Nick,
  Ligate,
  JoinStrandsByCrossover,
  JoinStrandsByMultipleCrossovers,
  PotentialVerticalCrossover,
  PotentialCrossover,
  PotentialCrossoverCreate,
  PotentialCrossoverMove,
  PotentialCrossoverRemove,
  WarnOnExitIfUnsavedSet,
  AssignDNA,
  AssignDNAComplementFromBoundStrands,
  RemoveDNA,
  ExportDNA,
  ExportDNAFormat,
  ErrorMessageSet,
  Insertion,
  SelectableInsertion,
  SelectableDeletion,
  InsertionAdd,
  DeletionAdd,
  InsertionRemove,
  DeletionRemove,
  InsertionLengthChange,
  InsertionsLengthChange,
  StrandCreation,
  StrandCreateStart,
  StrandCreateAdjustOffset,
  StrandCreateStop,
  StrandCreateCommit,
  DNAEndMove,
  DNAEndsMove,
  DNAEndsMoveStart,
  DNAEndsMoveStop,
  DNAEndsMoveSetSelectedEnds,
  DNAEndsMoveAdjustOffset,
  DNAEndsMoveCommit,
  // CopySelectedObjectTextToSystemClipboard,
  AutoPasteInitiate,
  ManualPasteInitiate,
  CopySelectedStrands,
  // StrandsAutoPaste,
  // StrandsCopyBufferClear,
  // UpdateCopyInfo,
  CopyInfo,
  StrandsMove,
  StrandsMoveStart,
  StrandsMoveStartSelectedStrands,
  StrandsMoveStop,
  StrandsMoveAdjustAddress,
  StrandsMoveCommit,
  DomainsMove,
  DomainsMoveStartSelectedDomains,
  DomainsMoveStop,
  DomainsMoveAdjustAddress,
  DomainsMoveCommit,
  GridChange,
  ThrottledActionFast,
  ThrottledActionNonFast,
  ContextMenu,
  ContextMenuItem,
  ContextMenuShow,
  ContextMenuHide,
  ScaffoldSet,
  Address,
  AddressDifference,
  Dialog,
  DialogItem,
  DialogText,
  DialogInteger,
  DialogFloat,
  DialogTextArea,
  DialogCheckbox,
  DialogRadio,
  DialogShow,
  DialogHide,
  DialogLink,
  StrandOrder,
  StrandColorSet,
  StrandColorPickerShow,
  StrandColorPickerHide,
  StrandPasteKeepColorSet,
  ExampleDesigns,
  ExampleDesignsLoad,
  HelixPositionSet,
  HelixGridPositionSet,
  InlineInsertionsDeletions,
  AutofitSet,
  ExportSvg,
  Modification5Prime,
  Modification3Prime,
  ModificationInternal,
  SelectableModification5Prime,
  SelectableModification3Prime,
  SelectableModificationInternal,
  LoadDnaSequenceImageUri,
  SetDisablePngCacheUntilActionCompletes,
  SetIsZoomAboveThreshold,
  DNASequencePredefined,
  SetOnlyDisplaySelectedHelices,
  InvertXYSet,
  SetModificationDisplayConnector,
  ModificationFontSizeSet,
  DomainNameFontSizeSet,
  StrandNameFontSizeSet,
  MajorTickOffsetFontSizeSet,
  MajorTickWidthFontSizeSet,
  HelicesPositionsSetBasedOnCrossovers,
  SetAppUIStateStorable,
  DisplayMajorTicksOffsetsSet,
  SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix,
  SetDisplayMajorTickWidths,
  SetDisplayMajorTickWidthsAllHelices,
  SliceBarOffsetSet,
  SliceBarMoveStart,
  SliceBarMoveStop,
  ShowSliceBarSet,
  ShowMouseoverDataSet,
  Autostaple,
  Autobreak,
  ZoomSpeedSet,
  NewDesignSet,
  OxdnaExport,
  Design,
  AssignDomainNameComplementFromBoundStrands,
  AssignDomainNameComplementFromBoundDomains,
  // BrowserClipboard,
  // CLIClipboard,
])
Serializers serializers = _$serializers;

Serializers standard_serializers = (serializers.toBuilder()
      ..add(PointSerializer<num>())
      ..add(ColorSerializer())
      ..addPlugin(new StandardJsonPlugin()))
    .build();

//Serializers standard_serializers2 = (serializers.toBuilder()..addPlugin(new StandardJsonPlugin())).build();

mixin BuiltJsonSerializable {
  dynamic toJson() => standard_serializers.serialize(this);
}

//// got this from https://github.com/google/built_value.dart/issues/417#issuecomment-391661750
//class LoopoutSerializer implements PrimitiveSerializer<Loopout> {
//  final bool structured = false;
//  @override
//  final Iterable<Type> types = new BuiltList<Type>([Loopout]);
//  @override
//  final String wireName = 'Loopout';
//
//  @override
//  Object serialize(Serializers serializers, Loopout loopout, {FullType specifiedType: FullType.unspecified}) {
//    return loopout.toJson();
//  }
//
//  @override
//  Loopout deserialize(Serializers serializers, Object serialized,
//      {FullType specifiedType: FullType.unspecified}) {
//    var loopout_json = serialized as Map<String, dynamic>;
//    return Loopout.from_json(loopout_json).build();
//  }
//}

// got this from https://github.com/google/built_value.dart/issues/417#issuecomment-391661750
class PointSerializer<T extends num> implements PrimitiveSerializer<Point<T>> {
  final bool structured = false;
  @override
  final Iterable<Type> types = new BuiltList<Type>([Point]);
  @override
  final String wireName = 'Point';

  @override
  Object serialize(Serializers serializers, Point<T> point, {FullType specifiedType: FullType.unspecified}) {
    return {'x': point.x.toString(), 'y': point.y.toString()};
  }

  @override
  Point<T> deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType: FullType.unspecified}) {
    Map map = serialized as Map;
    return Point<T>(num.parse(map['x']), num.parse(map['y']));
  }
}

// got this from https://github.com/google/built_value.dart/issues/417#issuecomment-391661750
class ColorSerializer implements PrimitiveSerializer<Color> {
  final bool structured = false;
  @override
  final Iterable<Type> types = new BuiltList<Type>([Color]);
  @override
  final String wireName = 'Color';

  @override
  Object serialize(Serializers serializers, Color color, {FullType specifiedType: FullType.unspecified}) {
    return color.toHexColor().toCssString();
  }

  @override
  Color deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType: FullType.unspecified}) {
    String color_hex = serialized as String;
    return Color.hex(color_hex);
  }
}

//class UnusedFieldsSerializer implements PrimitiveSerializer<Color> {
//  final bool structured = false;
//  @override
//  final Iterable<Type> types = new BuiltList<Type>([convert._JsonMap]);
//  @override
//  final String wireName = '_JsonMap';
//
//  @override
//  Object serialize(Serializers serializers, Color color, {FullType specifiedType: FullType.unspecified}) {
//    return color.toHexColor().toCssString();
//  }
//
//  @override
//  Color deserialize(Serializers serializers, Object serialized,
//      {FullType specifiedType: FullType.unspecified}) {
//    String color_hex = serialized as String;
//    return Color.hex(color_hex);
//  }
//}
