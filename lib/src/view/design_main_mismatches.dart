import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/composite_stores.dart';

import '../model/dna_design.dart';
import '../app.dart';
import '../model/strand.dart';
import 'design_main_mismatch.dart';

part 'design_main_mismatches.over_react.g.dart';

@Factory()
UiFactory<DesignMainMismatchesProps> DesignMainMismatches = _$DesignMainMismatches;

@Props()
class _$DesignMainMismatchesProps extends FluxUiProps<MismatchesStore, MismatchesStore> {
  bool show_mismatches;
}

@Component()
class DesignMainMismatchesComponent extends FluxUiComponent<DesignMainMismatchesProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    if (!this.props.store.show_mismatches_store.show_mismatches) {
      return null;
    } else {
      List<ReactElement> mismatch_components = this._create_mismatch_components();
      return (Dom.g()..className = 'mismatches-main-view')(mismatch_components);
    }
  }

  List<ReactElement> _create_mismatch_components() {
    List<ReactElement> mismatch_components = [];
    Set<String> keys = {};
    for (Strand strand in this.props.store.strands_store.strands) {
      for (BoundSubstrand substrand in strand.bound_substrands()) {
        List<Mismatch> mismatches = app.model.dna_design.mismatches_on_substrand(substrand);
        for (Mismatch mismatch in mismatches) {
          var helix = app.model.dna_design.helices[substrand.helix];
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
