import 'dart:math';

import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/dna_extensions_move.dart';

import '../app.dart';

import '../util.dart' as util;

part 'potential_extensions_view.over_react.g.dart';

UiFactory<PotentialExtensionsViewProps> ConnectedPotentialExtensionsView =
    connect<DNAExtensionsMove?, PotentialExtensionsViewProps>(
      mapStateToPropsWithOwnProps: (
        DNAExtensionsMove? potential_extensions,
        PotentialExtensionsViewProps props,
      ) {
        return PotentialExtensionsView()
          ..potential_extensions = potential_extensions
          ..id_ = props.id_;
      },
      context: app.context_extensions_move,
    )(PotentialExtensionsView);

UiFactory<PotentialExtensionsViewProps> PotentialExtensionsView = _$PotentialExtensionsView;

mixin PotentialExtensionsViewProps on UiProps {
  DNAExtensionsMove? potential_extensions;
  String? id_;
}

class PotentialExtensionsViewComponent extends UiComponent2<PotentialExtensionsViewProps> {
  @override
  render() {
    DNAExtensionsMove? potential_extensions = props.potential_extensions;
    if (potential_extensions == null) {
      return null;
    }

    // potential_extensions.moves.map returns an iterable. Need to be casted into a Dom object.
    // Similar issue as #655
    return (Dom.g())(
      potential_extensions.moves.map(
        (move) =>
            (Dom.line()
              ..x1 = '${move.attached_end_position.x}'
              ..y1 = '${move.attached_end_position.y}'
              ..x2 = '${potential_extensions.current_point_of(move.dna_end)!.x}'
              ..y2 = '${potential_extensions.current_point_of(move.dna_end)!.y}'
              ..className = 'potential-segment'
              ..stroke = move.color.toHexColor().toCssString()
              ..key = '${props.id_}-${move.dna_end.id}'
              ..id = '${props.id_}-${move.dna_end.id}')(),
      ),
    );
  }
}
