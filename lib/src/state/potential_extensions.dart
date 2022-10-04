import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:react/react.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/potential_extension.dart';

import '../serializers.dart';

part 'potential_extensions.g.dart';

abstract class PotentialExtensions
    with BuiltJsonSerializable
    implements Built<PotentialExtensions, PotentialExtensionsBuilder> {
  factory PotentialExtensions.from([void Function(PotentialExtensionsBuilder) updates]) = _$PotentialExtensions;

  PotentialExtensions._();

  static Serializer<PotentialExtensions> get serializer => _$potentialExtensionsSerializer;

  factory PotentialExtensions({
    BuiltList<PotentialExtension> potential_extensions,
  }) {
    return PotentialExtensions.from((b) => b
      ..potential_extensions.replace(potential_extensions)
    );
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<PotentialExtension> get potential_extensions;
}
