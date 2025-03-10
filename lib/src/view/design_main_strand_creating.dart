import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/view/pure_component.dart';
import 'package:scadnano/src/view/transform_by_helix_group.dart';

import '../state/geometry.dart';
import '../state/group.dart';
import '../state/helix.dart';
import '3p_end.dart';
import '5p_end.dart';
import '../constants.dart' as constants;

part 'design_main_strand_creating.over_react.g.dart';

UiFactory<DesignMainStrandCreatingProps> DesignMainStrandCreating = _$DesignMainStrandCreating;

mixin DesignMainStrandCreatingProps on UiProps implements TransformByHelixGroupPropsMixin {
  late Helix helix;
  late bool forward;
  late int start;
  late int end;
  late Color color;

  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late Geometry geometry;
  late num svg_position_y;
}

class DesignMainStrandCreatingComponent extends UiComponent2<DesignMainStrandCreatingProps>
    with PureComponent {
  @override
  render() {
    Point<double> start_svg = props.helix.svg_base_pos(
      props.start,
      props.forward,
      props.svg_position_y,
      props.geometry,
    );
    Point<double> end_svg = props.helix.svg_base_pos(
      props.end - 1,
      props.forward,
      props.svg_position_y,
      props.geometry,
    );

    String classname_5p = constants.css_selector_end_5p_strand;
    String classname_3p = constants.css_selector_end_3p_strand;

    return (Dom.g()
      ..className = constants.css_selector_strand_creating
      ..transform = transform_of_helix2(props, props.helix.idx))(
      (Dom.line()
        ..stroke = props.color.toHexColor().toCssString()
        ..x1 = '${start_svg.x}'
        ..y1 = '${start_svg.y}'
        ..x2 = '${end_svg.x}'
        ..y2 = '${end_svg.y}'
        ..className = constants.css_selector_domain)(),
      (End5Prime()
        ..classname = classname_5p
        ..pos = props.forward ? start_svg : end_svg
        ..color = props.color
        ..forward = props.forward)(),
      (End3Prime()
        ..classname = classname_3p
        ..pos = props.forward ? end_svg : start_svg
        ..color = props.color
        ..forward = props.forward)(),
    );
  }
}
