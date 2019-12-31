
import 'package:over_react/over_react.dart';

part 'design_side_rotation_arrow.over_react.g.dart';

@Factory()
UiFactory<DesignSideRotationArrowProps> DesignSideRotationArrow = _$DesignSideRotationArrow;

@Props()
class _$DesignSideRotationArrowProps extends UiProps {
  double angle_degrees;
  double radius;
  String color;
}

@Component2()
class DesignSideRotationArrowComponent extends UiComponent2<DesignSideRotationArrowProps> {

  @override
  render() {
    num mag = this.props.radius * 0.93;
//    var path_description = 'M 0 0 '
//        'h $mag '
//        'm ${-mag / 4.0} ${-mag / 6.0} '
//        'L ${mag} 0 '
//        'm ${-mag / 4.0} ${mag / 6.0} '
//        'L ${mag} 0 ';
//    num angle_degrees = this.props.angle * 360.0 / (2 * pi);
    var path_description = 'M 0 0 '
        'v -$mag '
        'm ${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} '
        'm -${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} ';

//    num angle_degrees = this.props.angle * 360.0 / (2 * pi);
    num angle_degrees = this.props.angle_degrees;

    return (Dom.path()
      ..transform = 'rotate($angle_degrees)'
      ..d = path_description
      ..fill = "none"
      ..stroke = this.props.color
      ..className = 'rotation-line')();
  }
}
