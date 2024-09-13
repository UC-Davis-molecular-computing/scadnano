import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/design_side_rotation_data.dart';

import '../state/mouseover_data.dart';
import '../state/helix.dart';
import 'design_side_rotation_arrow.dart';
import 'pure_component.dart';

part 'design_side_rotation.over_react.g.dart';

UiFactory<DesignSideRotationProps> DesignSideRotation = _$DesignSideRotation;

mixin DesignSideRotationProps on UiProps {
  late double radius;
  late DesignSideRotationData data;
  late bool invert_y;
}

class DesignSideRotationComponent extends UiComponent2<DesignSideRotationProps> with PureComponent {
  @override
  render() {
    double roll_reverse = props.data.roll_forward + props.data.minor_groove_angle;
    var color_forward_str = props.data.color_forward.toHexColor().toCssString();
    var color_reverse_str = props.data.color_reverse.toHexColor().toCssString();

    return Dom.g()(
      (DesignSideRotationArrow()
        ..radius = props.radius
        ..angle_degrees = props.data.roll_forward
        ..color = color_forward_str
        ..invert_y = props.invert_y
        ..className = 'rotation-arrow')(),
      (DesignSideRotationArrow()
        ..radius = props.radius
        ..angle_degrees = roll_reverse
        ..color = color_reverse_str
        ..invert_y = props.invert_y
        ..className = 'rotation-arrow')(),
    );
  }
}
