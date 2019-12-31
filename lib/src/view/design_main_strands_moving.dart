import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/strands_move.dart';

import '../state/app_state.dart';
import '../state/strand.dart';
import 'design_main_strand_moving.dart';

part 'design_main_strands_moving.over_react.g.dart';

UiFactory<DesignMainStrandsMovingProps> ConnectedDesignMainStrandsMoving =
    connect<AppState, DesignMainStrandsMovingProps>(mapStateToProps: (state) {
  return DesignMainStrandsMoving()
    ..strands_move = state.ui_state.strands_move
    ..helices = state.dna_design.helices
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs;
})(DesignMainStrandsMoving);

@Factory()
UiFactory<DesignMainStrandsMovingProps> DesignMainStrandsMoving = _$DesignMainStrandsMoving;

@Props()
class _$DesignMainStrandsMovingProps extends UiProps {
  StrandsMove strands_move;
  BuiltList<Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
}

@Component2()
class DesignMainStrandsMovingComponent extends UiComponent2<DesignMainStrandsMovingProps> {
  @override
  render() {
    if (props.strands_move == null) {
      return null;
    }
    return (Dom.g()
      ..className = 'strands-moving-main-view' + (props.strands_move.allowable ? '' : ' disallowed'))([
      for (var strand in props.strands_move.strands_moving)
        (DesignMainStrandMoving()
          ..strand = strand
          ..delta = props.strands_move.delta
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..helices = props.helices
          ..allowable = props.strands_move.allowable
          ..key = strand.toString())()
    ]);
  }
}
