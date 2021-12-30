import 'dart:math';

import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_strand_strand_name.over_react.g.dart';

UiFactory<DesignMainStrandStrandNameProps> DesignMainStrandStrandName = _$DesignMainStrandStrandName;

mixin DesignMainStrandStrandNamePropsMixin on UiProps {
  String strand_name;
  Domain domain; // domain next to which we draw strand name
  Helix helix;
  Geometry geometry;

  int font_size;
  bool show_dna;
  bool show_domain_names;
  String transform;
  num helix_svg_position_y;
}

class DesignMainStrandStrandNameProps = UiProps with DesignMainStrandStrandNamePropsMixin;

class DesignMainStrandStrandNameComponent extends UiComponent2<DesignMainStrandStrandNameProps>
    with PureComponent {
  @override
  render() {
    Point<num> start_svg = props.helix.svg_base_pos(props.domain.start, props.domain.forward, props.helix_svg_position_y);
    Point<num> end_svg = props.helix.svg_base_pos(props.domain.end - 1, props.domain.forward, props.helix_svg_position_y);
    Point<num> mid_svg = (start_svg + end_svg) * 0.5;

    String baseline = props.domain.forward ? 'baseline' : 'hanging';

    // offset depends on whether we are showing DNA and/or domain names, so they don't overlap
    num y_offset = 0;
    if (props.show_dna) {
      y_offset += props.helix.geometry.base_height_svg;
    }
    if (props.show_domain_names) {
      y_offset += props.helix.geometry.base_height_svg;
    }

    var dy = props.geometry.base_height_svg * 0.7 + y_offset;
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
      ..className = constants.css_selector_strand_name_text)(props.strand_name);
  }
}
