import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/app_ui_state.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/select_mode_state.dart';
import 'package:scadnano/src/state/selectable.dart';

import '../state/app_state.dart';
import '../state/strand.dart';
import 'design_main_strand.dart';

part 'design_main_strands.over_react.g.dart';

UiFactory<DesignMainStrandsProps> ConnectedDesignMainStrands =
    connect<AppState, DesignMainStrandsProps>(mapStateToProps: (state) {
  return DesignMainStrands()
    ..strands = state.dna_design.strands
    ..helices = state.dna_design.helices
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..strands_selectable = state.ui_state.select_mode_state.modes.contains(SelectModeChoice.strand)
    ..assign_dna_mode = state.ui_state.edit_modes.contains(EditModeChoice.assign_dna)
    ..select_mode = state.ui_state.edit_modes.contains(EditModeChoice.select)
    ..selectables_store = state.ui_state.selectables_store
    ..select_mode_state = state.ui_state.select_mode_state
    ..select_mode = state.ui_state.edit_modes.contains(EditModeChoice.select)
    ..pencil_mode = state.ui_state.edit_modes.contains(EditModeChoice.pencil)
    ..ligate_mode = state.ui_state.edit_modes.contains(EditModeChoice.ligate)
    ..loopout_mode = state.ui_state.edit_modes.contains(EditModeChoice.loopout)
    ..nick_mode = state.ui_state.edit_modes.contains(EditModeChoice.nick)
    ..drawing_potential_crossover = state.ui_state.drawing_potential_crossover
    ..moving_dna_ends = state.ui_state.moving_dna_ends
    ..show_mouseover_rect = state.ui_state.edit_modes.contains(EditModeChoice.backbone);
})(DesignMainStrands);

@Factory()
UiFactory<DesignMainStrandsProps> DesignMainStrands = _$DesignMainStrands;

@Props()
class _$DesignMainStrandsProps extends UiProps {
  BuiltList<Strand> strands;
  BuiltList<Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
  SelectablesStore selectables_store;
  SelectModeState select_mode_state;
  bool strands_selectable;
  bool assign_dna_mode;
  bool select_mode;
  bool pencil_mode;
  bool ligate_mode;
  bool loopout_mode;
  bool nick_mode;
  bool drawing_potential_crossover;
  bool moving_dna_ends;
  bool show_mouseover_rect;
}

@Component2()
class DesignMainStrandsComponent extends UiComponent2<DesignMainStrandsProps> {
//  @override
//  bool shouldComponentUpdate(Map nextProps, Map nextState) {
//    BuiltList<Strand> strands = nextProps['DesignMainStrandsProps.strands'];
//    return !(props.strands == strands);
//  }

  @override
  render() {
//    AppUIState ui_state = props.state.ui_state;
    bool;
    return (Dom.g()..className = 'strands-main-view')([
      for (var strand in props.strands)
//        (ConnectedDesignMainStrand()
        (DesignMainStrand()
          ..strand = strand
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..selected = props.selectables_store.selected(strand)
          ..selectable = props.strands_selectable
          ..assign_dna_mode_enabled = props.assign_dna_mode
          ..helices = props.helices
          ..selectables_store = props.selectables_store
          ..select_mode_state = props.select_mode_state
          ..select_mode = props.select_mode
          ..pencil_mode = props.pencil_mode
          ..ligate_mode = props.ligate_mode
          ..loopout_mode = props.loopout_mode
          ..nick_mode = props.nick_mode
          ..drawing_potential_crossover = props.drawing_potential_crossover
          ..moving_dna_ends = props.moving_dna_ends
          ..show_mouseover_rect = props.show_mouseover_rect
          ..key = strand.toString())()
    ]);
  }
}
