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

part 'design_main_base_pair_rectangle.over_react.g.dart';

UiFactory<DesignMainBasePairRectangleProps> DesignMainBasePairRectangle = _$DesignMainBasePairRectangle;

mixin DesignMainBasePairRectangleProps on UiProps {
  late bool with_mismatches;
  late Design design;
  late bool only_display_selected_helices;
  late BuiltSet<int> side_selected_helix_idxs;
  late BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainBasePairRectangleComponent extends UiComponent2<DesignMainBasePairRectangleProps>
    with PureComponent {
  @override
  render() {
    List<ReactElement> base_pair_lines_components = this.create_base_pair_lines_components(
      app.state.design.strands.toBuiltSet(),
    );
    return (Dom.g()..className = 'base-pair-lines-main-view')(base_pair_lines_components);
  }

  List<ReactElement> create_base_pair_lines_components(BuiltSet<Strand> strands) {
    List<ReactElement> base_pair_lines_components = [];
    BuiltMap<int, BuiltList<int>> base_pairs =
        props.with_mismatches
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
        int last_offset = -2;
        var last_svg_forward_pos = null;
        for (int offset in base_pairs[helix_idx]!) {
          var svg_position_y = props.helix_idx_to_svg_position_y_map[helix_idx]!;
          var base_svg_forward_pos = helix.svg_base_pos(offset, true, svg_position_y, geometry);
          var base_svg_reverse_pos = helix.svg_base_pos(offset, false, svg_position_y, geometry);

          var base_pair_ele = null;

          if (offset - last_offset == 1) {
            base_pair_ele =
                (Dom.rect()
                  ..id = 'base_pair-${helix_idx}-${offset}'
                  ..x = last_svg_forward_pos.x - 0.5
                  ..y = base_svg_forward_pos.y
                  ..width = base_svg_reverse_pos.x - last_svg_forward_pos.x + 0.8
                  ..height = base_svg_reverse_pos.y - base_svg_forward_pos.y
                  ..className = constants.css_selector_base_pair_rect
                  ..fill = 'grey'
                  ..key = 'base-pair-rect-H${helix_idx}-${offset}')();
          } else {
            base_pair_ele =
                (Dom.line()
                  ..id = 'base_pair-${helix_idx}-${offset}'
                  ..x1 = base_svg_forward_pos.x
                  ..y1 = base_svg_forward_pos.y
                  ..x2 = base_svg_reverse_pos.x
                  ..y2 = base_svg_reverse_pos.y
                  ..className = constants.css_selector_base_pair_line
                  ..stroke = 'grey'
                  ..key = 'base-pair-line-H${helix_idx}-${offset}')();
          }

          helix_components.add(base_pair_ele);
          last_offset = offset;
          last_svg_forward_pos = base_svg_forward_pos;
        }
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
