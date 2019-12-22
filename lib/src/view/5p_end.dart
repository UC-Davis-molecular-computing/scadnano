import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;

part '5p_end.over_react.g.dart';

typedef PointerDownHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

abstract class EndEitherPrimeProps implements UiProps {
  PointerDownHandler on_pointer_down;
  MouseUpHandler on_mouse_up;
  String classname;
  Point<num> pos;
  Color color;
  bool forward;
}

@Factory()
UiFactory<End5PrimeProps> End5Prime = _$End5Prime;

@Props()
class _$End5PrimeProps extends UiProps implements EndEitherPrimeProps {
  PointerDownHandler on_pointer_down;
  MouseUpHandler on_mouse_up;
  String classname;
  Point<num> pos;
  Color color;
  bool forward;
}

@Component2()
class End5PrimeComponent extends UiComponent2<End5PrimeProps> {
  @override
  render() {
    //XXX: width, height, rx, ry should be do-able in CSS. However, Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here.
    num width = 7;
    return (Dom.rect()
      ..onPointerDown = props.on_pointer_down
      ..onMouseUp = props.on_mouse_up
      ..className = props.classname
      ..x = '${props.pos.x - width / 2}'
      ..y = '${props.pos.y - width / 2}'
      ..width = '${width}px'
      ..height = '${width}px'
      ..rx = '1.5px'
      ..ry = '1.5px'
      ..fill = props.color.toRgbColor().toCssString())();
  }
}