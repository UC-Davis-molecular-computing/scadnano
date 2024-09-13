import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;

part '5p_end.over_react.g.dart';

typedef PointerDownUpHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

abstract class EndEitherPrimeProps implements UiProps {
  late String classname;
  late Point<double> pos;
  late Color color;
  late bool forward;
  PointerDownUpHandler? on_pointer_down;
  PointerDownUpHandler? on_pointer_up;
  MouseUpHandler? on_mouse_up;
  MouseUpHandler? on_mouse_move;
  MouseUpHandler? on_mouse_enter;
  MouseUpHandler? on_mouse_leave;
  String? id_;
  String? transform;
}

UiFactory<End5PrimeProps> End5Prime = _$End5Prime;

mixin End5PrimeProps on UiProps implements EndEitherPrimeProps {
  late String classname;
  late Point<double> pos;
  late Color color;
  late bool forward; // this is only needed for 3' end, but we include it here for the uniform interface
  PointerDownUpHandler? on_pointer_down;
  PointerDownUpHandler? on_pointer_up;
  MouseUpHandler? on_mouse_up;
  MouseUpHandler? on_mouse_move;
  MouseUpHandler? on_mouse_enter;
  MouseUpHandler? on_mouse_leave;
  String? id_;
  String? transform;
}

class End5PrimeComponent extends UiComponent2<End5PrimeProps> {
  @override
  render() {
    //XXX: width, height, rx, ry should be do-able in CSS. However, Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here.
    num width = 7;
    var rect_props = Dom.rect()
      ..className = props.classname
      ..x = '${props.pos.x - width / 2}'
      ..y = '${props.pos.y - width / 2}'
      ..width = '${width}px'
      ..height = '${width}px'
      ..rx = '1.5px'
      ..ry = '1.5px'
      ..fill = props.color.toHexColor().toCssString();

    if (props.transform != null) {
      // if it is present, then this is a "real" end, not moving,
      // so all the other option props will also be present
      // https://stackoverflow.com/questions/15138801/rotate-rectangle-around-its-own-center-in-svg
      rect_props = rect_props
        ..transform = props.transform
        ..id = props.id_
        ..onPointerDown = props.on_pointer_down
        ..onPointerUp = props.on_pointer_up
        ..onMouseUp = props.on_mouse_up
        ..onMouseEnter = props.on_mouse_enter
        ..onMouseLeave = props.on_mouse_leave
        ..onMouseMove = props.on_mouse_move;
    }
    return rect_props();
  }
}
