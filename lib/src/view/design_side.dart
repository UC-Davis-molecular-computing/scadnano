import 'dart:svg' hide Point;

import 'package:scadnano/src/constants.dart';

import 'design_side_helix.dart';
import '../model/helix.dart';
import '../app.dart';

import 'package:over_react/over_react.dart';

part 'design_side.over_react.g.dart';

@Factory()
UiFactory<DesignSideProps> DesignSide = _$DesignSide;

@Props()
class _$DesignSideProps extends FluxUiProps<HelicesStore, HelicesStore> {}

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
          ..used = true
          ..grid_position = helix.grid_position()
          ..key = '${helix.has_grid_position() ? helix.grid_position() : helix.svg_position()}')()
    ];
    List potential_helices_components = [
      for (var potential_helix in this.props.store.potential_helices)
        (DesignSideHelix()
          ..helix = null
          ..used = false
          ..grid_position = potential_helix.grid_position()
          ..key = '${potential_helix.grid_position()}')()
    ];
    return (Dom.g()..className = 'helices-side-view')(helices_components + potential_helices_components);
  }
}
