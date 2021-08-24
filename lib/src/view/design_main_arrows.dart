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
    ..invert_xy = state.ui_state.invert_xy;
})(DesignMainArrows);

UiFactory<DesignMainArrowsProps> DesignMainArrows = _$DesignMainArrows;

mixin DesignMainArrowsProps on UiProps {
  bool invert_xy;
}

class DesignMainArrowsComponent
    extends UiComponent2<DesignMainArrowsProps> {
 

  @override
  render() {
    num mag = 50 * 0.93;
    var path_description = 'M 0 0 '
        'v -$mag '
        'm ${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} '
        'm -${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} ';


    return (Dom.path()
      ..d = path_description
      ..fill = "none"
      ..stroke = 'red'
      ..className = 'arrow-line')();
  }