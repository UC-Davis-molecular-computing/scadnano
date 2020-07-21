import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/edit_mode.dart';

import '../state/app_state.dart';
import '../state/mouseover_data.dart';
import 'design_side_helix.dart';
import '../state/helix.dart';
import '../state/grid.dart';
import '../state/grid_position.dart';
import 'design_side_potential_helix.dart';
import 'selection_box_view.dart';
import 'pure_component.dart';
import '../util.dart' as util;

part 'design_side.over_react.g.dart';

// The react/redux stuff keeps going in the background even if we don't render it. To prevent a crash when
// there is an error message to display instead of a DNADesign (since the components for DesignSide and DesignMain
// are rendered manually top-level by vanilla Dart DOM code), we need to say what to do here when state has an error.
UiFactory<DesignSideProps> ConnectedDesignSide = connect<AppState, DesignSideProps>(
  mapStateToProps: (state) {
    if (state.has_error()) {
      return DesignSide();
    } else {
      return DesignSide()
        ..helices = state.design.helices
        ..helix_change_apply_to_all = state.ui_state.helix_change_apply_to_all
        ..helix_idxs_selected = state.ui_state.side_selected_helix_idxs
        ..mouseover_datas = state.ui_state.mouseover_datas
        ..edit_modes = state.ui_state.edit_modes
        ..grid = state.design.grid
        ..grid_position_mouse_cursor = state.ui_state.side_view_grid_position_mouse_cursor
        ..mouse_svg_pos = state.ui_state.side_view_position_mouse_cursor
        ..show_grid_coordinates = state.ui_state.show_grid_coordinates_side_view
        ..invert_y = state.ui_state.invert_yz;
    }
  },
)(DesignSide);

UiFactory<DesignSideProps> DesignSide = _$DesignSide;

mixin DesignSideProps on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltSet<int> helix_idxs_selected;
  BuiltList<MouseoverData> mouseover_datas;
  BuiltSet<EditModeChoice> edit_modes;

  Point<num> mouse_svg_pos;
  Grid grid;
  GridPosition grid_position_mouse_cursor;
  bool invert_y;
  bool helix_change_apply_to_all;
  bool show_grid_coordinates;
}

class DesignSideComponent extends UiComponent2<DesignSideProps> with PureComponent {
  @override
  render() {
    if (props.helices == null) {
      // This means there is an error message to display instead of a DNADesign.
      return null;
    }

    BuiltList<MouseoverData> mouseover_datas = props.mouseover_datas;
    Map<int, MouseoverData> helix_idx_to_mouseover_data = {
      for (var mod in mouseover_datas) mod.helix.idx: mod
    };
    BuiltSet<int> helix_idxs_selected = props.helix_idxs_selected;

//    print('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n'
//        'DesignSide.render()  using helices:\n${helices}');

    List helices_components = [
      for (var helix in props.helices.values)
        (DesignSideHelix()
//        (ConnectedDesignSideHelix()
          ..helix = helix
          ..invert_y = props.invert_y
          ..grid = props.grid
          ..helix_change_apply_to_all = props.helix_change_apply_to_all
          ..edit_modes = props.edit_modes
          ..mouse_is_over = props.grid_position_mouse_cursor == helix.grid_position
          ..show_grid_coordinates = props.show_grid_coordinates
          ..selected = helix_idxs_selected.contains(helix.idx)
          ..mouseover_data = helix_idx_to_mouseover_data[helix.idx]
          ..key = '${helix.position_ == null ? helix.grid_position : helix.position_}')()
    ];
    Set<GridPosition> existing_helix_grid_positions = {
      for (var helix in props.helices.values) helix.grid_position
    };

    bool should_display_potential_helix = props.mouse_svg_pos != null ||
        (props.grid_position_mouse_cursor != null &&
            !existing_helix_grid_positions.contains(props.grid_position_mouse_cursor));

    return (Dom.g()..className = 'side-view')([
      if (should_display_potential_helix)
        (DesignSidePotentialHelix()
          ..grid = this.props.grid
          ..invert_y = props.invert_y
          ..grid_position = props.grid_position_mouse_cursor
          ..mouse_svg_pos = props.mouse_svg_pos
          ..key = 'potential-helix')(),
      (Dom.g()
        ..className = 'helices-side-view'
        ..key = 'helices-side-view')(helices_components),
      (ConnectedSelectionBoxView()
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_side_js())
        ..is_main = false
        ..id = 'selection-box-side'
        ..key = 'selection-box')(),
    ]);
  }
}
