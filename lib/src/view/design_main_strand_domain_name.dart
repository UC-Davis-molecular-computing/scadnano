import 'dart:math';

import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_strand_domain_name.over_react.g.dart';

UiFactory<DesignMainStrandDomainNameProps> DesignMainStrandDomainName = _$DesignMainStrandDomainName;

mixin DesignMainStrandDomainNamePropsMixin on UiProps {
  Domain domain;
  Helix helix;
  Geometry geometry;

  int font_size;
  bool show_dna;
  String transform;
  num svg_position_y;
}

class DesignMainStrandDomainNameProps = UiProps with DesignMainStrandDomainNamePropsMixin;

class DesignMainStrandDomainNameComponent extends UiComponent2<DesignMainStrandDomainNameProps>
    with PureComponent {
  @override
  render() {

    Point<num> start_svg = props.helix.svg_base_pos(props.domain.start, props.domain.forward, props.svg_position_y);
    Point<num> end_svg = props.helix.svg_base_pos(props.domain.end - 1, props.domain.forward, props.svg_position_y);
    Point<num> mid_svg = (start_svg + end_svg) * 0.5;

    String baseline = props.domain.forward ? 'baseline' : 'hanging';

    // offset depends on whether we are showing DNA, so they don't overlap
    num offset_of_dna = props.show_dna ? props.helix.geometry.base_height_svg : 0;

    var dy = props.geometry.base_height_svg * 0.7 + offset_of_dna;
    if (props.domain.forward) {
      dy = -dy;
    }

    return (Dom.text()
      ..x = '${mid_svg.x}'
      ..y = '${mid_svg.y}'
      ..dy = '${dy}'
      ..transform = props.transform
      ..fontSize = props.font_size
      ..dominantBaseline = baseline
      ..className = constants.css_selector_domain_name_text)(props.domain.name);
  }
}
