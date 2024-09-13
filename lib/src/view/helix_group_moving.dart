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

HelixGroupMovingProps set_helix_group_moving_props(
    HelixGroupMovingProps elt, HelixGroupMove? helix_group_move) {
  return elt..helix_group_move = helix_group_move;
}

UiFactory<HelixGroupMovingProps> ConnectedHelixGroupMoving = connect<HelixGroupMove?, HelixGroupMovingProps>(
  mapStateToProps: (HelixGroupMove? helix_group_move) =>
      set_helix_group_moving_props(HelixGroupMoving(), helix_group_move),
  context: app.context_helix_group_move,
)(HelixGroupMoving);

UiFactory<HelixGroupMovingProps> HelixGroupMoving = _$HelixGroupMoving;

mixin HelixGroupMovingProps on UiProps {
  HelixGroupMove? helix_group_move;
  late BuiltSet<int> side_selected_helix_idxs;
  late bool only_display_selected_helices;
  late bool show_helix_circles;
  late BuiltMap<int, Point<double>> helix_idx_to_svg_position_map;
  late double major_tick_offset_font_size;
  late double major_tick_width_font_size;
  late bool show_domain_labels;
}

class HelixGroupMovingComponent extends UiComponent2<HelixGroupMovingProps> with PureComponent {
  @override
  render() {
    HelixGroupMove? helix_group_move = props.helix_group_move;
    if (helix_group_move == null || helix_group_move.helices.isEmpty) {
      return null;
    }
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool only_display_selected_helices = props.only_display_selected_helices;

    if (helix_group_move.helix_idxs_in_group.isEmpty) {
      return null;
    }

    var children = [];
    for (int helix_idx in helix_group_move.helix_idxs_in_group) {
      var helix = helix_group_move.helices[helix_idx]!;

      if (only_display_selected_helices && side_selected_helix_idxs.contains(helix.idx) ||
          !only_display_selected_helices) {
        children.add((DesignMainHelix()
          ..helix = helix
          ..selected = side_selected_helix_idxs.contains(helix.idx)
          ..major_tick_offset_font_size = props.major_tick_offset_font_size
          ..major_tick_width_font_size = props.major_tick_width_font_size
          ..show_dna = false
          ..show_domain_labels = props.show_domain_labels
          ..show_helix_circles = props.show_helix_circles
          ..helix_change_apply_to_all = false
          ..display_base_offsets_of_major_ticks = false
          ..display_major_tick_widths = false
          ..helix_svg_position = props.helix_idx_to_svg_position_map[helix.idx]!
          ..key = helix.idx.toString())());
      }
    }

    var new_position = helix_group_move.current_position;
    var new_group = helix_group_move.group.rebuild((b) => b..position.replace(new_position));
    var transform = new_group.transform_str(helix_group_move.geometry);

    return (Dom.g()
      ..className = 'helix-group-moving-${helix_group_move.group_name}'
      ..transform = transform
      ..key = '${helix_group_move.group_name}')(children);
  }
}
