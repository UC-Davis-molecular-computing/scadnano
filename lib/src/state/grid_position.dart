import 'package:built_value/serializer.dart';

import 'package:built_value/built_value.dart';
import 'package:scadnano/src/serializers.dart';

part 'grid_position.g.dart';

final _ORIGIN = GridPosition(0, 0, 0);

final _NONE = GridPosition(-1, -1, -1);

abstract class GridPosition with BuiltJsonSerializable implements Built<GridPosition, GridPositionBuilder> {
  int get h;

  int get v;

  int get b;

  static GridPosition origin() => _ORIGIN;

  static GridPosition none() => _NONE;

  static final ORIGIN = GridPosition.origin(); //Point<int>(0, 0);
  static final NONE = GridPosition.none(); //Point<int>(0, 0);

  static GridPosition from_list(List<dynamic> json_list) =>
      GridPosition(json_list[0], json_list[1], json_list.length == 3 ? json_list[2] : 0);

  List<int> to_json_serializable({bool suppress_indent = false}) {
    var list = [
      this.h,
      this.v,
    ];
    if (this.b != 0) {
      list.add(this.b);
    }
    return list;
  }

  @override
  String toString() => '(${this.h}, ${this.v}' + (this.b == 0 ? ')' : ', ${this.b})');

  /************************ begin BuiltValue boilerplate ************************/
  factory GridPosition(int h, int v, [int b = 0]) => GridPosition.from((g) => g
    ..h = h
    ..v = v
    ..b = b);

  factory GridPosition.from([void Function(GridPositionBuilder) updates]) = _$GridPosition;

  GridPosition._();

  static Serializer<GridPosition> get serializer => _$gridPositionSerializer;
}
