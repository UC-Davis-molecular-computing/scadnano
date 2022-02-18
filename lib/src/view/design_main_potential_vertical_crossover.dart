import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';


import '../state/group.dart';
import 'pure_component.dart';
import 'transform_by_helix_group.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import 'design_main_strand_paths.dart';
import '../state/potential_vertical_crossover.dart';
import '../state/domain.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_potential_vertical_crossover.over_react.g.dart';

UiFactory<DesignMainPotentialVerticalCrossoverProps> DesignMainPotentialVerticalCrossover =
    _$DesignMainPotentialVerticalCrossover;

mixin DesignMainPotentialVerticalCrossoverPropsMixin on UiProps {
  PotentialVerticalCrossover potential_vertical_crossover;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;
  BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainPotentialVerticalCrossoverProps = UiProps
    with DesignMainPotentialVerticalCrossoverPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainPotentialVerticalCrossoverComponent
    extends UiComponent2<DesignMainPotentialVerticalCrossoverProps>
    with PureComponent, TransformByHelixGroup<DesignMainPotentialVerticalCrossoverProps> {
  @override
  render() {
    PotentialVerticalCrossover crossover = props.potential_vertical_crossover;

    Domain prev_domain = crossover.domain_top;
    Domain next_domain = crossover.domain_bot;
    if (crossover.dna_end_top.is_5p) {
      prev_domain = crossover.domain_bot;
      next_domain = crossover.domain_top;
    }

    var prev_group = props.helices[prev_domain.helix].group;
    var next_group = props.helices[next_domain.helix].group;
    bool within_group = prev_group == next_group;
    if (!within_group) {
      // don't render these unless both helices are in the same group
      return null;
    }

    var classname_this_curve = 'potential-vertical-crossover-curve';
    var path = crossover_path_description_within_group(
        prev_domain, next_domain, props.helices, props.geometry, props.helix_idx_to_svg_position_y_map[prev_domain.helix], props.helix_idx_to_svg_position_y_map[next_domain.helix]);
    var color = crossover.color;

    String tooltip = 'click to add a crossover';

    var path_props = Dom.path()
      ..d = path
      ..stroke = color
      ..className = classname_this_curve
      ..transform = transform_of_helix(prev_domain.helix)
      ..onPointerDown = ((ev) {
        if (ev.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
          app.dispatch(actions.JoinStrandsByCrossover(
              dna_end_first_click: crossover.dna_end_top, dna_end_second_click: crossover.dna_end_bot));
        }
      });

    return path_props(Dom.svgTitle()(tooltip));
  }
}
