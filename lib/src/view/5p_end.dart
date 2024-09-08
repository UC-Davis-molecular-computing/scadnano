// @dart=2.9
import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;

part '5p_end.over_react.g.dart';

typedef PointerDownUpHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

abstract class EndEitherPrimeProps implements UiProps {
  PointerDownUpHandler on_pointer_down;
  PointerDownUpHandler on_pointer_up;
  MouseUpHandler on_mouse_up;
  MouseUpHandler on_mouse_move;
  MouseUpHandler on_mouse_enter;
  MouseUpHandler on_mouse_leave;
  String classname;
  Point<double> pos;
  Color color;
  bool forward;
  String id;
  String transform;
}

UiFactory<End5PrimeProps> End5Prime = _$End5Prime;

mixin End5PrimeProps on UiProps implements EndEitherPrimeProps {
  PointerDownUpHandler on_pointer_down;
  PointerDownUpHandler on_pointer_up;
  MouseUpHandler on_mouse_up;
  MouseUpHandler on_mouse_move;
  MouseUpHandler on_mouse_enter;
  MouseUpHandler on_mouse_leave;
  String classname;
  Point<double> pos;
  Color color;
  bool forward;
  String id;
  String transform;
}

class End5PrimeComponent extends UiComponent2<End5PrimeProps> {
  @override
  render() {
    //XXX: width, height, rx, ry should be do-able in CSS. However, Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here.
    num width = 7;
    var rect_props = Dom.rect()
      ..onPointerDown = props.on_pointer_down
      ..onPointerUp = props.on_pointer_up
      ..onMouseUp = props.on_mouse_up
      ..onMouseEnter = props.on_mouse_enter
      ..onMouseLeave = props.on_mouse_leave
      ..onMouseMove = props.on_mouse_move
      ..className = props.classname
      ..x = '${props.pos.x - width / 2}'
      ..y = '${props.pos.y - width / 2}'
      ..width = '${width}px'
      ..height = '${width}px'
      ..rx = '1.5px'
      ..ry = '1.5px'
      ..id = props.id
      ..fill = props.color.toHexColor().toCssString();

    if (props.transform != null) {
      // https://stackoverflow.com/questions/15138801/rotate-rectangle-around-its-own-center-in-svg
      rect_props = rect_props..transform = props.transform;
    }
    return rect_props();
  }
}
