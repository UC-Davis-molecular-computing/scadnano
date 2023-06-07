import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:color/color.dart';

import '../serializers.dart';
import 'address.dart';
import 'design.dart';
import 'helix.dart';
import 'domain.dart';
import 'strand.dart';
import 'substrand.dart';
import '../constants.dart' as constants;

part 'mouseover_data.g.dart';

abstract class MouseoverParams
    with BuiltJsonSerializable
    implements Built<MouseoverParams, MouseoverParamsBuilder> {
  int get helix_idx;

  int get offset;

  bool get forward;

  @memoized
  int get hashCode;

  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverParams(int helix_idx, int offset, bool forward) => MouseoverParams.from((b) => b
    ..helix_idx = helix_idx
    ..offset = offset
    ..forward = forward);

  factory MouseoverParams.from([void Function(MouseoverParamsBuilder) updates]) = _$MouseoverParams;

  MouseoverParams._();

  static Serializer<MouseoverParams> get serializer => _$mouseoverParamsSerializer;
}

abstract class MouseoverData
    with BuiltJsonSerializable
    implements Built<MouseoverData, MouseoverDataBuilder> {
  Helix get helix;

  int get offset;

  Color get color_forward;

  Color get color_reverse;

  double get roll_forward;

  double get minor_groove_angle;

  int get strand_idx;

  @nullable
  Domain get domain;

  @memoized
  int get hashCode;

  /// Converts from raw mouseover data (helix, offset, forward) to data user wants to see in the footer (substrand)
  static List<MouseoverData> from_params(Design design, Iterable<MouseoverParams> params) {
    Domain domain_in_direction = null;
    List<MouseoverData> mouseover_datas_builder = [];
    for (var param in params) {
      int helix_idx = param.helix_idx;
      int offset = param.offset;
      bool forward = param.forward;
      Color color_forward = constants.color_forward_rotation_arrow_no_strand;
      Color color_reverse = constants.color_forward_rotation_arrow_no_strand;
      Helix helix = design.helices[helix_idx];
      double roll_forward = design.helix_rotation_forward(helix.idx, offset);
      int num_domains_found = 0;
      int strand_idx = -1;
      for (Domain domain in design.domains_on_helix(helix_idx)) {
        if (domain.contains_offset(offset)) {
          if (domain.forward == forward) {
            domain_in_direction = domain;
            strand_idx =
                design.idx_on_strand(Address(helix_idx: helix_idx, offset: offset, forward: forward));
          }
          num_domains_found++;
          Strand strand = design.substrand_to_strand[domain];
          if (domain.forward) {
            color_forward = strand.color;
          } else {
            color_reverse = strand.color;
          }
        }
        if (num_domains_found >= 2) {
          break;
        }
      }
      double minor_groove_angle = design.geometry.minor_groove_angle;
      mouseover_datas_builder.add(MouseoverData(helix, offset, strand_idx, domain_in_direction, color_forward,
          color_reverse, roll_forward, minor_groove_angle));
    }
    return mouseover_datas_builder;
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverData(Helix helix, int offset, int strand_idx, Domain domain, Color color_forward,
          Color color_reverse, double roll_forward, double minor_groove_angle) =>
      MouseoverData.from((b) => b
        ..helix.replace(helix)
        ..domain = domain?.toBuilder()
        ..offset = offset
        ..strand_idx = strand_idx
        ..color_forward = color_forward
        ..color_reverse = color_reverse
        ..roll_forward = roll_forward
        ..minor_groove_angle = minor_groove_angle);

  factory MouseoverData.from([void Function(MouseoverDataBuilder) updates]) = _$MouseoverData;

  MouseoverData._();

  static Serializer<MouseoverData> get serializer => _$mouseoverDataSerializer;
}
