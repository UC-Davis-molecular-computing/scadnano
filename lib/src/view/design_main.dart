library view_main;

import 'package:react/react_client/react_interop.dart';

import 'design_main_mismatches.dart';
import 'design_main_helices.dart';
import 'design_main_strands.dart';
import 'design_main_dna_sequences.dart';
import 'design_main_mouseover_rect_helices.dart';
import 'design_main_selection_box.dart';

import '../model/selection_box.dart';
import '../model/composite_stores.dart';
import '../model/model.dart';
import '../model/dna_design.dart';
import 'react_dnd.dart';

import 'package:over_react/over_react.dart';

part 'design_main.over_react.g.dart';

//TODO: display width of each portion of helix between major ticks lightly above helix 0;
//  alternately, display as mouseover information

final USING_REACT_DND = false;

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
    SelectionBoxStore selection_rectangle_store = this.props.store.main_view_ui_model.selection_box_store;

    ReactElement main_elt = (Dom.g()..id = 'main-view-group')(
      (DesignMainMouseoverRectHelices()..store = dna_design.helices_store)(),
      (DesignMainHelices()..store = dna_design.helices_store)(),
      (DesignMainMismatches()..store = mismatches_store)(),
      (DesignMainStrands()..store = dna_design.strands_store)(),
      (DesignMainDNASequences()..store = dna_sequences_store)(),
      (DesignMainSelectionBox()..store = selection_rectangle_store)(),
    );

    if (USING_REACT_DND) {
      ReactComponent dnd_provider_comp = DndProvider({'backend': HTML5Backend}, main_elt);
      return dnd_provider_comp;
    } else {
      return main_elt;
    }
  }
}
