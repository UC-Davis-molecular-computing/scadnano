import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/group.dart';
import '../state/substrand.dart';
import '../state/loopout.dart';
import '../state/extension.dart';
import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/helix.dart';
import '../util.dart';

import '../state/strand.dart';
import 'design_main_loopout_extension_length.dart';
import 'pure_component.dart';
import '../constants.dart' as constants;
import 'design_main_dna_sequence.dart';

part 'design_main_loopout_extension_lengths.over_react.g.dart';

UiFactory<DesignMainLoopoutExtensionLengthsProps> DesignMainLoopoutExtensionLengths =
    _$DesignMainLoopoutExtensionLengths;

mixin DesignMainLoopoutExtensionLengthsProps on UiProps {
  late Geometry geometry;
  late BuiltList<Strand> strands;
  late bool show_length;
}

class DesignMainLoopoutExtensionLengthsComponent extends UiComponent2<DesignMainLoopoutExtensionLengthsProps>
    with PureComponent {
  @override
  render() {
    if (props.show_length) {
      var elts = [];
      int idx = 0;
      for (Strand strand in props.strands)
        for (Substrand substrand in strand.substrands)
          if (substrand is Loopout || substrand is Extension) {
            elts.add((DesignMainLoopoutExtensionLength()
              ..geometry = props.geometry
              ..substrand = substrand
              ..key = "${idx++}"
              ..className = 'loopout-extension-length-elts')());
          }
      return (Dom.g()..className = 'loopout-extension-lengths-main-view')(elts);
    }
  }
}
