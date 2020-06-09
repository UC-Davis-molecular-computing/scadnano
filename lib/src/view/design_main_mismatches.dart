import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/dna_design.dart';
import '../app.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'design_main_mismatch.dart';
import 'pure_component.dart';

part 'design_main_mismatches.over_react.g.dart';

UiFactory<DesignMainMismatchesProps> DesignMainMismatches = _$DesignMainMismatches;

mixin DesignMainMismatchesProps on UiProps {
  DNADesign dna_design;
}

class DesignMainMismatchesComponent extends UiComponent2<DesignMainMismatchesProps> with PureComponent {
  @override
  render() {
    List<ReactElement> mismatch_components = this._create_mismatch_components(props.dna_design);
    return (Dom.g()..className = 'mismatches-main-view')(mismatch_components);
  }

  List<ReactElement> _create_mismatch_components(DNADesign dna_design) {
    List<ReactElement> mismatch_components = [];
    Set<String> keys = {};
    for (Strand strand in dna_design.strands) {
      for (Domain substrand in strand.domains()) {
        BuiltList<Mismatch> mismatches = dna_design.mismatches_on_substrand(substrand);
        for (Mismatch mismatch in mismatches) {
          //FIXME: don't access global variable; make this a connected component and used a memoized selector
          var helix = app.state.dna_design.helices[substrand.helix];
          var base_svg_pos = helix.svg_base_pos(mismatch.offset, substrand.forward);
          // For now, if there is a mismatch in an insertion we simply display it for the whole insertion,
          // not for a specific base. We maintain React keys to agree on any mismatches in the same
          // insertion, and we only render one of them.
          String key = '${base_svg_pos};${substrand.forward}';
          if (!keys.contains(key)) {
            // otherwise, already rendered mismatch for this insertion
            keys.add(key);
            var mismatch_component = (DesignMainMismatch()
              ..key = key
              ..base_svg_pos = base_svg_pos
              ..forward = substrand.forward)();
            mismatch_components.add(mismatch_component);
          }
        }
      }
    }
    return mismatch_components;
  }
}
