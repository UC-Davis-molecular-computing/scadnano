import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';

import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/design.dart';
import '../state/geometry.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import 'design_main_mismatch.dart';
import '../util.dart' as util;

part 'design_main_slice_bar.over_react.g.dart';

UiFactory<DesignMainSliceBarProps> DesignMainSliceBar = _$DesignMainSliceBar;

mixin DesignMainSliceBarProps on UiProps {
  int slice_bar_offset;
  String displayed_group_name;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltMap<String, HelixGroup> groups;
  BuiltMap<String, BuiltList<int>> helix_idxs_in_group;
  BuiltMap<int, Helix> helices;
  bool only_display_selected_helices;
  Geometry geometry;
}

class DesignMainSliceBarComponent extends UiComponent2<DesignMainSliceBarProps> with PureComponent {
  @override
  render() {
    int number_of_displayed_helices_in_displayed_group = 0;
    var helix_idxs_in_group = props.helix_idxs_in_group[props.displayed_group_name];
    for (int helix_idx in helix_idxs_in_group) {
      var helix = props.helices[helix_idx];
      var side_selected_helix_idxs = props.side_selected_helix_idxs;

      bool only_display_selected_helices = props.only_display_selected_helices;
      if (only_display_selected_helices && side_selected_helix_idxs.contains(helix.idx) ||
          !only_display_selected_helices) {
        number_of_displayed_helices_in_displayed_group += 1;
      }
    }
    // Add slicebar if needed
    var geometry = props.geometry;
    var width = geometry.base_width_svg;
    var height = geometry.helix_diameter_svg * number_of_displayed_helices_in_displayed_group +
        geometry.nm_to_svg_pixels *
            geometry.inter_helix_gap *
            (number_of_displayed_helices_in_displayed_group - 1);
    var helix = props.helices[helix_idxs_in_group.first];
    var pos = helix.svg_base_pos(props.slice_bar_offset, true);

    var x = pos.x - geometry.base_width_svg / 2;
    var y = -geometry.inter_helix_gap * geometry.nm_to_svg_pixels / 2;

    var slice_bar = (Dom.rect()
      ..onPointerDown = (_) {
        app.dispatch(actions.SliceBarMoveStart());
      }
      ..width = width
      ..height = height
      ..x = x
      ..y = y)();

    var offset_text = (Dom.text()
      ..x = pos.x
      ..y = y - 5)(props.slice_bar_offset);

    return ((Dom.g()
      ..className = 'slice-bar-rect'
      ..transform = props.groups[props.displayed_group_name].transform_str(props.geometry)
      ..key = 'slice-bar')(slice_bar, offset_text));
  }
}
