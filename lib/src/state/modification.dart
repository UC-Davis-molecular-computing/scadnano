import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/helix.dart';
import '../state/design.dart';

import '../json_serializable.dart';
import '../serializers.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'unused_fields.dart';

part 'modification.g.dart';

abstract class Modification {
  String get display_text;

  String get id;

  String get idt_text;

  BuiltMap<String, Object> get unused_fields;

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false});

  Modification set_id(String id);

  static Map<String, dynamic> mod_to_json_serializable(Modification mod, bool suppress_indent) {
    Map<String, dynamic> map = {
      constants.mod_display_text_key: mod.display_text,
      if (mod.idt_text != null) constants.mod_idt_text_key: mod.idt_text,
    };
    map.addAll(mod.unused_fields.toMap());
    return map;
  }

  static Modification from_json(Map<String, dynamic> json_map) {
    String location = json_map[constants.mod_location_key];
    Modification mod;
    var unused_fields = util.unused_fields_map(json_map, constants.modification_keys);
    if (location == "5'") {
      mod = Modification5Prime.from_json(json_map).rebuild((b) => b.unused_fields = unused_fields);
    } else if (location == "3'") {
      mod = Modification3Prime.from_json(json_map).rebuild((b) => b.unused_fields = unused_fields);
    } else if (location == "internal") {
      mod = ModificationInternal.from_json(json_map).rebuild((b) => b.unused_fields = unused_fields);
    } else {
      throw IllegalDesignError('unknown Modification location "${location}"');
    }

    return mod;
  }

  @memoized
  int get hashCode;

  String html_id(Address address);
}

String mod_html_id(Modification modification, Address address) =>
    "modification-${modification.id.replaceAll('/', '')}-${address}";

abstract class Modification5Prime
    with BuiltJsonSerializable, UnusedFields
    implements Built<Modification5Prime, Modification5PrimeBuilder>, Modification {
  factory Modification5Prime(
      {String display_text, String id, String idt_text, BuiltMap<String, Object> unused_fields}) {
    String id_to_assign = id ?? ("5'-" + idt_text);
    var unused_fields_to_assign = unused_fields ?? BuiltMap<String, Object>();
    return Modification5Prime.from((b) => b
      ..display_text = display_text
      ..idt_text = idt_text
      ..id = id_to_assign
      ..unused_fields.replace(unused_fields_to_assign));
  }

  factory Modification5Prime.from([void Function(Modification5PrimeBuilder) updates]) = _$Modification5Prime;

  Modification5Prime._();

  static Serializer<Modification5Prime> get serializer => _$modification5PrimeSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get display_text;

  // need to delay assigning id until modification is read, since Modification.from_json doesn't know
  // the key in the map that maps the id to this modification. Call set_id after creating to set this.
  @nullable
  String get id;

  String get idt_text;

  String html_id(Address address) => mod_html_id(this, address);

  Modification set_id(String id) => rebuild((b) => b..id = id);

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var ret = Modification.mod_to_json_serializable(this, suppress_indent);
    ret[constants.mod_location_key] = "5'";
    return ret;
  }

  static Modification5Prime from_json(Map<String, dynamic> json_map) {
    String display_text = json_map[constants.mod_display_text_key];
    String id = json_map[constants.mod_id_key];
    String location = json_map[constants.mod_location_key];
    assert(location == "5'");
    String idt_text = json_map[constants.mod_idt_text_key];
    var unused_fields = util.unused_fields_map(json_map, constants.modification_keys).build();

    return Modification5Prime(
        display_text: display_text, id: id, idt_text: idt_text, unused_fields: unused_fields);
  }
}

abstract class Modification3Prime
    with BuiltJsonSerializable, UnusedFields
    implements Built<Modification3Prime, Modification3PrimeBuilder>, Modification {
  factory Modification3Prime(
      {String display_text, String id, String idt_text, BuiltMap<String, Object> unused_fields}) {
    String id_to_assign = id ?? ("3'-" + idt_text);
    var unused_fields_to_assign = unused_fields ?? BuiltMap<String, Object>();
    return Modification3Prime.from((b) => b
      ..display_text = display_text
      ..idt_text = idt_text
      ..id = id_to_assign
      ..unused_fields.replace(unused_fields_to_assign));
  }

  factory Modification3Prime.from([void Function(Modification3PrimeBuilder) updates]) = _$Modification3Prime;

  Modification3Prime._();

  static Serializer<Modification3Prime> get serializer => _$modification3PrimeSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get display_text;

  // need to delay assigning id until modification is read, since Modification.from_json doesn't know
  // the key in the map that maps the id to this modification. Call set_id after creating to set this.
  @nullable
  String get id;

  String get idt_text;

  String html_id(Address address) => mod_html_id(this, address);

  Modification set_id(String id) => rebuild((b) => b..id = id);

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var ret = Modification.mod_to_json_serializable(this, suppress_indent);
    ret[constants.mod_location_key] = "3'";
    return ret;
  }

  static Modification3Prime from_json(Map<String, dynamic> json_map) {
    String display_text = json_map[constants.mod_display_text_key];
    String id = json_map[constants.mod_id_key];
    String location = json_map[constants.mod_location_key];
    assert(location == "3'");
    String idt_text = json_map[constants.mod_idt_text_key];
    var unused_fields = util.unused_fields_map(json_map, constants.modification_keys).build();

    return Modification3Prime(
        display_text: display_text, id: id, idt_text: idt_text, unused_fields: unused_fields);
  }
}

abstract class ModificationInternal
    with BuiltJsonSerializable, UnusedFields
    implements Built<ModificationInternal, ModificationInternalBuilder>, Modification {
  factory ModificationInternal(
      {String display_text,
      String id,
      String idt_text,
      BuiltSet<String> allowed_bases,
      BuiltMap<String, Object> unused_fields}) {
    String id_to_assign = id ?? ("internal-" + idt_text);
    var unused_fields_to_assign = unused_fields ?? BuiltMap<String, Object>();
    var allowed_bases_to_assign = allowed_bases ?? BuiltSet<String>(['A', 'C', 'G', 'T']);
    return ModificationInternal.from((b) => b
      ..display_text = display_text
      ..idt_text = idt_text
      ..id = id_to_assign
      ..allowed_bases.replace(allowed_bases_to_assign)
      ..unused_fields.replace(unused_fields_to_assign));
  }

  factory ModificationInternal.from([void Function(ModificationInternalBuilder) updates]) =
      _$ModificationInternal;

  ModificationInternal._();

  static Serializer<ModificationInternal> get serializer => _$modificationInternalSerializer;

  // factory ModificationInternal(
  //     {String display_text,
  //     String id,
  //     String idt_text,
  //     BuiltSet<String> allowed_bases,
  //     BuiltMap<String, Object> unused_fields}) = _$ModificationInternal._;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get display_text;

  // need to delay assigning id until modification is read, since Modification.from_json doesn't know
  // the key in the map that maps the id to this modification. Call set_id after creating to set this.
  @nullable
  String get id;

  String get idt_text;

  @nullable
  BuiltSet<String> get allowed_bases;

  String html_id(Address address) => mod_html_id(this, address);

  Modification set_id(String id) => rebuild((b) => b..id = id);

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var ret = Modification.mod_to_json_serializable(this, suppress_indent);
    ret[constants.mod_location_key] = "internal";
    if (allowed_bases != null) {
      ret[constants.mod_allowed_bases_key] =
          suppress_indent ? NoIndent(allowed_bases.toList()) : allowed_bases.toList();
    }
    return ret;
  }

  static ModificationInternal from_json(Map<String, dynamic> json_map) {
    String display_text = json_map[constants.mod_display_text_key];
    String id = json_map[constants.mod_id_key];
    String location = json_map[constants.mod_location_key];
    assert(location == "internal");
    String idt_text = json_map[constants.mod_idt_text_key];
    var allowed_bases_json = json_map[constants.mod_allowed_bases_key];
    var allowed_bases = allowed_bases_json == null ? null : BuiltSet<String>(allowed_bases_json);
    var unused_fields = util.unused_fields_map(json_map, constants.modification_keys).build();

    return ModificationInternal(
        display_text: display_text,
        id: id,
        idt_text: idt_text,
        allowed_bases: allowed_bases,
        unused_fields: unused_fields);
  }

  bool base_is_allowed(String base) => this.allowed_bases == null || this.allowed_bases.contains(base);
}
