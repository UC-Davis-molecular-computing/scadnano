import 'package:js/js.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import '../app.dart';
import '../state/app_state.dart';
import '../state/strand.dart';

part 'axis_arrows_side.over_react.g.dart';

///////////////////////////////////////////////////////
// shared between AxisArrowsMain and AxisArrowsSide
abstract class AxisArrowsProps implements UiProps {
  late bool invert_y;
  late bool show_helices_axis_arrows;
}

//FIXME: this (and related functions of the form set_some_props defined near the `connect` function
// calls for connected OverReact components) are a workaround for a strange
// behavior in OverReact where in connected components, required props must be set not only
// in the `mapStateToProps` function, but also when hooking up the connected component to the view
// as in the file view/design.dart (where ConnectedAxisArrowsSide() is invoked in `react_dom.render`)
AxisArrowsProps set_axis_arrows_props(AxisArrowsProps elt, AppState state) =>
    elt
      ..invert_y = state.ui_state.invert_y
      ..show_helices_axis_arrows = state.ui_state.show_helices_axis_arrows;
// end shared between AxisArrowsMain and AxisArrowsSide
///////////////////////////////////////////////////////

UiFactory<AxisArrowsSideProps> ConnectedAxisArrowsSide = connect<AppState, AxisArrowsSideProps>(
  mapStateToProps: (state) => set_axis_arrows_props(AxisArrowsSide(), state),
)(AxisArrowsSide);

UiFactory<AxisArrowsSideProps> AxisArrowsSide = _$AxisArrowsSide;

mixin AxisArrowsSideProps on UiProps implements AxisArrowsProps {
  late bool invert_y;
  late bool show_helices_axis_arrows;
}

class AxisArrowsComponent extends UiComponent2<AxisArrowsSideProps> {
  @override
  render() {
    double mag = 50 * 0.93, circle_rad = 10, x_end_offset = circle_rad * 0.632, arrow_padding = 10;

    var arrow_path =
        'M 0 0 '
        'v -$mag ' //vertical line to
        'm ${mag / 6.0} ${mag / 4.0} ' //move to
        'L 0 -${mag} ' //normal line to
        'm -${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} ';
    var x_path =
        'M -$x_end_offset -$x_end_offset L $x_end_offset $x_end_offset M $x_end_offset -$x_end_offset L -$x_end_offset $x_end_offset';

    double svg_center_x = props.invert_y ? mag + circle_rad + arrow_padding : circle_rad + arrow_padding;
    double svg_center_y = props.invert_y ? mag + circle_rad + arrow_padding : circle_rad + arrow_padding;

    double font_width = 12, font_height = 17; // arbitrary dimensions found through web inspector

    //RGB XYZ
    if (props.show_helices_axis_arrows == true) {
      return (Dom.g()
        ..className = 'arrow-group'
        ..transform = 'translate($svg_center_x, $svg_center_y)')(
        Dom.svgTitle()("⦻ - Into the screen"),
        //inward arrow (Z-axis)
        (Dom.path()
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
          ..transform = props.invert_y ? 'rotate(270)' : 'rotate(90)'
          ..d = arrow_path
          ..fill = "none"
          ..stroke = 'red'
          ..className = 'axis-arrow')(),
        //downward arrow (Y-axis)
        (Dom.path()
          ..transform = props.invert_y ? 'rotate(0)' : 'rotate(180)'
          ..d = arrow_path
          ..fill = "none"
          ..stroke = 'green'
          ..className = 'axis-arrow')(),
        // axis labels
        (Dom.text()
          ..x = props.invert_y ? -mag - font_width - 2 : mag + 2
          ..y = font_height / 2 - 2
          ..style = {"fill": "red"})("X"),
        (Dom.text()
          ..x = -font_width / 2
          ..y = props.invert_y ? -mag - 2 : mag + font_height - 2
          ..style = {"fill": "green"})("Y"),
        (Dom.text()
          ..x = props.invert_y ? -circle_rad - font_width : circle_rad
          ..y = props.invert_y ? -circle_rad : circle_rad + font_height
          ..style = {"fill": "blue"})("Z"),
      );
    } else {
      return Dom.g()();
    }
  }
}
