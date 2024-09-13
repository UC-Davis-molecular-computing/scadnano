import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/extension.dart';
import 'pure_component.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_strand_extension_text.over_react.g.dart';

UiFactory<DesignMainStrandExtensionTextProps> DesignMainStrandExtensionText = _$DesignMainStrandExtensionText;

mixin DesignMainStrandExtensionTextProps on UiProps {
  late Extension ext;
  late Geometry geometry;
  late String text;
  late String css_selector_text;
  late int num_stacked;

  late double font_size;
}

class DesignMainStrandExtensionTextComponent extends UiComponent2<DesignMainStrandExtensionTextProps>
    with PureComponent {
  @override
  render() {
    var start_offset = '50%';
    var dy = -0.1 * props.geometry.base_height_svg;
    dy -= props.geometry.base_height_svg * props.num_stacked;

    double letter_spacing = 0.0;
    double font_size = props.font_size;

    Map<String, dynamic> style_map = {'letterSpacing': '${letter_spacing}em', 'fontSize': '${font_size}px'};

    SvgProps text_path_props = (Dom.textPath()
      ..className = props.css_selector_text
      ..xlinkHref = '#${props.ext.id}'
      ..startOffset = start_offset
      ..style = style_map);
    var dom = props.ext.adjacent_domain;
    var adj_dom_offset = props.ext.is_5p ? dom.offset_5p : dom.offset_3p;
    return (Dom.text()
      ..key = 'extension-text-H${props.ext.adjacent_domain.helix},${adj_dom_offset}'
      ..dy = '$dy')(text_path_props(props.text));
  }
}
