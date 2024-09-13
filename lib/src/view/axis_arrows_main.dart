@JS()
library scadnano;

import 'package:js/js.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'axis_arrows_side.dart';
import '../app.dart';
import '../state/app_state.dart';
import '../state/strand.dart';

part 'axis_arrows_main.over_react.g.dart';

UiFactory<AxisArrowsMainProps> ConnectedAxisArrowsMain = connect<AppState, AxisArrowsMainProps>(
    mapStateToProps: (state) => set_axis_arrows_props(AxisArrowsMain(), state))(AxisArrowsMain);

UiFactory<AxisArrowsMainProps> AxisArrowsMain = _$AxisArrowsMain;

mixin AxisArrowsMainProps on UiProps implements AxisArrowsProps {
  late bool invert_y;
  late bool show_helices_axis_arrows;
}

class DesignMainArrowsComponent extends UiComponent2<AxisArrowsMainProps> {
  @override
  render() {
    double mag = 50 * 0.93, circle_rad = 10, x_end_offset = circle_rad * 0.632, arrow_padding = 10;

    var arrow_path = 'M 0 0 '
        'v -$mag ' //vertical line to
        'm ${mag / 6.0} ${mag / 4.0} ' //move to
        'L 0 -${mag} ' //normal line to
        'm -${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} ';
    var x_path =
        'M -$x_end_offset -$x_end_offset L $x_end_offset $x_end_offset M $x_end_offset -$x_end_offset L -$x_end_offset $x_end_offset';

    double svg_center_x = circle_rad + arrow_padding;
    double svg_center_y = props.invert_y ? mag + circle_rad + arrow_padding : circle_rad + arrow_padding;

    double font_width = 12, font_height = 17; // arbitrary dimensions found through web inspector

//RGB XYZ
    if (props.show_helices_axis_arrows == true) {
      return (Dom.g()
        ..className = 'arrow-group'
        ..transform = 'translate($svg_center_x, $svg_center_y)')([
        (Dom.svgTitle()..key = "title")(props.invert_y ? "⦻ - Into the screen" : "⊙ - Out of the screen"),
        //outward arrow (X-axis) into the screen ⦻
        if (props.invert_y) ...[
          (Dom.path()
            ..key = "x"
            ..d = x_path
            ..fill = "none"
            ..stroke = 'red'
            ..className = 'axis-arrow')(),
          (Dom.circle()
            ..key = "x_circle"
            ..r = circle_rad
            ..stroke = 'red'
            ..fill = "none"
            ..className = 'axis-arrow')(),
        ],
        //horizontal arrow (Z-axis)
        (Dom.path()
          ..key = "z_path"
          ..transform = 'rotate(90)'
          ..d = arrow_path
          ..fill = "none"
          ..stroke = 'blue'
          ..className = 'axis-arrow')(),
        //downward arrow (Y-axis)
        (Dom.path()
          ..key = "y_path"
          ..transform = props.invert_y ? 'rotate(0)' : 'rotate(180)'
          ..d = arrow_path
          ..fill = "none"
          ..stroke = 'green'
          ..className = 'axis-arrow')(),
        //outward arrow (X-axis) out of the screen ⊙
        if (!props.invert_y) ...[
          (Dom.circle()
            ..key = "dot"
            ..r = "2"
            ..stroke = 'red'
            ..fill = "red"
            ..className = 'axis-arrow')(),
          (Dom.circle()
            ..key = "x_circle"
            ..r = circle_rad
            ..stroke = 'red'
            ..fill = "none"
            ..className = 'axis-arrow')(),
        ],
        // axis labels
        (Dom.text()
          ..key = 'x-axis-label'
          ..x = circle_rad
          ..y = props.invert_y ? -circle_rad : circle_rad + font_height
          ..style = {"fill": "red"})("X"),
        (Dom.text()
          ..key = 'y-axis-label'
          ..x = -font_width / 2
          ..y = props.invert_y ? -mag - 2 : mag + font_height - 2
          ..style = {"fill": "green"})("Y"),
        (Dom.text()
          ..key = 'z-axis-label'
          ..x = mag + 2
          ..y = font_height / 2 - 2
          ..style = {"fill": "blue"})("Z"),
      ]);
    } else {
      return Dom.g()();
    }
  }
}
