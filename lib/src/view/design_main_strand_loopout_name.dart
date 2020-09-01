import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import 'pure_component.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_strand_loopout_name.over_react.g.dart';

UiFactory<DesignMainStrandLoopoutNameProps> DesignMainStrandLoopoutName = _$DesignMainStrandLoopoutName;

mixin DesignMainStrandLoopoutNamePropsMixin on UiProps {
  Loopout loopout;
  Geometry geometry;
  Domain prev_domain;
  Domain next_domain;

  int font_size;
  bool show_dna;
}

class DesignMainStrandLoopoutNameProps = UiProps with DesignMainStrandLoopoutNamePropsMixin;

class DesignMainStrandLoopoutNameComponent extends UiComponent2<DesignMainStrandLoopoutNameProps>
    with PureComponent {
  @override
  render() {
    var start_offset = '50%';
    var dy = -0.1 * props.geometry.base_height_svg;
    if (props.show_dna) {
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
      ..className = constants.css_selector_loopout_name
      ..xlinkHref = '#${props.loopout.id()}'
      ..startOffset = start_offset
      ..style = style_map);
    return (Dom.text()
      ..key = 'loopout-text-'
          'H${props.prev_domain.helix},${props.prev_domain.offset_3p}-'
          'H${props.next_domain.helix},${props.next_domain.offset_5p}'
      ..dy = '$dy')(text_path_props(props.loopout.name));
  }
}
