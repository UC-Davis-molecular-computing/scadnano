import 'dart:math';

import 'package:over_react/over_react.dart';

import '../app.dart';
import '../actions/actions_OLD.dart';
import '../model/grid.dart';
import '../model/grid_position.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

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
      ..className = allowed_grid_position? 'side-view-potential-helix': 'side-view-potential-helix-disallowed-position')();
  }

  _handle_click(SyntheticMouseEvent event, GridPosition grid_pos) {
    if (!(event.ctrlKey || event.metaKey)) {
      return;
    }
    if (grid_pos == null) {
      throw UnsupportedError('clicking to create helices off-grid not yet supported');
    }

    int idx = app.state.dna_design.helices.length;
    int max_offset = constants.default_max_offset;
    var params = HelixUseActionParameters(true, grid_pos, idx, max_offset);
    var helix_use_action_pack = HelixUseActionPack(params);

    //FIXME: implement this
//    app.send_action(helix_use_action_pack);
  }
}
