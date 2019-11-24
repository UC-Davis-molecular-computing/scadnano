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
  Set<GridPosition> existing_helix_grid_positions;
  Point<num> mouse_svg_pos;
}

@Component2()
class DesignSidePotentialHelixComponent extends UiComponent2<DesignSidePotentialHelixProps> {
  @override
  render() {
    Point<num> mouse_svg_pos = this.props.mouse_svg_pos;
    if (mouse_svg_pos == null) {
      return null;
    }

    Point<num> svg_ideal_pos;
    Grid grid = this.props.grid;
    GridPosition grid_pos = null;

    if (grid.is_none()) {
      svg_ideal_pos = mouse_svg_pos;
    } else {
      grid_pos = util.side_view_svg_to_grid(grid, mouse_svg_pos);
      if (this.props.existing_helix_grid_positions.contains(grid_pos)) {
        return null;
      }
      if (grid == Grid.honeycomb && !util.in_honeycomb_lattice(grid_pos)) {
        return null;
      }
      svg_ideal_pos = util.side_view_grid_to_svg(grid_pos, grid);
    }

    return (Dom.circle()
      ..cx = svg_ideal_pos.x
      ..cy = svg_ideal_pos.y
      ..r = '${constants.SIDE_HELIX_RADIUS}'
      ..onClick = ((e) => this._handle_click(e, grid_pos))
      ..className = 'side-view-potential-helix')();
  }

  _handle_click(SyntheticMouseEvent event, GridPosition grid_pos) {
    if (!(event.ctrlKey || event.metaKey)) {
      return;
    }
    if (grid_pos == null) {
      throw UnsupportedError('clicking to create helices off-grid not yet supported');
    }

    int idx = app.model.dna_design.helices.length;
    int max_offset = constants.default_max_offset;
    var params = HelixUseActionParameters(true, grid_pos, idx, max_offset);
    var helix_use_action_pack = HelixUseActionPack(params);

    //FIXME: implement this
//    app.send_action(helix_use_action_pack);
  }
}
