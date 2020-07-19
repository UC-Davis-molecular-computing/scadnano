import 'package:over_react/over_react.dart';

part 'design_side_rotation_arrow.over_react.g.dart';

UiFactory<DesignSideRotationArrowProps> DesignSideRotationArrow = _$DesignSideRotationArrow;

mixin DesignSideRotationArrowProps on UiProps {
  double angle_degrees;
  double radius;
  String color;
  bool invert_y;
}

class DesignSideRotationArrowComponent extends UiComponent2<DesignSideRotationArrowProps> {
  @override
  render() {
    num mag = this.props.radius * 0.93;
    var path_description = 'M 0 0 '
        'v -$mag '
        'm ${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} '
        'm -${mag / 6.0} ${mag / 4.0} '
        'L 0 -${mag} ';

    num angle_degrees = this.props.angle_degrees;
    if (props.invert_y) {
      angle_degrees += 180;
    }

    return (Dom.path()
      ..transform = 'rotate($angle_degrees)'
      ..d = path_description
      ..fill = "none"
      ..stroke = this.props.color
      ..className = 'rotation-line')();
  }
}
