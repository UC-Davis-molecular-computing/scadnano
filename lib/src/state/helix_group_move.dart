import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'dna_end.dart';
import 'group.dart';
import 'helix.dart';

part 'helix_group_move.g.dart';

abstract class HelixGroupMove
    with BuiltJsonSerializable
    implements Built<HelixGroupMove, HelixGroupMoveBuilder> {
  factory HelixGroupMove(
      {String group_name, HelixGroup group, BuiltMap<int, Helix> helices, Point<num> original_mouse_point}) {
    return HelixGroupMove.from((b) => b
      ..group_name = group_name
      ..group.replace(group)
      ..helices.replace(helices)
      ..original_mouse_point = original_mouse_point
      ..current_mouse_point = original_mouse_point);
  }

  factory HelixGroupMove.from([void Function(HelixGroupMoveBuilder) updates]) = _$HelixGroupMove;

  HelixGroupMove._();

  static Serializer<HelixGroupMove> get serializer => _$helixGroupMoveSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get group_name;

  HelixGroup get group;

  BuiltMap<int, Helix> get helices;

  /// starting offset (in units of bases) where mouse was when we started moving
  Point<num> get original_mouse_point;

  /// current offset where mouse is
  Point<num> get current_mouse_point;

  @memoized
  Point<num> get delta => current_mouse_point - original_mouse_point;
}
