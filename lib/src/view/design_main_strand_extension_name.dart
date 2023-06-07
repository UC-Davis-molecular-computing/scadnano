import 'package:over_react/over_react.dart';

import '../state/geometry.dart';
import '../state/extension.dart';
import 'pure_component.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_strand_extension_name.over_react.g.dart';

UiFactory<DesignMainStrandExtensionNameProps> DesignMainStrandExtensionName = _$DesignMainStrandExtensionName;

mixin DesignMainStrandExtensionNamePropsMixin on UiProps {
  Extension ext;
  Geometry geometry;

  int font_size;
  bool show_dna;
}

class DesignMainStrandExtensionNameProps = UiProps with DesignMainStrandExtensionNamePropsMixin;

class DesignMainStrandExtensionNameComponent extends UiComponent2<DesignMainStrandExtensionNameProps>
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
      ..className = constants.css_selector_extension_name
      ..xlinkHref = '#${props.ext.id}'
      ..startOffset = start_offset
      ..style = style_map);
    var dom = props.ext.adjacent_domain;
    var adj_dom_offset = props.ext.is_5p ? dom.offset_5p : dom.offset_3p;
    return (Dom.text()
      ..key = 'extension-text-H${props.ext.adjacent_domain.helix},${adj_dom_offset}'
      ..dy = '$dy')(text_path_props(props.ext.name));
  }
}
