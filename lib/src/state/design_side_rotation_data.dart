
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:color/color.dart';

import '../serializers.dart';
import 'design.dart';
import 'helix.dart';
import 'domain.dart';
import 'strand.dart';
import '../constants.dart' as constants;

part 'design_side_rotation_data.g.dart';

abstract class DesignSideRotationParams
    with BuiltJsonSerializable
    implements Built<DesignSideRotationParams, DesignSideRotationParamsBuilder> {
  int get helix_idx;

  int get offset;

  @memoized
  int get hashCode;

  /************************ begin BuiltValue boilerplate ************************/
  factory DesignSideRotationParams(int helix_idx, int offset) => DesignSideRotationParams.from((b) => b
    ..helix_idx = helix_idx
    ..offset = offset);

  factory DesignSideRotationParams.from([void Function(DesignSideRotationParamsBuilder) updates]) = _$DesignSideRotationParams;

  DesignSideRotationParams._();

  static Serializer<DesignSideRotationParams> get serializer => _$designSideRotationParamsSerializer;
}

abstract class DesignSideRotationData
    with BuiltJsonSerializable
    implements Built<DesignSideRotationData, DesignSideRotationDataBuilder> {
  Helix get helix;

  int get offset;

  Color get color_forward;

  Color get color_reverse;

  double get roll_forward;

  double get minor_groove_angle;

  @memoized
  int get hashCode;

  /// Converts from raw parameters (helix, offset) to data for users to see backbone angles in side view
  static List<DesignSideRotationData> from_params(Design design, List<DesignSideRotationParams> params) {
    List<DesignSideRotationData> design_side_rotation_datas_builder = [];
    for (var param in params) {
      int helix_idx = param.helix_idx;
      int offset = param.offset;
      Color color_forward = constants.color_forward_rotation_arrow_no_strand;
      Color color_reverse = constants.color_forward_rotation_arrow_no_strand;
      Helix helix = design.helices[helix_idx];
      double roll_forward = design.helix_rotation_forward(helix.idx, offset);
      int num_domains_found = 0;
      for (Domain domain in design.domains_on_helix(helix_idx)) {
        if (domain.contains_offset(offset)) {
          num_domains_found++;
          Strand strand = design.substrand_to_strand[domain];
          if (domain.forward) {
            color_forward = domain.color ?? strand.color;
          } else {
            color_reverse = domain.color ?? strand.color;
          }
        }
        if (num_domains_found >= 2) {
          break;
        }
      }
      double minor_groove_angle = design.geometry.minor_groove_angle;
      design_side_rotation_datas_builder.add(DesignSideRotationData(helix, offset, color_forward,
          color_reverse, roll_forward, minor_groove_angle));
    }
    return design_side_rotation_datas_builder;
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory DesignSideRotationData(Helix helix, int offset, Color color_forward, Color color_reverse,
          double roll_forward, double minor_groove_angle) =>
      DesignSideRotationData.from((b) => b
        ..helix.replace(helix)
        ..offset = offset
        ..color_forward = color_forward
        ..color_reverse = color_reverse
        ..roll_forward = roll_forward
        ..minor_groove_angle = minor_groove_angle);

  factory DesignSideRotationData.from([void Function(DesignSideRotationDataBuilder) updates]) = _$DesignSideRotationData;

  DesignSideRotationData._();

  static Serializer<DesignSideRotationData> get serializer => _$designSideRotationDataSerializer;
}
