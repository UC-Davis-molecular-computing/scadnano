import 'package:over_react/over_react.dart';
import 'package:platform_detect/platform_detect.dart';

import '../constants.dart' as constants;
import 'package:scadnano/src/state/geometry.dart';
import '../state/loopout.dart';
import 'pure_component.dart';

part 'design_main_loopout_length.over_react.g.dart';

UiFactory<DesignMainLoopoutProps> DesignMainLoopout = _$DesignMainLoopout;

mixin DesignMainLoopoutPropsMixin on UiProps {
  Geometry geometry;
  Loopout loopout;
}

class DesignMainLoopoutProps = UiProps with DesignMainLoopoutPropsMixin;

class DesignMainLoopoutComponent extends UiComponent2<DesignMainLoopoutProps> with PureComponent {
  @override
  render() {
    List<ReactElement> loopout_length_elts = [];
    loopout_length_elts.add(this._loopout_length());
    return (Dom.g()..className = 'strand-loopout-length')(loopout_length_elts);
  }

  ReactElement _loopout_length() {
    var start_offset = '50%';
    var dx = '${0}';

    if(browser.isFirefox){
      dx = '${0.55 * props.geometry.base_height_svg}';
    }
    
    Map<String, dynamic> style_map = {'fontSize': '${9}px'};
    var loopout_length = props.loopout.loopout_length.toString().split('').reversed.join('');

    SvgProps text_path_props = (Dom.textPath()
      ..className = constants.css_selector_loopout_length
      ..xlinkHref = '#${props.loopout.id()}'
      ..startOffset = start_offset
      ..style = style_map);
    return (Dom.text()
      ..rotate = 180
      ..key = props.loopout.id()
      ..dx = dx)(text_path_props(loopout_length));
  }
}
