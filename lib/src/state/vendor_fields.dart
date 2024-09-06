// @dart=2.9
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import '../state/unused_fields.dart';
import '../constants.dart' as constants;
import '../serializers.dart';
import '../util.dart' as util;
import 'design.dart';

import 'package:built_value/built_value.dart';

part 'vendor_fields.g.dart';

abstract class VendorFields
    with BuiltJsonSerializable, UnusedFields
    implements Built<VendorFields, VendorFieldsBuilder> {
  factory VendorFields({String scale, String purification, String plate = null, String well = null}) =>
      VendorFields.from((b) => b
        ..scale = scale
        ..purification = purification
        ..plate = plate
        ..well = well
        ..unused_fields = MapBuilder<String, Object>({}));

  factory VendorFields.from([void Function(VendorFieldsBuilder) updates]) = _$VendorFields;

  VendorFields._();

  static Serializer<VendorFields> get serializer => _$vendorFieldsSerializer;

  /************************ end BuiltValue boilerplate ************************/

  String get scale;

  String get purification;

  @nullable
  String get plate;

  @nullable
  String get well;

  @memoized
  int get hashCode;

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {
      constants.vendor_scale_key: this.scale,
      constants.vendor_purification_key: this.purification
    };
    if (this.plate != null) {
      json_map[constants.vendor_plate_key] = this.plate;
    }
    if (this.well != null) {
      json_map[constants.vendor_well_key] = this.well;
    }
    json_map.addAll(unused_fields.toMap());
    return json_map;
  }

  static VendorFields from_json(Map<String, dynamic> json_map) {
    var field_name = 'VendorFields';
    var scale = util.mandatory_field(json_map, constants.vendor_scale_key, field_name);
    var purification = util.mandatory_field(json_map, constants.vendor_purification_key, field_name);
    var plate, well;
    if (json_map.containsKey(constants.vendor_plate_key)) {
      plate = json_map[constants.vendor_plate_key];
    }
    if (json_map.containsKey(constants.vendor_well_key)) {
      well = json_map[constants.vendor_well_key];
    }
    if (plate == null && well != null) {
      throw IllegalDesignError("cannot set VendorFields.well to ${well} when plate is null\n"
          "this occurred when reading VendorFields entry:\n${json_map}");
    }
    if (plate != null && well == null) {
      throw IllegalDesignError("cannot set VendorFields.plate to ${plate} when well is null\n"
          "this occurred when reading VendorFields entry:\n${json_map}");
    }
    var unused_fields = util.unused_fields_map(json_map, constants.vendor_keys);

    return new VendorFields(scale: scale, purification: purification, plate: plate, well: well)
        .rebuild((b) => b.unused_fields = unused_fields);
  }

  tooltip() =>
      '      scale: $scale\n' +
      '      purification: $purification\n' +
      (plate == null
          ? ''
          : '      plate: $plate\n'
              '      well: $well');
}
