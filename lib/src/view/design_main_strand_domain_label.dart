import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/domain.dart';
import 'pure_component.dart';

import '../state/helix.dart';

part 'design_main_strand_domain_label.over_react.g.dart';

UiFactory<DesignMainStrandDomainLabelProps> DesignMainStrandDomainLabel = _$DesignMainStrandDomainLabel;

mixin DesignMainStrandDomainLabelPropsMixin on UiProps {
  Domain domain;
  Helix helix;
  Geometry geometry;

  int font_size;
  bool show_dna;
  String transform;
}

class DesignMainStrandDomainLabelProps = UiProps with DesignMainStrandDomainLabelPropsMixin;

class DesignMainStrandDomainLabelsComponent extends UiComponent2<DesignMainStrandDomainLabelProps>
    with PureComponent {
  @override
  render() {
    var label = props.domain.label;
    String label_str;
    if (label is String) {
      label_str = label;
    } else {
      label_str = label.toString();
    }

    Point<num> start_svg = props.helix.svg_base_pos(props.domain.start, props.domain.forward);
    Point<num> end_svg = props.helix.svg_base_pos(props.domain.end - 1, props.domain.forward);
    Point<num> mid_svg = (start_svg + end_svg) * 0.5;

    String baseline = props.domain.forward ? 'baseline' : 'hanging';

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
      ..className = 'domain-label-text')(label_str);
  }
}
