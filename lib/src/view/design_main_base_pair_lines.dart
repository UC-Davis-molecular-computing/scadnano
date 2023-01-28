import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/design.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import 'design_main_warning_star.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_base_pair_lines.over_react.g.dart';

UiFactory<DesignMainBasePairLinesProps> DesignMainBasePairLines = _$DesignMainBasePairLines;

mixin DesignMainBasePairLinesProps on UiProps {
  bool with_mismatches;
  Design design;
  bool only_display_selected_helices;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainBasePairLinesComponent extends UiComponent2<DesignMainBasePairLinesProps> with PureComponent {
  @override
  render() {
    List<ReactElement> base_pair_lines_components = this._create_base_pair_lines_components();
    return (Dom.g()..className = 'base-pair-lines-main-view')(base_pair_lines_components);
  }

  List<ReactElement> _create_base_pair_lines_components() {
    List<ReactElement> base_pair_lines_components = [];
    var base_pairs =
        props.with_mismatches ? props.design.base_pairs_with_mismatches : props.design.base_pairs;

    for (int helix_idx in base_pairs.keys) {
      if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(helix_idx)) {
        var helix = props.design.helices[helix_idx];
        List<ReactElement> helix_components = [];
        for (int offset in base_pairs[helix_idx]) {
          var svg_position_y = props.helix_idx_to_svg_position_y_map[helix_idx];
          var base_svg_forward_pos = helix.svg_base_pos(offset, true, svg_position_y);
          var base_svg_reverse_pos = helix.svg_base_pos(offset, false, svg_position_y);
          var base_pair_line = (Dom.line()
            ..x1 = base_svg_forward_pos.x
            ..y1 = base_svg_forward_pos.y
            ..x2 = base_svg_reverse_pos.x
            ..y2 = base_svg_reverse_pos.y
            ..className = constants.css_selector_base_pair_line
            ..stroke = 'black'
            ..key = 'base-pair-line-H${helix_idx}-${offset}')();
          helix_components.add(base_pair_line);
        }
        HelixGroup group = props.design.groups[helix.group];
        String transform_str = group.transform_str(props.design.geometry);
        var helix_dom_group = (Dom.g()
          ..transform = transform_str
          ..className = 'base-pair-lines-components-in-helix'
          ..key = 'base-pair-lines-components-in-helix-H${helix_idx}')(helix_components);
        base_pair_lines_components.add(helix_dom_group);
      }
    }

    return base_pair_lines_components;
  }
}
