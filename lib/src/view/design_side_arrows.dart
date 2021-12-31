import 'package:js/js.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import '../app.dart';
import '../state/app_state.dart';
import '../state/strand.dart';

part 'design_side_arrows.over_react.g.dart';

UiFactory<DesignSideArrowsProps> ConnectedDesignSideArrows =
    connect<AppState, DesignSideArrowsProps>(mapStateToProps: (state) {
  return DesignSideArrows()
    ..invert_xy = state.ui_state.invert_xy
    ..show_helices_axis_arrows = state.ui_state.show_helices_axis_arrows;
})(DesignSideArrows);

UiFactory<DesignSideArrowsProps> DesignSideArrows = _$DesignSideArrows;

mixin DesignSideArrowsProps on UiProps {
  bool invert_xy;
  bool show_helices_axis_arrows;
}

class DesignMainArrowsComponent extends UiComponent2<DesignSideArrowsProps> {
  @override
  render() {
    num mag = 50 * 0.93, circle_rad = 10, x_end_offset = circle_rad * 0.632, arrow_padding = 10;

    var arrow_path = 'M 0 0 '
        'v -$mag ' //vertical line to
        'm ${mag / 6.0} ${mag / 4.0} ' //move to
        'L 0 -${mag} ' //normal line to
        'm -${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} ';
    var x_path =
        'M -$x_end_offset -$x_end_offset L $x_end_offset $x_end_offset M $x_end_offset -$x_end_offset L -$x_end_offset $x_end_offset';

    num svg_center_x = props.invert_xy ? mag + circle_rad + arrow_padding : circle_rad + arrow_padding,
        svg_center_y = props.invert_xy ? mag + circle_rad + arrow_padding : circle_rad + arrow_padding;

    num font_width = 12, font_height = 17;    // arbitrary dimensions found through web inspector

//RGB XYZ
    if (props.show_helices_axis_arrows == true) {
      return (Dom.g()
      ..className = 'arrow-group'
      ..transform = 'translate($svg_center_x, $svg_center_y)')(
        Dom.svgTitle()("⦻ - Into the screen"),
        //inward arrow (Z-axis)
        (Dom.path()
          ..key = "z_path"
          ..d = x_path
          ..fill = "none"
          ..stroke = 'blue'
          ..className = 'axis-arrow')(),
        (Dom.circle()
          ..r = circle_rad
          ..stroke = 'blue'
          ..fill = "none"
          ..className = 'axis-arrow')(),
        // horizontal arrow (X-axis)
        (Dom.path()
          ..key = "x_path"
          ..transform = props.invert_xy ? 'rotate(270)' : 'rotate(90)'
          ..d = arrow_path
          ..fill = "none"
          ..stroke = 'red'
          ..className = 'axis-arrow')(),
        //downward arrow (Y-axis)
        (Dom.path()
          ..key = "y_path"
          ..transform = props.invert_xy ? 'rotate(0)' : 'rotate(180)'
          ..d = arrow_path
          ..fill = "none"
          ..stroke = 'green'
          ..className = 'axis-arrow')(),
        // axis labels
        (Dom.text()
          ..x = props.invert_xy ? -mag - font_width - 2 : mag + 2
          ..y = font_height / 2 - 2
          ..style = {"fill": "red"})("X"),
        (Dom.text()
          ..x = -font_width / 2
          ..y = props.invert_xy ? -mag - 2 : mag + font_height - 2
          ..style = {"fill": "green"})("Y"),
        (Dom.text()
          ..x = props.invert_xy ? -circle_rad - font_width : circle_rad
          ..y = props.invert_xy ? -circle_rad : circle_rad + font_height
          ..style = {"fill": "blue"})("Z"),
      );
    } else {
      return Dom.g()();
    }
  }
}
