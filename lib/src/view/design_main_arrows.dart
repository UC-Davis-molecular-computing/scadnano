@JS()
library scadnano;

import 'package:js/js.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import '../app.dart';
import '../state/app_state.dart';
import '../state/strand.dart';

part 'design_main_arrows.over_react.g.dart';

typedef ActionCreator = actions.UndoableAction Function(Strand strand);

UiFactory<DesignMainArrowsProps> ConnectedDesignMainArrows =
    connect<AppState, DesignMainArrowsProps>(mapStateToProps: (state) {
  return DesignMainArrows()
    ..invert_xy = state.ui_state.invert_xy
    ..show_helices_axis_arrows = state.ui_state.show_helices_axis_arrows;
})(DesignMainArrows);

UiFactory<DesignMainArrowsProps> DesignMainArrows = _$DesignMainArrows;

mixin DesignMainArrowsProps on UiProps {
  bool invert_xy;
  bool show_helices_axis_arrows;
}

class DesignMainArrowsComponent extends UiComponent2<DesignMainArrowsProps> {
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

    num svg_center_x = circle_rad + arrow_padding,
        svg_center_y = props.invert_xy ? mag + circle_rad + arrow_padding : circle_rad + arrow_padding;

//RGB XYZ
    if (props.show_helices_axis_arrows == true) {
      return (Dom.g()
      ..className = 'arrow-group'
      ..transform = 'translate($svg_center_x, $svg_center_y)')([
        (Dom.svgTitle()..key = "title")(props.invert_xy ? "⦻ - Into the screen" : "⊙ - Out of the screen"),
        //horizontal arrow (Z-axis)
        if (props.invert_xy) ...[
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
          ..transform = props.invert_xy ? 'rotate(0)' : 'rotate(180)'
          ..d = arrow_path
          ..fill = "none"
          ..stroke = 'green'
          ..className = 'axis-arrow')(),
        //outward arrow (X-axis)
        if (!props.invert_xy) ...[
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
      ]);
    } else {
      return Dom.g()();
    }
  }
}
