// @dart=2.9
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';

import '../state/helix.dart';
import '../state/group.dart';
import '../state/geometry.dart';

part 'transform_by_helix_group.over_react.g.dart';

/// Components that have these three fields in their props can mixin these props and the below
/// class to get a function to compute the proper transform based on a helix group, given the Helix idx.
mixin TransformByHelixGroupPropsMixin on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;
}

abstract class TransformByHelixGroup<P extends TransformByHelixGroupPropsMixin> {
  P get props;

  String transform_of_helix(int helix_idx) {
    Helix helix = props.helices[helix_idx];
    var group = props.groups[helix.group];
    var transform_str = group.transform_str(props.geometry);
    return transform_str;
  }

  String transform_of_group(String group_name) {
    var group = props.groups[group_name];
    var transform_str = group.transform_str(props.geometry);
    return transform_str;
  }

  Point<double> translation_of_helix(int helix_idx) {
    Helix helix = props.helices[helix_idx];
    var group = props.groups[helix.group];
    Point<double> translation = group.translation(props.geometry);
    return translation;
  }
}
