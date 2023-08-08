import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

part 'dna_file_type.g.dart';

class DNAFileType extends EnumClass {
  const DNAFileType._(String name) : super(name);

  @memoized
  int get hashCode;

  static Serializer<DNAFileType> get serializer => _$dNAFileTypeSerializer;

  /******************** end BuiltValue boilerplate *********************/

  static const DNAFileType scadnano_file = _$scadnano_file;
  static const DNAFileType cadnano_file = _$cadnano_file;

  static BuiltSet<DNAFileType> get values => _$values;
  static DNAFileType valueOf(String name) => _$valueOf(name);
}
