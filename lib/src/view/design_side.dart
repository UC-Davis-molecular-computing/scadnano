import 'package:over_react/over_react.dart';

import '../model/model_ui_side.dart';
import '../model/mouseover_data.dart';
import 'design_side_helix.dart';
import '../model/helix.dart';
import 'design_side_potential_helix.dart';

part 'design_side.over_react.g.dart';

@Factory()
UiFactory<DesignSideProps> DesignSide = _$DesignSide;

@Props()
class _$DesignSideProps extends FluxUiProps<HelicesStore, HelicesStore> {
  MouseoverDataStore mouseover_data_store;
  SideViewMousePositionStore side_view_mouse_position_store;
  Grid grid;
}

@Component()
class DesignSideComponent extends FluxUiComponent<DesignSideProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    //TODO: it's not well-defined what to do when grid=none and there is no grid position for helices
    List helices_components = [
      for (var helix in this.props.store.helices)
        (DesignSideHelix()
          ..helix = helix
          ..grid_position = helix.grid_position()
          ..grid = this.props.grid
          ..store = this.props.mouseover_data_store
          ..key = '${helix.has_grid_position() ? helix.grid_position() : helix.svg_position()}')()
    ];
    Set<GridPosition> existing_helix_grid_positions = {
      for (var helix in this.props.store.helices) helix.grid_position()
    };
    return (Dom.g()..className = 'side-view')(
      (DesignSidePotentialHelix()
        ..grid = this.props.grid
        ..existing_helix_grid_positions = existing_helix_grid_positions
        ..store = this.props.side_view_mouse_position_store)(),
      (Dom.g()..className = 'helices-side-view')(helices_components),
    );
  }
}
