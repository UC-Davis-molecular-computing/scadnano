import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/scadnano.dart';
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
  late bool with_mismatches;
  late Design design;
  late bool only_display_selected_helices;
  late BuiltSet<int> side_selected_helix_idxs;
  late BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainBasePairLinesComponent extends UiComponent2<DesignMainBasePairLinesProps> with PureComponent {
  @override
  render() {
    List<ReactElement> base_pair_lines_components =
        this.create_base_pair_lines_components(app.state.design.strands.toBuiltSet());
    return (Dom.g()..className = 'base-pair-lines-main-view')(base_pair_lines_components);
  }

  List<ReactElement> create_base_pair_lines_components(BuiltSet<Strand> strands) {
    List<ReactElement> base_pair_lines_components = [];
    BuiltMap<int, BuiltList<int>> base_pairs = props.with_mismatches
        ? props.design.selected_base_pairs_with_mismatches(strands, true)
        : props.design.selected_base_pairs(strands, true);

    for (int helix_idx in base_pairs.keys) {
      if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(helix_idx)) {
        var helix = props.design.helices[helix_idx]!;
        HelixGroup group = props.design.groups[helix.group]!;
        var geometry = group.geometry ?? props.design.geometry;
        String transform_str = group.transform_str(geometry);

        // code below draws one line for each base pair, should render somewhat slowly
        // however, this makes it easier to associate base pair lines to individual strands,
        // convenient when exporting SVG
        List<ReactElement> helix_components = [];
        for (int offset in base_pairs[helix_idx]!) {
          var svg_position_y = props.helix_idx_to_svg_position_y_map[helix_idx]!;
          var base_svg_forward_pos = helix.svg_base_pos(offset, true, svg_position_y, geometry);
          var base_svg_reverse_pos = helix.svg_base_pos(offset, false, svg_position_y, geometry);
          var base_pair_line = (Dom.line()
            ..id = 'base_pair-${helix_idx}-${offset}'
            ..x1 = base_svg_forward_pos.x
            ..y1 = base_svg_forward_pos.y
            ..x2 = base_svg_reverse_pos.x
            ..y2 = base_svg_reverse_pos.y
            ..className = constants.css_selector_base_pair_line
            ..stroke = 'black'
            ..key = 'base-pair-line-H${helix_idx}-${offset}')();
          helix_components.add(base_pair_line);
        }
        var helix_dom_group = (Dom.g()
          ..transform = transform_str
          ..className = 'base-pair-lines-components-in-helix'
          ..key = 'base-pair-lines-components-in-helix-H${helix_idx}')(helix_components);
        base_pair_lines_components.add(helix_dom_group);

        // // code below draws one long disconnected path for base pairs in each helix; should render faster
        // // however, it's not clear how to use this when exporting SVG for only some selected strands
        // // since it puts all the base pair lines for the whole helix in one single SVG path
        // var d = StringBuffer();
        // for (int offset in base_pairs[helix_idx]) {
        //   var svg_position_y = props.helix_idx_to_svg_position_y_map[helix_idx];
        //   var base_svg_forward_pos = helix.svg_base_pos(offset, true, svg_position_y);
        //   var base_svg_reverse_pos = helix.svg_base_pos(offset, false, svg_position_y);
        //   d.write(" M ${base_svg_forward_pos.x} ${base_svg_forward_pos.y}"
        //       " L ${base_svg_reverse_pos.x} ${base_svg_reverse_pos.y}");
        // }
        // var helix_lines_path = (Dom.path()
        //   ..d = d.toString()
        //   ..transform = transform_str
        //   ..stroke = 'black'
        //   ..className = constants.css_selector_base_pair_line
        //   ..key = 'base-pair-lines-H${helix_idx}')();
        // base_pair_lines_components.add(helix_lines_path);
      }
    }

    return base_pair_lines_components;
  }
}
