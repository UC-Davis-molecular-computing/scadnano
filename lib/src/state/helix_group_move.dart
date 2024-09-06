// @dart=2.9
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/geometry.dart';

import '../serializers.dart';
import 'dna_end.dart';
import 'group.dart';
import 'helix.dart';
import 'position3d.dart';

part 'helix_group_move.g.dart';

abstract class HelixGroupMove
    with BuiltJsonSerializable
    implements Built<HelixGroupMove, HelixGroupMoveBuilder> {
  factory HelixGroupMove(
      {String group_name, HelixGroup group, BuiltMap<int, Helix> helices, Point<num> original_mouse_point}) {
    if (helices.isEmpty) {
      throw ArgumentError.value('helices should not be empty in a HelixGroupMove object');
    }
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

  /// current position in nanometers (original is group.position)
  @memoized
  Position3D get current_position {
    var mouse_translation = delta;
    var nm_translation = mouse_translation * geometry.svg_pixels_to_nm;
    var new_position = group.position.rebuild((b) => b
      ..z = group.position.z + nm_translation.x
      ..y = group.position.y + nm_translation.y);
    return new_position;
  }

  @memoized
  Point<num> get delta => current_mouse_point - original_mouse_point;

  @memoized
  bool get is_nontrivial => !(delta.x == 0 && delta.y == 0);

  @memoized
  BuiltList<int> get helix_idxs_in_group => [for (var helix in helices.values) helix.idx].build();

  @memoized
  Geometry get geometry => helices.isNotEmpty ? helices.values.first.geometry : null;
}
