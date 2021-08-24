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
  return DesignMainArrows()..invert_xy = state.ui_state.invert_xy;
})(DesignMainArrows);

UiFactory<DesignMainArrowsProps> DesignMainArrows = _$DesignMainArrows;

mixin DesignMainArrowsProps on UiProps {
  bool invert_xy;
}

class DesignMainArrowsComponent extends UiComponent2<DesignMainArrowsProps> {
  @override
  render() {
    num mag = 50 * 0.93;
    var path_description = 'M 0 0 '
        'v -$mag ' //vertical line to
        'm ${mag / 6.0} ${mag / 4.0} ' //move to
        'L 0 -${mag} ' //normal line to
        'm -${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} ';
//RGB XYZ
    return (Dom.g()..className = 'axis-arrows')([
      //horizontal arrow (Z-axis)
      (Dom.path()
        ..key = "z_path"
        ..transform = 'rotate(90)'
        ..d = path_description
        ..fill = "none"
        ..stroke = 'blue'
        ..className = 'axis-arrow')(),
      //downward arrow (Y-axis)
      (Dom.path()
        ..key = "y_path"
        ..transform = props.invert_xy ? 'rotate(0)' : 'rotate(180)'
        ..d = path_description
        ..fill = "none"
        ..stroke = 'green'
        ..className = 'axis-arrow')(),
      //outward arrow (X-axis)
      if (!props.invert_xy)
        (Dom.circle()
          ..key = "dot"
          ..r = "2"
          ..stroke = 'red'
          ..fill = "red"
          ..className = 'axis-arrow')(),
      if (props.invert_xy)
        (Dom.path()
          ..key = "x"
          ..d = 'M -6.32 -6.32 L 6.32 6.32 M 6.32 -6.32 L -6.32 6.32'
          ..fill = "none"
          ..stroke = 'red'
          ..className = 'axis-arrow')(),
      (Dom.circle()
        ..key = "x_circle"
        ..r = "10"
        ..stroke = 'red'
        ..fill = "none"
        ..title = props.invert_xy ? "⦻ - Into the screen" : "⊙ - Out of the screen"
        ..className = 'axis-arrow')(),
  
    ]);
  }
}