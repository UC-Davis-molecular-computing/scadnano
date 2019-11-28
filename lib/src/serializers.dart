import 'dart:math';

import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/standard_json_plugin.dart';

import 'package:scadnano/src/model/selectable.dart';
import 'package:scadnano/src/model/ui_model.dart';
import 'package:scadnano/src/view/select_mode.dart';
import 'model/grid.dart';
import 'model/helix.dart';
import 'model/mouseover_data.dart';
import 'model/position3d.dart';
import 'model/select_mode.dart';
import 'model/bound_substrand.dart';
import 'model/grid_position.dart';
import 'actions/actions.dart';
import 'model/selection_box.dart';
import 'model/select_mode_state.dart';

part 'serializers.g.dart';

@SerializersFor([
  ToggleSelectMode,
  SetSelectModes,
  SelectionBox,
  SetShowDNA,
  SetShowMismatches,
  SetShowEditor,
  SaveDNAFile,
  LoadDNAFile,
  MouseoverDataClear,
  MouseoverDataUpdate,
  SideViewSelectionBoxCreateToggling,
  SideViewSelectionBoxCreateSelecting,
  SideViewSelectionBoxSizeChanged,
  SideViewSelectionBoxRemove,
  MainViewSelectionBoxCreateToggling,
  MainViewSelectionBoxCreateSelecting,
  MainViewSelectionBoxSizeChanged,
  MainViewSelectionBoxRemove,
  SideViewMousePositionUpdate,
  SideViewMousePositionRemove,
  MouseoverParams,
  Helix,
  BoundSubstrand,
  GridPosition,
  Position3D,
  Point,
  UIModel,
  SelectablesStore,
  SelectionBox,
  SelectModeChoice,
  SelectModeState,
  SetShowMouseoverRect,
  MouseoverDataUpdate,
  MouseoverDataClear,
  Grid,
])
Serializers serializers = _$serializers;

Serializers standard_serializers = (serializers.toBuilder()
      ..add(PointSerializer<num>())
      ..addPlugin(new StandardJsonPlugin()))
    .build();

Serializers standard_serializers2 = (serializers.toBuilder()..addPlugin(new StandardJsonPlugin())).build();

mixin BuiltJsonSerializable {
  dynamic toJson() => standard_serializers.serialize(this);
}

//extension BuiltListSerializable<E> on BuiltList<E> {
//  dynamic toJson() => standard_serializers.serialize(this);
//}

//extension BuiltListSerializable<E> on BuiltList<E> {
//  dynamic toJson() => this.toList();
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
//    return point;
    return {'x': point.x.toString(), 'y': point.y.toString()};
  }

  @override
  Point<T> deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType: FullType.unspecified}) {
//    return serialized as Point<T>;
    Map map = serialized as Map;
    return Point<T>(num.parse(map['x']), num.parse(map['y']));
  }
}
