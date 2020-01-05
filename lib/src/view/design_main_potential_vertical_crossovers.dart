import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';

import '../state/potential_vertical_crossover.dart';
import 'design_main_potential_vertical_crossover.dart';

part 'design_main_potential_vertical_crossovers.over_react.g.dart';

@Factory()
UiFactory<DesignMainPotentialVerticalCrossoversProps> DesignMainPotentialVerticalCrossovers =
    _$DesignMainPotentialVerticalCrossovers;

@Props()
class _$DesignMainPotentialVerticalCrossoversProps extends UiProps {
  BuiltList<PotentialVerticalCrossover> potential_vertical_crossovers;
}

@Component2()
class DesignMainPotentialVerticalCrossoversComponent
    extends UiComponent2<DesignMainPotentialVerticalCrossoversProps> {
  @override
  render() {
    return (Dom.g()..className = 'potential-vertical-crossovers')([
      for (var potential_vertical_crossover in props.potential_vertical_crossovers)
        (DesignMainPotentialVerticalCrossover()
          ..potential_vertical_crossover = potential_vertical_crossover
          ..key = potential_vertical_crossover.dna_end_top.id())()
    ]);
  }
}
