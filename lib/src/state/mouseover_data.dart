import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'dna_design.dart';
import 'helix.dart';
import 'domain.dart';
import 'substrand.dart';

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

  @nullable
  Domain get substrand;

  @memoized
  int get hashCode;

  /// Converts from raw mouseover data (helix, offset, forward) to data user wants to see in the footer (substrand)
  static List<MouseoverData> from_params(DNADesign dna_design, Iterable<MouseoverParams> params) {
    Domain substrand = null;
    var mouseover_datas_builder = List<MouseoverData>();
    for (var param in params) {
      int helix_idx = param.helix_idx;
      int offset = param.offset;
      bool forward = param.forward;
      for (Substrand ss in dna_design.substrands_on_helix(helix_idx)) {
        if (ss.is_domain()) {
          var bound_ss = ss as Domain;
          if (bound_ss.contains_offset(offset) && bound_ss.forward == forward) {
            substrand = bound_ss;
            break;
          }
        }
      }
      Helix helix = dna_design.helices[helix_idx];
      mouseover_datas_builder.add(MouseoverData(helix, offset, substrand));
    }
    return mouseover_datas_builder;
  }

  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverData(Helix helix, int offset, Domain substrand) => MouseoverData.from((b) => b
    ..helix.replace(helix)
//    ..substrand.replace(substrand)
    ..substrand = substrand?.toBuilder()
    ..offset = offset);

  factory MouseoverData.from([void Function(MouseoverDataBuilder) updates]) = _$MouseoverData;

  MouseoverData._();

  static Serializer<MouseoverData> get serializer => _$mouseoverDataSerializer;
}
