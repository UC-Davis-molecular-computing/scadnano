import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import '../state/context_menu.dart';
import '../state/edit_mode.dart';
import '../state/grid.dart';
import '../state/position3d.dart';

import '../state/mouseover_data.dart';
import '../app.dart';
import '../state/helix.dart';
import 'design_side_rotation.dart';
import 'pure_component.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'helix_context_menu.dart';

part 'design_side_helix.over_react.g.dart';

const String SIDE_VIEW_PREFIX = 'side-view';

UiFactory<DesignSideHelixProps> DesignSideHelix = _$DesignSideHelix;

mixin DesignSideHelixProps on UiProps {
  Helix helix;
  bool selected;
  bool mouse_is_over;
  bool helix_change_apply_to_all;
  bool show_grid_coordinates;
  bool invert_y;
  Grid grid;
  MouseoverData mouseover_data;
  BuiltSet<EditModeChoice> edit_modes;
}

class DesignSideHelixComponent extends UiComponent2<DesignSideHelixProps> with PureComponent {
  @override
  render() {
    String classname_circle = '$SIDE_VIEW_PREFIX-helix-circle';
    if (props.selected) {
      classname_circle += ' selected';
    }
    if (props.mouse_is_over && props.edit_modes.contains(EditModeChoice.pencil)) {
      classname_circle += ' deletable';
    }

    // set SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX to true to print helix coordinates in side view instead
    // of idx, which is useful for making figures in the documentation showing how the grids work
//    bool SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX = true;
    bool SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX = false;
    String grid_position_str;

    String tooltip;
    if (props.grid.is_none()) {
      var pos = props.helix.position3d();
      int precision = constants.NUM_DIGITS_PRECISION_POSITION_DISPLAYED;
      tooltip = '${pos.x.toStringAsFixed(precision)}, ${pos.y.toStringAsFixed(precision)}';
      grid_position_str = '${pos.x.toStringAsFixed(1)},${pos.y.toStringAsFixed(1)}';
    } else {
      var pos = props.helix.grid_position;
      tooltip = '${pos.h}, ${pos.v}';
      grid_position_str = tooltip.replaceAll(' ', '');
    }

    var children = [
      (Dom.circle()
        ..className = classname_circle
        ..r = '${props.helix.geometry.helix_radius_svg}'
        ..onClick = ((e) => this._handle_click(e, props.helix))
        ..id = helix_circle_id()
        ..key = 'circle')((Dom.svgTitle()..key = 'circle-tooltip')(tooltip)),
      (Dom.text()
            ..style = SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX ? {'fontSize': 20} : {}
            ..className = '$SIDE_VIEW_PREFIX-helix-text'
            ..id = helix_text_id()
            ..onClick = ((e) => this._handle_click(e, props.helix))
            ..key = 'text-idx')(
          SHOW_HELIX_COORDINATES_INSTEAD_OF_IDX ? grid_position_str : props.helix.idx.toString(),
          (Dom.svgTitle()..key = 'text-idx-tooltip')(tooltip)),
      if (props.show_grid_coordinates)
        (Dom.text()
          ..fontSize = 10
          ..dominantBaseline = 'text-before-edge'
          ..textAnchor = 'middle'
          ..y = props.helix.geometry.helix_radius_svg / 2
          ..key = 'text-grid-position')(grid_position_str),
      ((Dom.svgTitle()..key = 'text-grid-position-tooltip')(tooltip)),
    ];

    if (props.mouseover_data != null) {
      assert(props.mouseover_data.helix.idx == this.props.helix.idx);
      var rot_component = (DesignSideRotation()
        ..radius = props.helix.geometry.helix_radius_svg
        ..mouseover_data = props.mouseover_data
        ..invert_y = props.invert_y
        ..className = '$SIDE_VIEW_PREFIX-helix-rotation'
        ..key = 'rotation')();
      children.add(rot_component);
    }

    Position3D pos3d = props.helix.position3d();
    Point<num> center = util.position3d_to_side_view_svg(pos3d, props.helix.invert_yz, props.helix.geometry);

    return (Dom.g()
      ..transform = 'translate(${center.x} ${center.y})'
      ..id = group_id())(children);
  }

  String helix_circle_id() => 'side-view-helix-circle-${props.helix.idx}';

  String helix_text_id() => 'side-view-helix-text-${props.helix.idx}';

  String group_id() => 'helix-side-view-${props.helix.idx}';

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var elt = querySelector('#${group_id()}');
    elt.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var elt = querySelector('#${group_id()}');
    elt.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: context_menu_helix(props.helix, props.helix_change_apply_to_all).build(),
              position: event.page)));
    }
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
