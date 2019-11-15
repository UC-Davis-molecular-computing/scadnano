import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

part 'grid.g.dart';

class Grid extends EnumClass {
  const Grid._(String name) : super(name);

  static const Grid square = _$square;
  static const Grid hex = _$hex;
  static const Grid honeycomb = _$honeycomb;
  static const Grid none = _$none;

  static BuiltSet<Grid> get values => _$values;
  static Grid valueOf(String name) => _$valueOf(name);

  String to_json() => name;
}

//enum Grid { square, hex, honeycomb, none }
//
//String grid_to_json(Grid grid) {
//  switch (grid) {
//    case Grid.square:
//      return 'square';
//    case Grid.hex:
//      return 'hex';
//    case Grid.honeycomb:
//      return 'honeycomb';
//    case Grid.none:
//      return 'none';
//    default:
//      throw UnimplementedError('unrecognized grid: $grid');
//  }
//}
//
//Grid grid_from_string(String string) {
//  switch (string) {
//    case 'square':
//      return Grid.square;
//    case 'hex':
//      return Grid.hex;
//    case 'honeycomb':
//      return Grid.honeycomb;
//    case 'none':
//      return Grid.none;
//    default:
//      throw new UnimplementedError('unrecognized grid: $string');
//  }
//}

