library view_main;

import 'design_main_mismatches.dart';
import 'design_main_helices.dart';
import 'design_main_strands.dart';
import 'design_main_dna_sequences.dart';
import 'design_main_mouseover_rect_helices.dart';

import '../model/composite_stores.dart';
import '../model/model.dart';
import '../model/dna_design.dart';

import 'package:over_react/over_react.dart';

part 'design_main.over_react.g.dart';

//TODO: display width of each portion of helix between major ticks lightly above helix 0;
//  alternately, display as mouseover information

@Factory()
UiFactory<DesignMainProps> DesignMain = _$DesignMain;

@Props()
class _$DesignMainProps extends FluxUiProps<Model, Model> {}

@Component()
class DesignMainComponent extends FluxUiComponent<DesignMainProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    DNADesign dna_design = this.props.store.dna_design;
    DNASequencesStore dna_sequences_store = this.props.store.dna_sequences_store;
    MismatchesStore mismatches_store = this.props.store.mismatches_store;
    return (Dom.g()
      ..id = 'main-view-group')(
      (DesignMainHelices()..store = dna_design.helices_store)(),
      (DesignMainMismatches()..store = mismatches_store)(),
      (DesignMainStrands()..store = dna_design.strands_store)(),
      (DesignMainDNASequences()..store = dna_sequences_store)(),
      (DesignMainMouseoverRectHelices()..store = dna_design.helices_store)(),
    );
  }
}

