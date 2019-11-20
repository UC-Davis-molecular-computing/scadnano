import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:tuple/tuple.dart';

import '../serializers.dart';
import 'dna_design.dart';
import 'helix.dart';
import 'bound_substrand.dart';
import 'substrand.dart';

part 'mouseover_data.g.dart';

abstract class MouseoverParams with BuiltJsonSerializable implements Built<MouseoverParams, MouseoverParamsBuilder> {
  int get helix;

  int get offset;

  bool get forward;

  /************************ begin BuiltValue boilerplate ************************/
  factory MouseoverParams(int helix, int offset, bool forward) => MouseoverParams.from((b) => b
    ..helix = helix
    ..offset = offset
    ..forward = forward);

  factory MouseoverParams.from([void Function(MouseoverParamsBuilder) updates]) = _$MouseoverParams;

  MouseoverParams._();

  static Serializer<MouseoverParams> get serializer => _$mouseoverParamsSerializer;
}

abstract class MouseoverData with BuiltJsonSerializable implements Built<MouseoverData, MouseoverDataBuilder> {
  Helix get helix;

  int get offset;

  @nullable
  BoundSubstrand get substrand;

  /// Converts from raw mouseover data (helix, offset, forward) to data user wants to see in the footer (substrand)
  static ListBuilder<MouseoverData> from_params(DNADesign dna_design, Iterable<MouseoverParams> params) {
    BoundSubstrand substrand = null;
    var mouseover_datas_builder = ListBuilder<MouseoverData>();
    for (var param in params) {
      int helix_idx = param.helix;
      int offset = param.offset;
      bool forward = param.forward;
      for (Substrand ss in dna_design.substrands_on_helix(helix_idx)) {
        if (ss.is_bound_substrand()) {
          var bound_ss = ss as BoundSubstrand;
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
  factory MouseoverData(Helix helix, int offset, BoundSubstrand substrand) => MouseoverData.from((b) => b
    ..helix.replace(helix)
    ..offset = offset
    ..substrand.replace(substrand));

  factory MouseoverData.from([void Function(MouseoverDataBuilder) updates]) = _$MouseoverData;

  MouseoverData._();

  static Serializer<MouseoverData> get serializer => _$mouseoverDataSerializer;
}
