import 'dart:math';

import 'package:built_value/serializer.dart';

import 'package:built_value/built_value.dart';
import 'package:scadnano/src/serializers.dart';
import 'grid.dart';

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

  /// Distance in nanometers between two grid positions,
  /// assuming each position is a circle of diameter 2.5 nm.
  num distance_nm(GridPosition other, Grid grid) {
    return distance_lattice(other, grid) * 2.5;
  }

  /// Unitless distance between between two grid positions, assuming each position is a circle of diameter 1.
  num distance_lattice(GridPosition other, Grid grid) {
    num x_diff;
    num y_diff;
    if (grid == Grid.square) {
      x_diff = h - other.h;
      y_diff = v - other.v;
    } else if (grid == Grid.hex || grid == Grid.honeycomb) {
      num x = h + v % 2 == 1 ? 0.5 : 0;
      num x_other = other.h + other.v % 2 == 1 ? 0.5 : 0;
      num y = h * 0.5 * sqrt(3);
      num y_other = other.h * 0.5 * sqrt(3);
      x_diff = x - x_other;
      y_diff = y - y_other;
    } else {
      throw ArgumentError('grid cannot be Grid.none to evaluate distance');
    }
    return sqrt(x_diff * x_diff + y_diff * y_diff);
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory GridPosition(int h, int v, [int b = 0]) => GridPosition.from((g) => g
    ..h = h
    ..v = v
    ..b = b);

  factory GridPosition.from([void Function(GridPositionBuilder) updates]) = _$GridPosition;

  GridPosition._();

  static Serializer<GridPosition> get serializer => _$gridPositionSerializer;
}
