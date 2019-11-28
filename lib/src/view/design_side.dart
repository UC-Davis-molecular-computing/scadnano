import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/model/selection_box.dart';

import '../model/model.dart';
import '../model/mouseover_data.dart';
import 'design_side_helix.dart';
import '../model/helix.dart';
import '../model/grid.dart';
import '../model/grid_position.dart';
import 'design_side_potential_helix.dart';
import 'selection_box_view.dart';
import '../util.dart' as util;

part 'design_side.over_react.g.dart';

// The react/redux stuff keeps going in the background even if we don't render it. To prevent a crash when
// there is an error message to display instead of a DNADesign (since the components for DesignSide and DesignMain
// are rendered manually top-level by vanilla Dart DOM code), we need to say what to do here when model has an error.
UiFactory<_$DesignSideProps> ConnectedDesignSide = connect<Model, DesignSideProps>(
  mapStateToProps: (model) => (DesignSide()
    ..helices = model.has_error() ? null : model.dna_design.helices
    ..helix_idxs_selected = model.has_error() ? null : model.ui_model.side_selected_helix_idxs
    ..mouseover_datas = model.has_error() ? null : model.ui_model.mouseover_datas
    ..mouse_svg_pos = model.has_error() ? null : model.ui_model.mouse_svg_pos_side_view
    ..grid = model.has_error() ? null : model.dna_design.grid
    ..selection_box = model.has_error() ? null : model.ui_model.selection_box_side_view),
)(DesignSide);

@Factory()
UiFactory<DesignSideProps> DesignSide = _$DesignSide;

@Props()
class _$DesignSideProps extends UiProps {
  BuiltList<Helix> helices;
  BuiltSet<int> helix_idxs_selected;
  BuiltList<MouseoverData> mouseover_datas;
  Point<num> mouse_svg_pos;
  Grid grid;
  SelectionBox selection_box;
}

@Component2()
class DesignSideComponent extends UiComponent2<DesignSideProps> {
  @override
  render() {
    if (props.helices == null) {
      // This means there is an error message to display instead of a DNADesign.
      return null;
    }

    SelectionBox selection_box = props.selection_box;
    Point<num> mouse_svg_pos = props.mouse_svg_pos;
    BuiltList<MouseoverData> mouseover_datas = props.mouseover_datas;
    Map<int, MouseoverData> helix_idx_to_mouseover_data = {for (var mod in mouseover_datas) mod.helix.idx: mod};
    BuiltList<Helix> helices = props.helices;
    BuiltSet<int> helix_idxs_selected = props.helix_idxs_selected;

    print('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n'
        'DesignSide.render()  using helices:\n${helices}');

    //TODO: it's not well-defined what to do when grid=none and there is no grid position for helices
    List helices_components = [
      for (var helix in helices)
        (DesignSideHelix()
//        (ConnectedDesignSideHelix()
          ..helix = helix
          ..grid_position = helix.grid_position
          ..grid = this.props.grid
          ..selected = helix_idxs_selected.contains(helix.idx)
//          ..mouseover_datas = mouseover_datas
          ..mouseover_data = helix_idx_to_mouseover_data[helix.idx]
          ..key = '${helix.has_grid_position() ? helix.grid_position : helix.svg_position}')()
    ];
    Set<GridPosition> existing_helix_grid_positions = {for (var helix in helices) helix.grid_position};

    return (Dom.g()..className = 'side-view')([
      (DesignSidePotentialHelix()
        ..grid = this.props.grid
        ..existing_helix_grid_positions = existing_helix_grid_positions
        ..mouse_svg_pos = mouse_svg_pos
        ..key = 'potential-helix')(),
      (Dom.g()
        ..className = 'helices-side-view'
        ..key = 'helices-side-view')(helices_components),
      if (selection_box != null && selection_box.displayed)
        (SelectionBoxView()
          ..selection_box = selection_box
          ..stroke_width = 2.0 / util.current_zoom_side()
          ..key = 'selection-box')(),
    ]);
  }
}
