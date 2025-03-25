import 'package:over_react/over_react.dart';

import '../constants.dart' as constants;
import 'package:scadnano/src/state/geometry.dart';
import '../state/substrand.dart';
import '../state/loopout.dart';
import '../state/extension.dart';
import 'pure_component.dart';

part 'design_main_loopout_extension_length.over_react.g.dart';

UiFactory<DesignMainLoopoutExtensionLengthProps> DesignMainLoopoutExtensionLength =
    _$DesignMainLoopoutExtensionLength;

mixin DesignMainLoopoutExtensionLengthProps on UiProps {
  late Geometry geometry;
  late Substrand substrand;
}

class DesignMainLoopoutExtensionLengthComponent extends UiComponent2<DesignMainLoopoutExtensionLengthProps>
    with PureComponent {
  @override
  render() {
    List<ReactElement> length_elts = [];
    length_elts.add(this._length());
    return (Dom.g()..className = 'loopout-extension-length')(length_elts);
  }

  ReactElement _length() {
    var start_offset = '50%';
    var dy = '${0.1 * props.geometry.base_width_svg}';

    Map<String, dynamic> style_map = {'fontSize': '${9}px'};
    String length = props.substrand.dna_length().toString();

    SvgProps text_path_props = (Dom.textPath()
      ..className = constants.css_selector_loopout_extension_length
      ..xlinkHref = '#${props.substrand.id}'
      ..startOffset = start_offset
      ..style = style_map);
    return (Dom.text()
      ..key = props.substrand.id
      ..dy = dy)(text_path_props(length));
  }
}
