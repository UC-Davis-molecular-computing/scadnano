import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/geometry.dart';
import '../state/position3d.dart';

import '../app.dart';
import '../state/grid.dart';
import '../state/grid_position.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;

part 'design_side_potential_helix.over_react.g.dart';

UiFactory<DesignSidePotentialHelixProps> DesignSidePotentialHelix = _$DesignSidePotentialHelix;

mixin DesignSidePotentialHelixProps on UiProps {
  Grid grid;
  GridPosition grid_position;
  Point<num> mouse_svg_pos;
  bool invert_y;
  Geometry geometry;
}

class DesignSidePotentialHelixComponent extends UiComponent2<DesignSidePotentialHelixProps> {
  @override
  render() {
    if (!props.grid.is_none()) {
      if (props.grid_position == null) {
        return null;
      }
    }

    Point<num> svg_ideal_pos;
    Grid grid = props.grid;

    if (grid.is_none()) {
      svg_ideal_pos = props.mouse_svg_pos;
    } else {
      svg_ideal_pos =
          util.side_view_grid_to_svg(props.grid_position, props.grid, props.invert_y, props.geometry);
    }

    String tooltip = '';
    if (props.grid.is_none()) {
      Position3D pos = util.svg_side_view_to_position3d(props.mouse_svg_pos, props.invert_y, props.geometry);
      tooltip = '(x, y) = ${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)}';
    } else {
      var pos = props.grid_position;
      tooltip = '${pos.h}, ${pos.v}';
    }

    return (Dom.circle()
      ..cx = svg_ideal_pos.x
      ..cy = svg_ideal_pos.y
      ..r = '${props.geometry.helix_radius_svg}'
      ..onClick = _handle_click
      ..className = 'side-view-potential-helix')(Dom.svgTitle()(tooltip));
  }

  _handle_click(SyntheticMouseEvent event) {
    // unlike DesignSideHelix, no need to check edit_mode here since PotentialHelix only displayed when
    // edit mode has helix on
    if (props.grid.is_none()) {
      Position3D position =
          util.svg_side_view_to_position3d(props.mouse_svg_pos, props.invert_y, props.geometry);
      app.dispatch(actions.HelixAdd(position: position));
    } else {
      app.dispatch(actions.HelixAdd(grid_position: props.grid_position));
    }
  }
}
