import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:built_collection/built_collection.dart';

import '../state/grid.dart';
import 'pure_component.dart';
import 'design_main_helix.dart';
import '../state/helix.dart';

part 'design_main_helices.over_react.g.dart';


UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;


mixin DesignMainHelicesProps on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
  bool strand_create_enabled;
  int design_major_tick_distance;
  bool only_display_selected_helices;
  Grid grid;
  bool helix_change_apply_to_all;
  bool show_dna;
  bool display_base_offsets_of_major_ticks;
  bool display_base_offsets_of_major_ticks_only_first_helix;
}


class DesignMainHelicesComponent extends UiComponent2<DesignMainHelicesProps> with PureComponent {
  @override
  render() {
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool only_display_selected_helices = props.only_display_selected_helices;

    var children = [];
    for (Helix helix in props.helices.values) {
      if (only_display_selected_helices && side_selected_helix_idxs.contains(helix.idx) || !only_display_selected_helices) {
        children.add((DesignMainHelix()
          ..helix = helix
          ..helix_change_apply_to_all = props.helix_change_apply_to_all
          ..strand_create_enabled = props.strand_create_enabled
          ..design_major_tick_distance = props.design_major_tick_distance
          ..grid = props.grid
          ..show_dna = props.show_dna
          ..display_base_offsets_of_major_ticks = props.display_base_offsets_of_major_ticks && (!props.display_base_offsets_of_major_ticks_only_first_helix || helix.view_order == 0)
          ..key = helix.toString())());
      }
    }

    return (Dom.g()..className = 'helices-main-view')(children);
  }
}
