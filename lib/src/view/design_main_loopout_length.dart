import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/view/design_main_strand_loopout.dart';
import 'package:scadnano/src/view/transform_by_helix_group.dart';
import 'package:tuple/tuple.dart';
import '../constants.dart' as constants;

import '../state/helix.dart';
import 'package:scadnano/src/state/geometry.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import 'pure_component.dart';
import '../util.dart' as util;

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
    loopout_length_elts.add(this._loopout_length(props.loopout));
    return (Dom.g()..className = 'strand-loopout-length')(loopout_length_elts);
  }

  ReactElement _loopout_length(Loopout loopout) {
    var start_offset = '50%';
    var dy = '${0.1 * props.geometry.base_width_svg}';

    Map<String, dynamic> style_map = {'fontSize': '${9}px'};
    var loopout_length = loopout.loopout_length.toString().split('').reversed.join('');

    SvgProps text_path_props = (Dom.textPath()
      ..className = constants.css_selector_loopout_length
      ..xlinkHref = '#${loopout.id()}'
      ..startOffset = start_offset
      ..style = style_map);
    return (Dom.text()
      ..rotate = 180
      ..key = 'loopout-length-'
          'H${loopout.id()},'
      ..dy = dy)(text_path_props(loopout_length));
  }
}
