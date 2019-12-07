library view_main;

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react_client/react_interop.dart';

import 'design_main_mismatches.dart';
import 'design_main_helices.dart';
import 'design_main_strands.dart';
import 'design_main_dna_sequences.dart';
import 'design_main_mouseover_rect_helices.dart';
import '../state/selection_box.dart';
import '../state/app_state.dart';
import 'selection_box_view.dart';
import 'react_dnd.dart';
import '../util.dart' as util;

part 'design_main.over_react.g.dart';

final USING_REACT_DND = false;

UiFactory<_$DesignMainProps> ConnectedDesignMain = connect<AppState, _$DesignMainProps>(
  mapStateToProps: (state) => (DesignMain()..state = state),
)(DesignMain);

@Factory()
UiFactory<DesignMainProps> DesignMain = _$DesignMain;

@Props()
class _$DesignMainProps extends UiProps {
  AppState state;
}

@Component2()
class DesignMainComponent extends UiComponent2<DesignMainProps> {
  @override
  render() {
    AppState state = props.state;

    if (state.has_error()) {
      return null;
    }

    ReactElement main_elt = (Dom.g()..id = 'main-view-group')([
      (DesignMainHelices()
        ..helices = state.dna_design.helices
        ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
        ..key = 'helices')(),
      (DesignMainMismatches()
        ..show_mismatches = state.ui_state.show_mismatches
        ..strands = state.dna_design.strands
        ..key = 'mismatches')(),
      (DesignMainStrands()
        ..strands = state.dna_design.strands
        ..key = 'strands')(),
      (DesignMainDNASequences()
        ..show_dna = state.ui_state.show_dna
        ..strands = state.dna_design.strands
        ..key = 'dna')(),
      (ConnectedSelectionBoxView()
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_main())
        ..is_main = true
        ..id = 'selection-box-main'
        ..key = 'selection_box')(),
      if (state.ui_state.show_mouseover_rect)
        (DesignMainMouseoverRectHelices()
          ..helices = state.dna_design.helices
          ..key = 'mouseover_rect')(),
    ]);

    if (USING_REACT_DND) {
      ReactComponent dnd_provider_comp = DndProvider({'backend': HTML5Backend}, main_elt);
      return dnd_provider_comp;
    } else {
      return main_elt;
    }
  }
}
