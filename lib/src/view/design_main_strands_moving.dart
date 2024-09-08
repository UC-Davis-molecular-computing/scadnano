// @dart=2.9
import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';

import '../state/group.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import '../state/strands_move.dart';
import '../state/app_state.dart';
import '../util.dart' as util;
import 'design_main_strand_moving.dart';

part 'design_main_strands_moving.over_react.g.dart';

UiFactory<DesignMainStrandsMovingProps> ConnectedDesignMainStrandsMoving =
    connect<AppState, DesignMainStrandsMovingProps>(mapStateToProps: (state) {
  HelixGroup current_group;
  BuiltMap<int, int> original_helices_view_order_inverse;
  bool selected_strands_on_multiple_groups = false;
  if (state.ui_state.strands_move != null) {
    original_helices_view_order_inverse = state.ui_state.strands_move.original_helices_view_order_inverse;
    current_group = util.current_group_from_strands_move(state.design, state.ui_state.strands_move);
    // Need to check this here, because we need to allow the middleware to let through the strands_move
    // object so that view/design.dart can issue a warning to the user on a mousemove event when the
    // left-click is depressed. But if we allow the strands_move to propagate to the view it throws
    // an exception since it assumes they are in the same group.
    if (!state.ui_state.strands_move.copy) {
      var group_names = state.design.group_names_of_strands(state.ui_state.strands_move.strands_moving);
      selected_strands_on_multiple_groups = group_names != null && group_names.length > 1;
    }
  }
  return DesignMainStrandsMoving()
    ..strands_move = selected_strands_on_multiple_groups ? null : state.ui_state.strands_move
    ..groups = state.design.groups
    ..original_helices_view_order_inverse = original_helices_view_order_inverse
    ..current_group = current_group
    ..helices = state.design.helices
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
    ..geometry = state.design.geometry;
})(DesignMainStrandsMoving);

UiFactory<DesignMainStrandsMovingProps> DesignMainStrandsMoving = _$DesignMainStrandsMoving;

mixin DesignMainStrandsMovingProps on UiProps {
  StrandsMove strands_move;
  BuiltMap<int, int> original_helices_view_order_inverse;
  HelixGroup current_group;
  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  BuiltSet<int> side_selected_helix_idxs;
  Geometry geometry;
  BuiltMap<int, Point<double>> helix_idx_to_svg_position_map;
}

class DesignMainStrandsMovingComponent extends UiComponent2<DesignMainStrandsMovingProps> {
  @override
  render() {
    if (props.strands_move == null || props.current_group == null) {
      return null;
    }
    return (Dom.g()
      ..className = 'strands-moving-main-view' + (props.strands_move.allowable ? '' : ' disallowed'))([
      for (var strand in props.strands_move.strands_moving)
        (DesignMainStrandMoving()
          ..strand = strand
          ..delta_view_order = props.strands_move.delta_view_order
          ..original_helices_view_order_inverse = props.original_helices_view_order_inverse
          ..current_group = props.current_group
          ..delta_offset = props.strands_move.delta_offset
          ..delta_forward = props.strands_move.delta_forward
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..helices = props.helices
          ..groups = props.groups
          ..allowable = props.strands_move.allowable
          ..geometry = props.geometry
          ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
          ..key = strand.toString())()
    ]);
  }
}
