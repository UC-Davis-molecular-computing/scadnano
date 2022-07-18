import 'dart:html';
import 'dart:math' as Math;
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';

import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/design.dart';
import '../state/geometry.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import 'design_main_warning_star.dart';
import '../util.dart' as util;

part 'design_main_slice_bar.over_react.g.dart';

UiFactory<DesignMainSliceBarProps> DesignMainSliceBar = _$DesignMainSliceBar;

mixin DesignMainSliceBarProps on UiProps {
  int slice_bar_offset;
  String displayed_group_name;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltMap<String, HelixGroup> groups;
  BuiltMap<String, BuiltList<int>> helix_idxs_in_group;
  BuiltMap<int, Helix> helices;
  bool only_display_selected_helices;
  Geometry geometry;
  BuiltMap<int, Point<num>> helix_idx_to_svg_position_map;
}

class DesignMainSliceBarComponent extends UiComponent2<DesignMainSliceBarProps> with PureComponent {
  @override
  render() {
    num displayed_helices_min_y = double.infinity;
    num displayed_helices_max_y = double.negativeInfinity;
    var helix_idxs_in_group = props.helix_idxs_in_group[props.displayed_group_name];
    for (int helix_idx in helix_idxs_in_group) {
      var helix = props.helices[helix_idx];
      var side_selected_helix_idxs = props.side_selected_helix_idxs;

      bool only_display_selected_helices = props.only_display_selected_helices;
      if (only_display_selected_helices && side_selected_helix_idxs.contains(helix.idx) ||
          !only_display_selected_helices) {
        var y = props.helix_idx_to_svg_position_map[helix_idx].y;
        displayed_helices_max_y = Math.max(displayed_helices_max_y, y);
        displayed_helices_min_y = Math.min(displayed_helices_min_y, y);
      }
    }
    // No helices are displayed, so no slice bar is needed
    if (displayed_helices_min_y == double.infinity) {
      assert(displayed_helices_max_y == double.negativeInfinity);
      return null;
    }
    // Add slicebar if needed
    var geometry = props.geometry;
    var slice_bar_svg_width = geometry.base_width_svg;
    var slice_bar_svg_height = displayed_helices_max_y - displayed_helices_min_y + geometry.helix_diameter_svg;
    var helix = props.helices[helix_idxs_in_group.first];
    var slice_bar_svg_base_center_pos = helix.svg_base_pos(props.slice_bar_offset, true, props.helix_idx_to_svg_position_map[helix_idxs_in_group.first].y);

    var slice_bar_x = slice_bar_svg_base_center_pos.x - geometry.base_width_svg / 2;
    var slice_bar_y = displayed_helices_min_y - geometry.helix_radius_svg + geometry.base_height_svg;

    var slice_bar = (Dom.rect()
      ..onPointerDown = (_) {
        app.dispatch(actions.SliceBarMoveStart());
      }
      ..width = slice_bar_svg_width
      ..height = slice_bar_svg_height
      ..x = slice_bar_x
      ..y = slice_bar_y)();

    var offset_text = (Dom.text()
      ..x = slice_bar_svg_base_center_pos.x
      ..y = slice_bar_y - 5)(props.slice_bar_offset);

    return ((Dom.g()
      ..className = 'slice-bar-rect'
      ..transform = props.groups[props.displayed_group_name].transform_str(props.geometry)
      ..key = 'slice-bar')(slice_bar, offset_text));
  }
}
