import 'dart:math';

import 'package:over_react/over_react.dart';

import '../app.dart';
import '../state/grid.dart';
import '../state/grid_position.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;

part 'design_side_potential_helix.over_react.g.dart';

@Factory()
UiFactory<DesignSidePotentialHelixProps> DesignSidePotentialHelix = _$DesignSidePotentialHelix;

@Props()
class _$DesignSidePotentialHelixProps extends UiProps {
  Grid grid;
  GridPosition grid_position;
//  Set<GridPosition> existing_helix_grid_positions;
//  Point<num> mouse_svg_pos;
}

@Component2()
class DesignSidePotentialHelixComponent extends UiComponent2<DesignSidePotentialHelixProps> {
  @override
  render() {
//    Point<num> mouse_svg_pos = props.mouse_svg_pos;
//    if (mouse_svg_pos == null) {
//      return null;
//    }

    Point<num> svg_ideal_pos;
    Grid grid = props.grid;
    GridPosition grid_position = props.grid_position;
    bool allowed_grid_position = true;

    if (grid.is_none()) {
      //FIXME: find a way to implement off-grid
      throw UnsupportedError('currently unsupported to draw potential helix with Grid.none');
//      svg_ideal_pos = mouse_svg_pos;
    } else {
      if (grid == Grid.honeycomb && !util.in_honeycomb_lattice(grid_position)) {
        allowed_grid_position = false;
      }
      svg_ideal_pos = util.side_view_grid_to_svg(grid_position, grid);
    }

    return (Dom.circle()
      ..cx = svg_ideal_pos.x
      ..cy = svg_ideal_pos.y
      ..r = '${constants.SIDE_HELIX_RADIUS}'
      ..onClick = ((e) => this._handle_click(e, grid_position))
      ..className = allowed_grid_position
          ? 'side-view-potential-helix'
          : 'side-view-potential-helix-disallowed-position')();
  }

  _handle_click(SyntheticMouseEvent event, GridPosition grid_pos) {
    // unlike DesignSideHelix, no need to check edit_mode here since PotentialHelix only displayed when
    // edit mode has helix on
    if (grid_pos == null) {
      throw UnsupportedError('clicking to create helices off-grid not yet supported');
    }

    app.dispatch(actions.HelixAdd(grid_pos));
  }
}
