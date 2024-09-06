// @dart=2.9
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
import '../state/helix.dart';

import '../serializers.dart';

part 'strand_creation.g.dart';

abstract class StrandCreation
    with BuiltJsonSerializable
    implements Built<StrandCreation, StrandCreationBuilder> {
  factory StrandCreation({Helix helix, bool forward, int original_offset, Color color}) =>
      StrandCreation.from((b) => b
        ..helix.replace(helix)
        ..forward = forward
        ..original_offset = original_offset
        ..current_offset = original_offset
        ..color = color);

  factory StrandCreation.from([void Function(StrandCreationBuilder) updates]) = _$StrandCreation;

  StrandCreation._();

  static Serializer<StrandCreation> get serializer => _$strandCreationSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  Helix get helix;

  bool get forward;

  int get original_offset;

  int get current_offset;

  Color get color;

  int get start => original_offset < current_offset ? original_offset : current_offset;

  int get end => 1 + (original_offset < current_offset ? current_offset : original_offset);
}
