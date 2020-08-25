import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import 'pure_component.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_strand_loopout_label.over_react.g.dart';

UiFactory<DesignMainStrandLoopoutLabelProps> DesignMainStrandLoopoutLabel = _$DesignMainStrandLoopoutLabel;

mixin DesignMainStrandLoopoutLabelPropsMixin on UiProps {
  Loopout loopout;
  Geometry geometry;
  Domain prev_domain;
  Domain next_domain;

  int font_size;
  bool show_dna;
}

class DesignMainStrandLoopoutLabelProps = UiProps with DesignMainStrandLoopoutLabelPropsMixin;

class DesignMainStrandLoopoutLabelsComponent extends UiComponent2<DesignMainStrandLoopoutLabelProps>
    with PureComponent {
  @override
  render() {
    var label = props.loopout.label;
    String label_str;
    if (label is String) {
      label_str = label;
    } else {
      label_str = label.toString();
    }

    var start_offset = '50%';
    var dy = -0.1 * props.geometry.base_height_svg;
    if (props.show_dna){
      dy -= props.geometry.base_height_svg;
    }

    num letter_spacing = 0.0;
    num font_size = props.font_size;

    Map<String, dynamic> style_map;
    if (letter_spacing != null) {
      style_map = {'letterSpacing': '${letter_spacing}em', 'fontSize': '${font_size}px'};
    } else {
      style_map = {'fontSize': '${font_size}px'};
    }

    SvgProps text_path_props = (Dom.textPath()
      ..className = constants.css_selector_loopout_label
      ..xlinkHref = '#${props.loopout.id()}'
      ..startOffset = start_offset
      ..style = style_map);
    return (Dom.text()
      ..key = 'loopout-text-'
          'H${props.prev_domain.helix},${props.prev_domain.offset_3p}-'
          'H${props.next_domain.helix},${props.next_domain.offset_5p}'
      ..dy = '$dy')(text_path_props(label_str));

    //BELOW HERE is Domain label code
    // num offset_of_dna = props.show_dna ? props.helix.geometry.base_height_svg : 0;
    // var dy = props.geometry.base_height_svg * 0.7 + offset_of_dna;
    // if (props.domain.forward) {
    //   dy = -dy;
    // }
    //
    // return (Dom.text()
    //   ..x = '${mid_svg.x}'
    //   ..y = '${mid_svg.y}'
    //   ..dy = '${dy}'
    //   ..fontSize = props.font_size
    //   ..dominantBaseline = baseline
    //   ..className = 'domain-label-text')(label_str);
  }
}
