import 'dart:math';

import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:color/color.dart';

import 'actions/actions.dart';
import 'state/dna_end.dart';
import 'state/dna_end_move.dart';
import 'state/edit_mode.dart';
import 'state/export_dna_format.dart';
import 'state/potential_crossover.dart';
import 'state/selectable.dart';
import 'state/app_ui_state.dart';
import 'state/substrand.dart';
import 'state/grid.dart';
import 'state/helix.dart';
import 'state/idt_fields.dart';
import 'state/loopout.dart';
import 'state/mouseover_data.dart';
import 'state/position3d.dart';
import 'state/select_mode.dart';
import 'state/bound_substrand.dart';
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
  SetShowDNA,
  SetShowMismatches,
  SetShowEditor,
  SaveDNAFile,
  LoadDNAFile,
  MouseoverDataClear,
  MouseoverDataUpdate,
  SelectionBoxCreate,
  SelectionBoxSizeChange,
  SelectionBoxRemove,
  MouseoverParams,
  Helix,
  BoundSubstrand,
  Strand,
  Crossover,
  DNAEnd,
  IDTFields,
  GridPosition,
  Position3D,
  Point,
  AppUIState,
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
  HelixRotationSet,
  HelixRotationSetAtOther,
  Undo,
  Redo,
  UndoRedoClear,
  MouseGridPositionSideUpdate,
  MouseGridPositionSideClear,
  HelixSelectionsAdjust,
  HelixSelectionsClear,
  HelixSelect,
  SelectionsAdjust,
  SelectionsClear,
  DeleteAllSelected,
  Select,
  Loopout,
  LoopoutLengthChange,
  ConvertCrossoverToLoopout,
  EditModeChoice,
  EditModeToggle,
  EditModesSet,
  HelixAdd,
  HelixRemove,
  HelixOffsetChange,
  HelixOffsetChangeAll,
  StrandCreate,
  Nick,
  Ligate,
  JoinStrandsByCrossover,
  PotentialCrossover,
  PotentialCrossoverCreate,
  PotentialCrossoverMove,
  PotentialCrossoverRemove,
  DNAEndMove,
  DNAEndsMove,
  DNAEndsMoveStart,
  DNAEndsMoveSetSelectedEnds,
  DNAEndsMoveAdjustOffset,
  DNAEndsMoveStop,
  DNAEndsMoveCommit,
  AssignDNA,
  ExportDNA,
  ExportDNAFormat,
  ErrorMessageSet,
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
