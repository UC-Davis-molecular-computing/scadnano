import 'package:quiver/core.dart' as quiver;

import 'package:built_value/built_value.dart';

part 'grid_position.g.dart';

/// TODO: document GridPosition class
abstract class GridPosition implements Built<GridPosition, GridPositionBuilder> {
  GridPosition._();

//  factory GridPosition([void Function(GridPositionBuilder) updates]) = _$GridPosition;
  // sets default for b; see https://medium.com/dartlang/moving-fast-with-dart-immutable-values-1e717925fafb
  factory GridPosition([void Function(GridPositionBuilder) updates]) => _$GridPosition((gp) => gp
    ..b = 0
    ..update(updates));

  int get h;

  int get v;

  int get b;

//  const GridPosition(this.h, this.v, [this.b]);

  static GridPosition origin() => GridPosition((gp) => gp
    ..h = 0
    ..v = 0
    ..b = 0);

  static GridPosition none() => GridPosition((gp) => gp
    ..h = -1
    ..v = -1
    ..b = -1);

  static final ORIGIN = GridPosition.origin(); //Point<int>(0, 0);
  static final NONE = GridPosition.origin(); //Point<int>(0, 0);

  static GridPosition from_list(List<dynamic> json_list) => GridPosition((gp) => gp
    ..h = json_list[0]
    ..v = json_list[1]
    ..b = json_list.length == 3 ? json_list[2] : 0);

  List<int> toJson() {
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
}
