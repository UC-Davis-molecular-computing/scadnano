import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';

import '../state/helix.dart';
import '../state/group.dart';
import '../state/geometry.dart';

// part 'transform_by_helix_group.over_react.g.dart';

/// Components that have these three fields in their props can mixin these props and the below
/// class to get a function to compute the proper transform based on a helix group, given the Helix idx.
mixin TransformByHelixGroupPropsMixin {
  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late Geometry geometry;
}

// mixin TransformByHelixGroup<P extends TransformByHelixGroupPropsMixin> {
//   P get props;
//
//   String transform_of_helix(int helix_idx) {
//     Helix helix = props.helices[helix_idx];
//     var group = props.groups[helix.group];
//     var transform_str = group.transform_str(props.geometry);
//     return transform_str;
//   }
//
//   String transform_of_group(String group_name) {
//     var group = props.groups[group_name];
//     var transform_str = group.transform_str(props.geometry);
//     return transform_str;
//   }
//
//   Point<double> translation_of_helix(int helix_idx) {
//     Helix helix = props.helices[helix_idx];
//     var group = props.groups[helix.group];
//     Point<double> translation = group.translation(props.geometry);
//     return translation;
//   }
// }

///FIXME: This is a workaround for a strange behavior in OverReact causing runtime errors when using mixins.
/// See `DesignMainDNASequence` for an example of usage while migrating.
/// Some strange OverReact behavior means the above doesn't work anymore. I tried several ideas
/// and they all resulting in runtime errors that were not seen in pre-null-safe OverReact.
/// So instead we'll try fewer mixins, which get interpreted strangely by OverReact,
/// and instead just use the functions directly that take props as input.
/// While migrating to null-safety, I'll call the new functions transform_of_helix2, etc.,
/// and after all components are migrated, we'll drop the mixin `TransformByHelixGroup`
/// (but keep `TransformByHelixGroupPropsMixin`, which props needing these functions should implement)
/// and rename the functions below to `transform_of_helix`, etc.
/// We also need to keep this as non-null-safe until all components using it are migrated.
String transform_of_helix2<P extends TransformByHelixGroupPropsMixin>(P props, int helix_idx) {
  Helix helix = props.helices[helix_idx]!;
  var group = props.groups[helix.group]!;
  var transform_str = group.transform_str(props.geometry);
  return transform_str;
}

String transform_of_group2<P extends TransformByHelixGroupPropsMixin>(P props, String group_name) {
  var group = props.groups[group_name]!;
  var transform_str = group.transform_str(props.geometry);
  return transform_str;
}

Point<double> translation_of_helix2<P extends TransformByHelixGroupPropsMixin>(P props, int helix_idx) {
  Helix helix = props.helices[helix_idx]!;
  var group = props.groups[helix.group]!;
  Point<double> translation = group.translation(props.geometry);
  return translation;
}
