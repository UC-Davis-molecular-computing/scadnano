import 'package:over_react/over_react.dart';
import 'package:platform_detect/platform_detect.dart';

import '../constants.dart' as constants;
import 'package:scadnano/src/state/geometry.dart';
import '../state/loopout.dart';
import 'pure_component.dart';

part 'design_main_loopout_length.over_react.g.dart';

UiFactory<DesignMainLoopoutLengthProps> DesignMainLoopoutLength = _$DesignMainLoopoutLength;

mixin DesignMainLoopoutLengthPropsMixin on UiProps {
  Geometry geometry;
  Loopout loopout;
}

class DesignMainLoopoutLengthProps = UiProps with DesignMainLoopoutLengthPropsMixin;

class DesignMainLoopoutLengthComponent extends UiComponent2<DesignMainLoopoutLengthProps> with PureComponent {
  @override
  render() {
    List<ReactElement> loopout_length_elts = [];
    loopout_length_elts.add(this._loopout_length());
    return (Dom.g()..className = 'strand-loopout-length')(loopout_length_elts);
  }

  ReactElement _loopout_length() {
    var start_offset = '50%';
    var translate_x = '${0}';

    if (browser.isFirefox) {
      //dominant-baseline does not align normally on Firefox
      translate_x = '${props.geometry.base_height_svg / 2}';
    }
    
    Map<String, dynamic> style_map = {'fontSize': '${9}px'};
    var loopout_length = props.loopout.loopout_length.toString().split('').reversed.join('');

    SvgProps text_path_props = (Dom.textPath()
      ..className = constants.css_selector_loopout_length
      ..xlinkHref = '#${props.loopout.id()}'
      ..startOffset = start_offset
      ..style = style_map);
    return (Dom.text()
      ..transform = 'translate(${0}, ${translate_x})'
      ..rotate = 180
      ..key = props.loopout.id())(text_path_props(loopout_length));
  }
}
