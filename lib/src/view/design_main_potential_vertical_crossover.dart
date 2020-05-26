import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/helix.dart';

import 'package:scadnano/src/state/potential_vertical_crossover.dart';
import '../state/domain.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_potential_vertical_crossover.over_react.g.dart';


UiFactory<DesignMainPotentialVerticalCrossoverProps> DesignMainPotentialVerticalCrossover =
    _$DesignMainPotentialVerticalCrossover;


mixin DesignMainPotentialVerticalCrossoverProps on UiProps {
  PotentialVerticalCrossover potential_vertical_crossover;
  BuiltMap<int, Helix> helices;
}


class DesignMainPotentialVerticalCrossoverComponent
    extends UiComponent2<DesignMainPotentialVerticalCrossoverProps> {
  @override
  render() {
    PotentialVerticalCrossover crossover = props.potential_vertical_crossover;

    Domain prev_substrand = crossover.substrand_top;
    Domain next_substrand = crossover.substrand_bot;
    if (crossover.dna_end_top.is_5p) {
      prev_substrand = crossover.substrand_bot;
      next_substrand = crossover.substrand_top;
    }

    var classname_this_curve = 'potential-vertical-crossover-curve';
    var path = crossover_path_description(prev_substrand, next_substrand, props.helices);
    var color = crossover.color;

    String tooltip = 'click to add a crossover';

    return (Dom.path()
      ..d = path
      ..stroke = color
      ..className = classname_this_curve
      ..onPointerDown = ((ev) {
        if (ev.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
          app.dispatch(actions.JoinStrandsByCrossover(
              dna_end_first_click: crossover.dna_end_top, dna_end_second_click: crossover.dna_end_bot));
        }
      }))(Dom.svgTitle()(tooltip));
  }
}
