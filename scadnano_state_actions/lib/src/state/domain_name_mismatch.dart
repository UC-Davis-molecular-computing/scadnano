import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'domain.dart';
import '../serializers.dart';

part 'domain_name_mismatch.g.dart';

abstract class DomainNameMismatch
    with BuiltJsonSerializable
    implements Built<DomainNameMismatch, DomainNameMismatchBuilder> {
  factory DomainNameMismatch({
    required int helix_idx,
    required Domain forward_domain,
    required Domain reverse_domain,
  }) = _$DomainNameMismatch._;

  factory DomainNameMismatch.from([void Function(DomainNameMismatchBuilder) updates]) = _$DomainNameMismatch;

  DomainNameMismatch._();

  static Serializer<DomainNameMismatch> get serializer => _$domainNameMismatchSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  int get helix_idx;

  Domain get forward_domain;

  Domain get reverse_domain;
}
