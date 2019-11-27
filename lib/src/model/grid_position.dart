import 'package:built_value/serializer.dart';

import 'package:built_value/built_value.dart';
import 'package:scadnano/src/serializers.dart';

part 'grid_position.g.dart';

final _ORIGIN = GridPosition((gp) => gp
  ..h = 0
  ..v = 0
  ..b = 0);

final _NONE = GridPosition((gp) => gp
  ..h = -1
  ..v = -1
  ..b = -1);

/// TODO: document GridPosition class
abstract class GridPosition with BuiltJsonSerializable implements Built<GridPosition, GridPositionBuilder> {
//  factory GridPosition([void Function(GridPositionBuilder) updates]) = _$GridPosition;
  // sets default for b; see https://medium.com/dartlang/moving-fast-with-dart-immutable-values-1e717925fafb
  factory GridPosition([void Function(GridPositionBuilder) updates]) => _$GridPosition((gp) => gp
    ..b = 0
    ..update(updates));

  int get h;

  int get v;

  int get b;

  static GridPosition origin() => _ORIGIN;

  static GridPosition none() => _NONE;

  static final ORIGIN = GridPosition.origin(); //Point<int>(0, 0);
  static final NONE = GridPosition.origin(); //Point<int>(0, 0);

  static GridPosition from_list(List<dynamic> json_list) => GridPosition((gp) => gp
    ..h = json_list[0]
    ..v = json_list[1]
    ..b = json_list.length == 3 ? json_list[2] : 0);

//  List<int> toJson() {
//    var list = [
//      this.h,
//      this.v,
//    ];
//    if (this.b != 0) {
//      list.add(this.b);
//    }
//    return list;
//  }

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
//  factory GridPosition(int prag) => GridPosition.from((b) => b..prag = prag);

//  factory GridPosition.from([void Function(GridPositionBuilder) updates]) = _$GridPosition;

  GridPosition._();

  static Serializer<GridPosition> get serializer => _$gridPositionSerializer;
}
