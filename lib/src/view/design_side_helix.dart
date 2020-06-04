import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/position3d.dart';

import '../state/mouseover_data.dart';
import '../app.dart';
import '../state/helix.dart';
import 'design_side_rotation.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'pure_component.dart';

part 'design_side_helix.over_react.g.dart';

const String SIDE_VIEW_PREFIX = 'side-view';

//UiFactory<_$DesignSideHelixProps> ConnectedDesignSideHelix = connect<AppState, _$DesignSideHelixProps>(
//  mapStateToProps: (state) => (DesignSideHelix()),
//)(DesignSideHelix);

UiFactory<DesignSideHelixProps> DesignSideHelix = _$DesignSideHelix;

mixin DesignSideHelixProps on UiProps {
  Helix helix;
  bool selected;
  bool mouse_is_over;
  MouseoverData mouseover_data;
  BuiltSet<EditModeChoice> edit_modes;
  Grid grid;
}

class DesignSideHelixComponent extends UiComponent2<DesignSideHelixProps> with PureComponent {
  @override
  render() {
//    print('rendering side helix ${props.helix.idx}');
    MouseoverData mouseover_data = this.props.mouseover_data;
//    print('  mouseover_data: $mouseover_data');

    Helix helix = props.helix;

    bool selected = props.selected;

    String classname_circle = '$SIDE_VIEW_PREFIX-helix-circle';
    if (selected) {
      classname_circle += ' selected';
    }
    if (props.mouse_is_over && props.edit_modes.contains(EditModeChoice.pencil)) {
      classname_circle += ' deletable';
    }

    // set SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX to true to print helix coordinates in side view instead
    // of idx, which is useful for making figures in the documentation showing how the grids work
//    bool SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX = true;
    bool SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX = false;
    var temp_text_for_help_doc_figure_making;

    String tooltip;
    if (props.grid.is_none()) {
      var pos = props.helix.position3d();
      int precision = constants.NUM_DIGITS_PRECISION_POSITION_DISPLAYED;
      tooltip = '${pos.x.toStringAsFixed(precision)}, ${pos.y.toStringAsFixed(precision)}';
      temp_text_for_help_doc_figure_making = '${pos.x.toStringAsFixed(1)},${pos.y.toStringAsFixed(1)}';
    } else {
      var pos = props.helix.grid_position;
      tooltip = '${pos.h}, ${pos.v}';
      temp_text_for_help_doc_figure_making = tooltip.replaceAll(' ', '');
    }

    var children = [
      (Dom.circle()
        ..className = classname_circle
        ..r = '${constants.HELIX_RADIUS_SIDE_PIXELS}'
        ..onClick = ((e) => this._handle_click(e, helix))
        ..key = 'circle')(Dom.svgTitle()(tooltip)),
      (Dom.text()
            ..style = SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX ? {'font-size': 20} : {}
            ..className = '$SIDE_VIEW_PREFIX-helix-text'
            ..onClick = ((e) => this._handle_click(e, helix))
            ..key = 'text')(
          SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX
              ? temp_text_for_help_doc_figure_making
              : props.helix.idx.toString(),
          Dom.svgTitle()(tooltip)),
    ];

//    print('checking mouseover data');
    if (mouseover_data != null) {
//      print('mouseover data not null; creating DesignSideRotation now');
      assert(mouseover_data.helix.idx == this.props.helix.idx);
      var rot_component = (DesignSideRotation()
        ..radius = constants.HELIX_RADIUS_SIDE_PIXELS
        ..helix = mouseover_data.helix
        ..offset = mouseover_data.offset
        ..key = 'rotation'
        ..className = '$SIDE_VIEW_PREFIX-helix-rotation')();
      children.add(rot_component);
    }

    Position3D pos3d = helix.position3d();
    Point<num> center = util.position3d_to_side_view_svg(pos3d);

    return (Dom.g()..transform = 'translate(${center.x} ${center.y})')(children);
  }

  _handle_click(SyntheticMouseEvent event, Helix helix) {
    if (props.edit_modes.contains(EditModeChoice.pencil)) {
      app.dispatch(actions.HelixRemove(helix.idx));
    } else if (event.shiftKey) {
      app.dispatch(actions.HelixSelect(helix.idx, false));
    } else if (event.ctrlKey || event.metaKey) {
      app.dispatch(actions.HelixSelect(helix.idx, true));
    }
  }
}
