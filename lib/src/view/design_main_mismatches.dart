import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

import '../state/dna_design.dart';
import '../app.dart';
import '../state/strand.dart';
import '../state/bound_substrand.dart';
import 'design_main_mismatch.dart';

part 'design_main_mismatches.over_react.g.dart';

@Factory()
UiFactory<DesignMainMismatchesProps> DesignMainMismatches = _$DesignMainMismatches;

@Props()
class _$DesignMainMismatchesProps extends UiProps {
  bool show_mismatches;
  BuiltList<Strand> strands;
}

@Component2()
class DesignMainMismatchesComponent extends UiComponent2<DesignMainMismatchesProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    bool show_mismatches = nextProps['DesignMainMismatchesProps.show_mismatches'];
    if (!show_mismatches && !props.show_mismatches) {
      // even if strands are updated, don't bother rendering if we aren't showing mismatches previously or now
      return false;
    }
    BuiltList<Strand> strands = nextProps['DesignMainMismatchesProps.strands'];
    return !(show_mismatches == props.show_mismatches && strands == props.strands);
  }

  @override
  render() {
    bool show_mismatches = this.props.show_mismatches;
    BuiltList<Strand> strands = this.props.strands;

    if (!show_mismatches) {
      return null;
    } else {
      List<ReactElement> mismatch_components = this._create_mismatch_components(strands);
      return (Dom.g()..className = 'mismatches-main-view')(mismatch_components);
    }
  }

  List<ReactElement> _create_mismatch_components(BuiltList<Strand> strands) {
    List<ReactElement> mismatch_components = [];
    Set<String> keys = {};
    for (Strand strand in strands) {
      for (BoundSubstrand substrand in strand.bound_substrands()) {
        BuiltList<Mismatch> mismatches = app.state.dna_design.mismatches_on_substrand(substrand);
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
