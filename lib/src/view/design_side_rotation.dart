import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/mouseover_data.dart';

import '../model/helix.dart';

part 'design_side_rotation.over_react.g.dart';

@Factory()
UiFactory<DesignSideRotationProps> DesignSideRotation = _$DesignSideRotation;

@Props()
class _$DesignSideRotationProps extends UiProps {
  Helix helix;
  double radius;
  MouseoverData mouseover_data;
}

@Component()
class DesignSideRotationComponent extends UiComponent<DesignSideRotationProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    var rotation_3p = this.props.helix.rotation_3p(this.props.mouseover_data.offset);
    var rotation_5p = this.props.helix.rotation_5p(this.props.mouseover_data.offset);
    var x_3p = cos(rotation_3p) * this.props.radius;
    var y_3p = sin(rotation_3p) * this.props.radius;
    var x_5p = cos(rotation_5p) * this.props.radius;
    var y_5p = sin(rotation_5p) * this.props.radius;
    return Dom.g()(
      (Dom.line()
        ..x1 = 0
        ..y1 = 0
        ..x2 = x_3p
        ..y2 = y_3p
        ..className = 'rotation-line rotation-line-3p')(),
      (Dom.line()
        ..x1 = 0
        ..y1 = 0
        ..x2 = x_5p
        ..y2 = y_5p
        ..className = 'rotation-line rotation-line-5p')(),
    );
  }
}
