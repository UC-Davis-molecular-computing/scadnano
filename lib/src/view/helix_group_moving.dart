// @dart=2.9
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/helix_group_move.dart';
import 'package:scadnano/src/state/position3d.dart';

import '../app.dart';
import '../state/group.dart';
import '../state/geometry.dart';
import 'design_main_helix.dart';
import '../state/helix.dart';
import 'pure_component.dart';
import '../extension_methods.dart';

part 'helix_group_moving.over_react.g.dart';

UiFactory<HelixGroupMovingProps> ConnectedHelixGroupMoving = connect<HelixGroupMove, HelixGroupMovingProps>(
  mapStateToPropsWithOwnProps: (HelixGroupMove helix_group_move, HelixGroupMovingProps props) {
    return HelixGroupMoving()..helix_group_move = helix_group_move;
  },
  context: app.context_helix_group_move,
)(HelixGroupMoving);

UiFactory<HelixGroupMovingProps> HelixGroupMoving = _$HelixGroupMoving;

mixin HelixGroupMovingProps on UiProps {
  HelixGroupMove helix_group_move;
  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;
  bool show_helix_circles;
  BuiltMap<int, Point<num>> helix_idx_to_svg_position_map;
}

class HelixGroupMovingComponent extends UiComponent2<HelixGroupMovingProps> with PureComponent {
  @override
  render() {
    if (props.helix_group_move == null || props.helix_group_move.helices.isEmpty) {
      return null;
    }
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool only_display_selected_helices = props.only_display_selected_helices;

    if (props.helix_group_move.helix_idxs_in_group.isEmpty) {
      return null;
    }

    var children = [];
    for (int helix_idx in props.helix_group_move.helix_idxs_in_group) {
      var helix = props.helix_group_move.helices[helix_idx];

      if (only_display_selected_helices && side_selected_helix_idxs.contains(helix.idx) ||
          !only_display_selected_helices) {
        children.add((DesignMainHelix()
          ..helix = helix
          ..selected = side_selected_helix_idxs.contains(helix.idx)
          ..show_dna = false
          ..show_helix_circles = props.show_helix_circles
          ..helix_change_apply_to_all = false
          ..display_base_offsets_of_major_ticks = false
          ..display_major_tick_widths = false
          ..helix_svg_position = props.helix_idx_to_svg_position_map[helix.idx]
          ..key = helix.idx.toString())());
      }
    }

    var new_position = props.helix_group_move.current_position;
    var new_group = props.helix_group_move.group.rebuild((b) => b..position.replace(new_position));
    var transform = new_group.transform_str(props.helix_group_move.geometry);

    return (Dom.g()
      ..className = 'helix-group-moving-${props.helix_group_move.group_name}'
      ..transform = transform
      ..key = '${props.helix_group_move.group_name}')(children);
  }
}
