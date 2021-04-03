import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'strand.dart';
import 'group.dart';
import 'helix.dart';

part 'strands_copy_info.g.dart';

// Represents information recorded in AppState when Ctrl+C is pressed and strands are selected
abstract class StrandsCopyInfo
    with BuiltJsonSerializable
    implements Built<StrandsCopyInfo, StrandsCopyInfoBuilder> {
  factory StrandsCopyInfo.from([void Function(StrandsCopyInfoBuilder) updates]) = _$StrandsCopyInfo;

  StrandsCopyInfo._();

  static Serializer<StrandsCopyInfo> get serializer => _$strandsCopyInfoSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  // strands to copy (calculated as selected strands)
  BuiltList<Strand> get strands;

  // address of topmost helix, leftmost offset on that helix, of selected strands
  Address get start_address;

  // default translation (expressed using Address as "vector") for auto-paste
  // null if no translation is valid
  @nullable
  Address get default_translation;

  factory StrandsCopyInfo({BuiltList<Strand> strands, Address start_address, Address default_translation}) =
      _$StrandsCopyInfo._;
}
