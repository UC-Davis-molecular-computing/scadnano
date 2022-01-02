import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:built_collection/built_collection.dart';

import '../state/group.dart';
import '../state/geometry.dart';
import 'design_main_helix.dart';
import '../state/helix.dart';
import 'pure_component.dart';
import '../extension_methods.dart';

part 'design_main_helices.over_react.g.dart';

UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;

mixin DesignMainHelicesProps on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltMap<String, BuiltList<int>> helix_idxs_in_group;
  BuiltMap<String, HelixGroup> groups;
  BuiltSet<int> side_selected_helix_idxs;
  num major_tick_offset_font_size;
  num major_tick_width_font_size;
  bool only_display_selected_helices;
  bool helix_change_apply_to_all;
  bool show_dna;
  bool show_domain_labels;
  bool display_base_offsets_of_major_ticks;
  bool display_base_offsets_of_major_ticks_only_first_helix;
  bool display_major_tick_widths;
  bool display_major_tick_widths_all_helices;
  Geometry geometry;
  bool show_helix_circles;
  BuiltMap<int, Point<num>> helix_idx_to_svg_position_map;
}

class DesignMainHelicesComponent extends UiComponent2<DesignMainHelicesProps> with PureComponent {
  @override
  render() {
    if (props.helices.isEmpty) {
      return null;
    }
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool only_display_selected_helices = props.only_display_selected_helices;

    var group_views = [];
    for (var group_name in props.groups.keys) {
      var group = props.groups[group_name];
      var helix_idxs_in_group = props.helix_idxs_in_group[group_name];

      if (helix_idxs_in_group.isEmpty) {
        continue;
      }

      int min_helix_idx = helix_idxs_in_group.min;
      bool invert_y = props.helices[min_helix_idx].invert_y;
      int first_helix_view_order = invert_y ? helix_idxs_in_group.length - 1 : 0;

      var children = [];
      for (int helix_idx in helix_idxs_in_group) {
        var helix = props.helices[helix_idx];
        var group = props.groups[helix.group];
        int view_order = group.helices_view_order_inverse[helix.idx];

        if (only_display_selected_helices && side_selected_helix_idxs.contains(helix.idx) ||
            !only_display_selected_helices) {
          children.add((DesignMainHelix()
            ..helix = helix
            ..selected = side_selected_helix_idxs.contains(helix.idx)
            ..major_tick_offset_font_size = props.major_tick_offset_font_size
            ..major_tick_width_font_size = props.major_tick_width_font_size
            ..helix_change_apply_to_all = props.helix_change_apply_to_all
            ..show_dna = props.show_dna
            ..show_domain_labels = props.show_domain_labels
            ..show_helix_circles = props.show_helix_circles
            ..display_base_offsets_of_major_ticks = props.display_base_offsets_of_major_ticks &&
                (!props.display_base_offsets_of_major_ticks_only_first_helix ||
                    view_order == first_helix_view_order)
            ..display_major_tick_widths = props.display_major_tick_widths &&
                (props.display_major_tick_widths_all_helices || view_order == first_helix_view_order)
            ..key = helix.idx.toString()
            ..helix_svg_position = props.helix_idx_to_svg_position_map[helix.idx])());
        }
      }

      group_views.add((Dom.g()
        ..className = 'helices-main-view-group-${group_name}'
        ..transform = group.transform_str(props.geometry)
        ..key = '${group_name}')(children));
    }

    return (Dom.g()..className = 'helices-main-view')(group_views);
  }
}
