import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'grid.dart';
import 'position3d.dart';

part 'group.g.dart';

abstract class HelixGroup with BuiltJsonSerializable implements Built<HelixGroup, HelixGroupBuilder> {

  Grid get grid;

  BuiltList<int> get helices_view_order;

  BuiltList<int> get helix_idxs;

  Position3D get position;

  double get pitch;

  double get yaw;

  double get roll;

  static void initializeBuilder(HelixGroupBuilder b) {
    b.grid = Grid.none;
    b.position = Position3D.origin.toBuilder();
    b.pitch = 0;
    b.yaw = 0;
    b.roll = 0;
  }

  factory HelixGroup({
    Grid grid = Grid.none,
    Iterable<int> helices_view_order,
    Iterable<int> helix_idxs,
    Position3D position = null,
    double pitch = 0,
    double yaw = 0,
    double roll = 0,
  }) {
    if (position == null) {
      position = Position3D.origin;
    }
    return HelixGroup.from((b) => b
      ..grid = grid
      ..helices_view_order.replace(helices_view_order)
      ..helix_idxs.replace(helix_idxs)
      ..position.replace(position)
      ..pitch = pitch
      ..yaw = yaw
      ..roll = roll);
  }
  
  /************************ end BuiltValue boilerplate ************************/

  factory HelixGroup.from([void Function(HelixGroupBuilder) updates]) = _$HelixGroup;

  HelixGroup._();

  static Serializer<HelixGroup> get serializer => _$helixGroupSerializer;

  @memoized
  int get hashCode;
}
