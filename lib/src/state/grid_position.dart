import 'dart:math';

import 'package:built_value/serializer.dart';

import 'package:built_value/built_value.dart';
import '../serializers.dart';
import 'grid.dart';
import '../util.dart' as util;

part 'grid_position.g.dart';

final _ORIGIN = GridPosition(0, 0);

final _NONE = GridPosition(-1, -1);

abstract class GridPosition with BuiltJsonSerializable implements Built<GridPosition, GridPositionBuilder> {
  int get h;

  int get v;

  static GridPosition origin() => _ORIGIN;

  static GridPosition none() => _NONE;

  static final ORIGIN = GridPosition.origin(); //Point<int>(0, 0);
  static final NONE = GridPosition.none(); //Point<int>(0, 0);

  static GridPosition from_list(List<dynamic> json_list) => GridPosition(json_list[0], json_list[1]);

  List<int> to_json_serializable({bool suppress_indent = false}) => [this.h, this.v];

  @override
  String toString() => '(${this.h},${this.v})';

  @memoized
  int get hashCode;

  /// Distance in nanometers between two grid positions,
  /// assuming each position is a circle of diameter 2.5 nm.
  double distance_nm(GridPosition other, Grid grid) {
    return distance_lattice(other, grid) * 2.5;
  }

  /// Unitless distance between between two grid positions, assuming each position is a circle of diameter 1.
  double distance_lattice(GridPosition other, Grid grid) {
    double x_diff;
    double y_diff;
    if (grid == Grid.square) {
      x_diff = h - other.h as double;
      y_diff = v - other.v as double;
    } else if (grid == Grid.hex || grid == Grid.honeycomb) {
      var pos;
      var other_pos;
      if (grid == Grid.hex) {
        pos = util.hex_grid_position_to_position2d_diameter_1_circles(this);
        other_pos = util.hex_grid_position_to_position2d_diameter_1_circles(other);
      } else if (grid == Grid.honeycomb) {
        pos = util.honeycomb_grid_position_to_position2d_diameter_1_circles(this);
        other_pos = util.honeycomb_grid_position_to_position2d_diameter_1_circles(other);
      }
      x_diff = other_pos.x - pos.x;
      y_diff = other_pos.y - pos.y;
    } else {
      throw ArgumentError('grid cannot be Grid.none to evaluate distance');
    }
    return sqrt(x_diff * x_diff + y_diff * y_diff);
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory GridPosition(int h, int v) => GridPosition.from((g) => g
    ..h = h
    ..v = v);

  factory GridPosition.from([void Function(GridPositionBuilder) updates]) = _$GridPosition;

  GridPosition._();

  static Serializer<GridPosition> get serializer => _$gridPositionSerializer;
}
