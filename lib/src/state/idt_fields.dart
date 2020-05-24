import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import '../constants.dart' as constants;
import '../serializers.dart';
import '../util.dart' as util;
import 'dna_design.dart';

import 'package:built_value/built_value.dart';

part 'idt_fields.g.dart';

abstract class IDTFields with BuiltJsonSerializable implements Built<IDTFields, IDTFieldsBuilder> {
  factory IDTFields(String name, String scale, String purification,
          {String plate = null, String well = null}) =>
      IDTFields.from((b) => b
        ..name = name
        ..scale = scale
        ..purification = purification
        ..plate = plate
        ..well = well
        ..unused_fields = MapBuilder<String, Object>({}));

  factory IDTFields.from([void Function(IDTFieldsBuilder) updates]) = _$IDTFields;

  IDTFields._();

  static Serializer<IDTFields> get serializer => _$iDTFieldsSerializer;

  /************************ end BuiltValue boilerplate ************************/

  String get name;

  String get scale;

  String get purification;

  @nullable
  String get plate;

  @nullable
  String get well;

  @memoized
  int get hashCode;

  BuiltMap<String, Object> get unused_fields;

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {
      constants.idt_name_key: this.name,
      constants.idt_scale_key: this.scale,
      constants.idt_purification_key: this.purification
    };
    if (this.plate != null) {
      json_map[constants.idt_plate_key] = this.plate;
    }
    if (this.well != null) {
      json_map[constants.idt_well_key] = this.well;
    }
    json_map.addAll(unused_fields.toMap());
    return json_map;
  }

  static IDTFields from_json(Map<String, dynamic> json_map) {
    var field_name = 'IDTFields';
    var name = util.get_value(json_map, constants.idt_name_key, field_name);
    var scale = util.get_value(json_map, constants.idt_scale_key, field_name);
    var purification = util.get_value(json_map, constants.idt_purification_key, field_name);
    var plate, well;
    if (json_map.containsKey(constants.idt_plate_key)) {
      plate = json_map[constants.idt_plate_key];
    }
    if (json_map.containsKey(constants.idt_well_key)) {
      well = json_map[constants.idt_well_key];
    }
    if (plate == null && well != null) {
      throw IllegalDNADesignError("cannot set IDTFields.well to ${well} when plate is null\n"
          "this occurred when reading IDTFields entry:\n${json_map}");
    }
    if (plate != null && well == null) {
      throw IllegalDNADesignError("cannot set IDTFields.plate to ${plate} when well is null\n"
          "this occurred when reading IDTFields entry:\n${json_map}");
    }
    var unused_fields = util.unused_fields_map(json_map, constants.idt_keys);

    return new IDTFields(name, scale, purification, plate: plate, well: well)
        .rebuild((b) => b.unused_fields = unused_fields);
  }

  tooltip() =>
      '      name: $name\n' +
      '      scale: $scale\n' +
      '      purification: $purification\n' +
      (plate == null
          ? ''
          : '      plate: $plate\n'
              '      well: $well');
}
