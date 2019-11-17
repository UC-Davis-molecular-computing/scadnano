library view_main;

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
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
import 'selection_box_view.dart';
import 'react_dnd.dart';
import '../util.dart' as util;

part 'design_main.over_react.g.dart';

//TODO: display width of each portion of helix between major ticks lightly above helix 0;
//  alternately, display as mouseover information

final USING_REACT_DND = false;

UiFactory<_$DesignMainProps> ConnectedDesignMain = connect<Model, _$DesignMainProps>(
  mapStateToProps: (model) => (DesignMain()..model = model),
)(DesignMain);

@Factory()
UiFactory<DesignMainProps> DesignMain = _$DesignMain;

@Props()
class _$DesignMainProps extends UiProps {
  Model model;
}

@Component2()
class DesignMainComponent extends UiComponent2<DesignMainProps> {
  @override
  render() {
    Model model = this.props.model;

    if (model.has_error()) {
      return null;
    }

    num stroke_width = 2.0 / util.current_zoom_main();

    ReactElement main_elt = (Dom.g()..id = 'main-view-group')(
      (DesignMainMouseoverRectHelices()..helices = model.dna_design.helices)(),
      (DesignMainHelices()..helices = model.dna_design.helices)(),
      (DesignMainMismatches()
        ..show_mismatches = model.ui_model.show_mismatches
        ..strands = model.dna_design.strands)(),
      (DesignMainStrands()..strands = model.dna_design.strands)(),
      (DesignMainDNASequences()
        ..show_dna = model.ui_model.show_dna
        ..strands = model.dna_design.strands)(),
      (SelectionBoxView()
        ..selection_box = model.ui_model.selection_box_main_view
        ..stroke_width = stroke_width)(),
    );

    if (USING_REACT_DND) {
      ReactComponent dnd_provider_comp = DndProvider({'backend': HTML5Backend}, main_elt);
      return dnd_provider_comp;
    } else {
      return main_elt;
    }
  }
}
