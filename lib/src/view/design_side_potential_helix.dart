import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:scadnano/src/model/helix.dart';

import '../../scadnano.dart';
import '../model/model_ui_side.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_side_potential_helix.over_react.g.dart';

@Factory()
UiFactory<DesignSidePotentialHelixProps> DesignSidePotentialHelix = _$DesignSidePotentialHelix;

@Props()
class _$DesignSidePotentialHelixProps
    extends FluxUiProps<SideViewMousePositionStore, SideViewMousePositionStore> {
  Grid grid;
  Set<GridPosition> existing_helix_grid_positions;
}

@Component()
class DesignSidePotentialHelixComponent extends FluxUiComponent<DesignSidePotentialHelixProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    Point<num> svg_pos = this.props.store.pos;
    if (svg_pos == null) {
      return null;
    }

    Grid grid = this.props.grid;

    if (grid == Grid.honeycomb || grid == Grid.hex) {
      //TODO: implement other two grids
      return null;
    }

    if (grid == Grid.square) {
      GridPosition grid_pos = util.side_view_svg_to_grid(grid, svg_pos);
      if (this.props.existing_helix_grid_positions.contains(grid_pos)) {
        return null;
      } else {
        Point<num> svg_ideal_pos = util.side_view_grid_to_svg(grid_pos, grid);
        return (Dom.circle()
          ..cx = svg_ideal_pos.x
          ..cy = svg_ideal_pos.y
          ..r = '${constants.SIDE_HELIX_RADIUS}'
          ..onClick = ((e) => this._handle_click(e, grid_pos))
          ..className = 'side-view-potential-helix')();
      }
    } else {
      return null;
    }
  }

  _handle_click(SyntheticMouseEvent event, GridPosition grid_pos) {
    if (!event.ctrlKey) {
      return;
    }

    int idx = app.model.dna_design.helices.length;
    int max_offset = constants.default_max_offset;
    var params = HelixUseActionParameters(true, grid_pos, idx, max_offset);
    var helix_use_action_pack = HelixUseActionPack(params);

    app.send_action(helix_use_action_pack);
  }
}
