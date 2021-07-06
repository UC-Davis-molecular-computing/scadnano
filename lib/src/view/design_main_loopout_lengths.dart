import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/loopout.dart';
import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/helix.dart';
import '../util.dart';

import '../state/strand.dart';
import 'design_main_loopout_length.dart';
import 'pure_component.dart';
import '../constants.dart' as constants;
import 'design_main_dna_sequence.dart';

part 'design_main_loopout_lengths.over_react.g.dart';

UiFactory<DesignMainLoopoutLengthsProps> DesignMainLoopoutLengths = _$DesignMainLoopoutLengths;

mixin DesignMainLoopoutLengthsProps on UiProps {
  Geometry geometry;
  BuiltList<Strand> strands;
  bool show_loopout_length;
}

class DesignMainLoopoutLengthsComponent extends UiComponent2<DesignMainLoopoutLengthsProps>
    with PureComponent {
  @override
  render() {
    if (props.show_loopout_length) {
      return (Dom.g()..className = 'loopout-length-main-view')([
        for (Strand strand in props.strands)
          for (Loopout loopout in strand.loopouts)
            (DesignMainLoopout()
              ..geometry = props.geometry
              ..key = loopout.toString()
              ..loopout = loopout
              ..className = 'strand-loopout-length-elts')()
      ]);
    }
  }
}
