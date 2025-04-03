import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import 'pure_component.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_strand_loopout_name.over_react.g.dart';

UiFactory<DesignMainStrandLoopoutTextProps> DesignMainStrandLoopoutText = _$DesignMainStrandLoopoutText;

mixin DesignMainStrandLoopoutTextProps on UiProps {
  late Loopout loopout;
  late Geometry geometry;
  late Domain prev_domain;
  late Domain next_domain;
  late String text;
  late String css_selector_text;
  late int num_stacked;
  late double font_size;
}

class DesignMainStrandLoopoutTextComponent extends UiComponent2<DesignMainStrandLoopoutTextProps>
    with PureComponent {
  @override
  render() {
    var start_offset = '50%';
    var dy = -0.1 * props.geometry.base_height_svg;
    dy -= props.geometry.base_height_svg * props.num_stacked;

    double letter_spacing = 0.0;
    double font_size = props.font_size;

    Map<String, dynamic> style_map = {'letterSpacing': '${letter_spacing}em', 'fontSize': '${font_size}px'};

    SvgProps text_path_props =
        (Dom.textPath()
          ..className = props.css_selector_text
          ..xlinkHref = '#${props.loopout.id}'
          ..startOffset = start_offset
          ..style = style_map);
    return (Dom.text()
      ..key =
          'loopout-text-'
          'H${props.prev_domain.helix},${props.prev_domain.offset_3p}-'
          'H${props.next_domain.helix},${props.next_domain.offset_5p}'
      ..dy = '$dy')(text_path_props(props.text));
  }
}
