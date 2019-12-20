
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';

import 'package:scadnano/src/state/potential_crossover.dart';
import '../app.dart';

part 'potential_crossover_view.over_react.g.dart';

UiFactory<PotentialCrossoverViewProps> ConnectedPotentialCrossoverView =
    connect<PotentialCrossover, PotentialCrossoverViewProps>(
  mapStateToProps: (potential_crossover) {
    return PotentialCrossoverView()..potential_crossover = potential_crossover;
  },
  context: app.context_potential_crossover,
)(PotentialCrossoverView);

@Factory()
UiFactory<PotentialCrossoverViewProps> PotentialCrossoverView = _$PotentialCrossoverView;

@Props()
class _$PotentialCrossoverViewProps extends UiProps {
  PotentialCrossover potential_crossover;
  String id;
}

@Component2()
class PotentialCrossoverViewComponent extends UiComponent2<PotentialCrossoverViewProps> {
  @override
  render() {
    PotentialCrossover potential_crossover = props.potential_crossover;
    if (potential_crossover == null) {
      return null;
    }

    return (Dom.line()
      ..x1 = '${potential_crossover.start_point.x}'
      ..y1 = '${potential_crossover.start_point.y}'
      ..x2 = '${potential_crossover.current_point.x}'
      ..y2 = '${potential_crossover.current_point.y}'
      ..className = 'potential-crossover'
      ..stroke = potential_crossover.color
      ..id = props.id)();
  }
}
