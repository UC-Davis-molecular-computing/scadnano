import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';

import '../state/potential_crossover.dart';
import '../app.dart';

part 'potential_crossover_view.over_react.g.dart';

PotentialCrossoverViewProps set_potential_crossover_props(
  PotentialCrossoverViewProps elt,
  PotentialCrossover? potential_crossover,
) {
  return elt
    ..potential_crossover = potential_crossover
    ..id_ = 'potential-crossover-main';
}

UiFactory<PotentialCrossoverViewProps> ConnectedPotentialCrossoverView =
    connect<PotentialCrossover?, PotentialCrossoverViewProps>(
      mapStateToProps:
          (PotentialCrossover? potential_crossover) =>
              set_potential_crossover_props(PotentialCrossoverView(), potential_crossover),
      context: app.context_potential_crossover,
    )(PotentialCrossoverView);

UiFactory<PotentialCrossoverViewProps> PotentialCrossoverView = _$PotentialCrossoverView;

mixin PotentialCrossoverViewProps on UiProps {
  PotentialCrossover? potential_crossover;
  late String id_;
}

class PotentialCrossoverViewComponent extends UiComponent2<PotentialCrossoverViewProps> {
  @override
  render() {
    PotentialCrossover? potential_crossover = props.potential_crossover;
    if (potential_crossover == null) {
      return null;
    }

    return (Dom.line()
      ..x1 = '${potential_crossover.start_point.x}'
      ..y1 = '${potential_crossover.start_point.y}'
      ..x2 = '${potential_crossover.current_point.x}'
      ..y2 = '${potential_crossover.current_point.y}'
      ..className = 'potential-segment'
      ..stroke = potential_crossover.color
      ..id = props.id_)();
  }
}
