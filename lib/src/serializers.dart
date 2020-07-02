import 'dart:math';
import 'dart:convert' as convert;

import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:color/color.dart';

import 'actions/actions.dart';
import 'dna_sequence_constants.dart';
import 'state/context_menu.dart';
import 'state/dialog.dart';
import 'state/dna_end.dart';
import 'state/dna_ends_move.dart';
import 'state/edit_mode.dart';
import 'state/example_dna_designs.dart';
import 'state/export_dna_format.dart';
import 'state/geometry.dart';
import 'state/modification.dart';
import 'state/potential_crossover.dart';
import 'state/potential_vertical_crossover.dart';
import 'state/selectable.dart';
import 'state/app_ui_state.dart';
import 'state/strand_creation.dart';
import 'state/strands_move.dart';
import 'state/substrand.dart';
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
import 'state/select_mode_state.dart';
import 'state/strand.dart';
import 'state/crossover.dart';

part 'serializers.g.dart';

@SerializersFor([
  SelectModeToggle,
  SelectModesSet,
  SelectionBox,
  ShowDNASet,
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
  MouseoverParams,
  Helix,
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
  AppUIStateStorable,
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
  SelectionsAdjust,
  SelectionsClear,
  DeleteAllSelected,
  SelectAll,
  SelectAllSelectable,
  Select,
  Loopout,
  LoopoutLengthChange,
  ConvertCrossoverToLoopout,
  EditModeChoice,
  EditModeToggle,
  EditModesSet,
  HelixAdd,
  HelixRemove,
  HelixRemoveAllSelected,
  HelixOffsetChange,
  HelixOffsetChangeAll,
  HelixMajorTickDistanceChange,
  HelixMajorTickDistanceChangeAll,
  HelixMajorTicksChange,
  HelixMajorTicksChangeAll,
  HelixRollSet,
  HelixRollSetAtOther,
  Nick,
  Ligate,
  JoinStrandsByCrossover,
  PotentialVerticalCrossover,
  PotentialCrossover,
  PotentialCrossoverCreate,
  PotentialCrossoverMove,
  PotentialCrossoverRemove,
  AssignDNA,
  RemoveDNA,
  ExportDNA,
  ExportDNAFormat,
  ErrorMessageSet,
  InsertionAdd,
  DeletionAdd,
  InsertionRemove,
  DeletionRemove,
  InsertionLengthChange,
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
  StrandsMove,
  StrandsMoveStart,
  StrandsMoveStartSelectedStrands,
  StrandsMoveStop,
  StrandsMoveAdjustAddress,
  StrandsMoveCommit,
  GridChange,
  ThrottledActionFast,
  ThrottledActionNonFast,
  ContextMenu,
  ContextMenuItem,
  ContextMenuShow,
  ContextMenuHide,
  ScaffoldSet,
  Address,
  Dialog,
  DialogItem,
  DialogText,
  DialogNumber,
  DialogFloatingNumber,
  DialogTextArea,
  DialogCheckbox,
  DialogSelect,
  DialogRadio,
  DialogShow,
  DialogHide,
  StrandColorSet,
  StrandPasteKeepColorSet,
  ExampleDNADesigns,
  ExampleDNADesignsLoad,
  HelixPositionSet,
  HelixGridPositionSet,
  InlineInsertionsDeletions,
  AutofitSet,
  ExportSvg,
  Modification5Prime,
  Modification3Prime,
  ModificationInternal,
  LoadDnaSequenceImageUri,
  SetDisablePngCacheUntilActionCompletes,
  SetIsZoomAboveThreshold,
  DNASequencePredefined,
  SetOnlyDisplaySelectedHelices,
  InvertYAxisSet,
  SetModificationDisplayConnector,
  ModificationFontSizeSet,
  MajorTickOffsetFontSizeSet,
  MajorTickWidthFontSizeSet,
  HelicesPositionsSetBasedOnCrossovers,
  SetAppUIStateStorable,
  DisplayMajorTicksOffsetsSet,
  SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix,
  SetDisplayMajorTickWidths,
  SetDisplayMajorTickWidthsAllHelices,
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
