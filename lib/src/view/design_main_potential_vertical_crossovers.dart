import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/group.dart';

import '../state/geometry.dart';
import '../state/helix.dart';
import '../state/potential_vertical_crossover.dart';
import 'design_main_potential_vertical_crossover.dart';

part 'design_main_potential_vertical_crossovers.over_react.g.dart';

UiFactory<DesignMainPotentialVerticalCrossoversProps> DesignMainPotentialVerticalCrossovers =
    _$DesignMainPotentialVerticalCrossovers;

mixin DesignMainPotentialVerticalCrossoversProps on UiProps {
  late BuiltList<PotentialVerticalCrossover> potential_vertical_crossovers;

  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late Geometry geometry;

  late bool only_display_selected_helices;
  late BuiltSet<int> side_selected_helix_idxs;
  late BuiltMap<int, double> helix_idx_to_svg_position_y_map;
}

class DesignMainPotentialVerticalCrossoversComponent
    extends UiComponent2<DesignMainPotentialVerticalCrossoversProps> {
  @override
  render() {
    List<ReactElement> crossover_components = [];
    for (var potential_vertical_crossover in props.potential_vertical_crossovers) {
      // pick out only helices and group we need for this component
      int idx_top = potential_vertical_crossover.helix_idx_top;
      int idx_bot = potential_vertical_crossover.helix_idx_bot;

      // skip if either helix is not being displayed
      if (props.only_display_selected_helices &&
          !props.side_selected_helix_idxs.containsAll([idx_bot, idx_top])) {
        continue;
      }
      BuiltMap<int, Helix> helices_of_crossover =
          (props.helices.toMap()..removeWhere((idx, _) => !(idx == idx_top || idx == idx_bot))).build();
      var group_top_name = helices_of_crossover[idx_top]!.group;
      var group_bot_name = helices_of_crossover[idx_bot]!.group;

      // we only render if both helices are in same group
      if (group_top_name == group_bot_name) {
        var group_top = props.groups[group_top_name]!;
        var geometry = group_top.geometry ?? props.geometry;
        BuiltMap<String, HelixGroup> groups_of_crossover =
            {group_bot_name: props.groups[group_bot_name]!}.build();
        crossover_components.add((DesignMainPotentialVerticalCrossover()
          ..potential_vertical_crossover = potential_vertical_crossover
          ..helices = helices_of_crossover
          ..groups = groups_of_crossover
          ..geometry = geometry
          ..helix_idx_to_svg_position_y_map = props.helix_idx_to_svg_position_y_map
          ..key = potential_vertical_crossover.dna_end_top.id)());
      }
    }
    return (Dom.g()..className = 'potential-vertical-crossovers')(crossover_components);
  }
}
