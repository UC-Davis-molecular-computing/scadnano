import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/potential_vertical_crossover.dart';
import 'design_main_potential_vertical_crossover.dart';

part 'design_main_potential_vertical_crossovers.over_react.g.dart';


UiFactory<DesignMainPotentialVerticalCrossoversProps> DesignMainPotentialVerticalCrossovers =
    _$DesignMainPotentialVerticalCrossovers;


mixin DesignMainPotentialVerticalCrossoversProps on UiProps {
  BuiltList<PotentialVerticalCrossover> potential_vertical_crossovers;
  BuiltMap<int, Helix> helices;
  Geometry geometry;
}


class DesignMainPotentialVerticalCrossoversComponent
    extends UiComponent2<DesignMainPotentialVerticalCrossoversProps> {
  @override
  render() {
    return (Dom.g()..className = 'potential-vertical-crossovers')([
      for (var potential_vertical_crossover in props.potential_vertical_crossovers)
        (DesignMainPotentialVerticalCrossover()
          ..potential_vertical_crossover = potential_vertical_crossover
          ..helices=props.helices
          ..geometry = props.geometry
          ..key = potential_vertical_crossover.dna_end_top.id())()
    ]);
  }
}
