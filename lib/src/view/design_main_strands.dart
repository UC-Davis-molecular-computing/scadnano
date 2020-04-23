import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react_client/react_interop.dart';
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
    ..selectables_store = state.ui_state.selectables_store
    ..select_mode_state = state.ui_state.select_mode_state
    ..edit_modes = state.ui_state.edit_modes
    ..is_origami = state.dna_design.is_origami
    ..show_modifications = state.ui_state.show_modifications
    ..currently_moving = state.ui_state.strands_move != null || state.ui_state.moving_dna_ends
    ..drawing_potential_crossover = state.ui_state.drawing_potential_crossover
    ..moving_dna_ends = state.ui_state.moving_dna_ends
    ..assign_complement_to_bound_strands_default = state.ui_state.assign_complement_to_bound_strands_default
    ..warn_on_change_strand_dna_assign_default = state.ui_state.warn_on_change_strand_dna_assign_default;
})(DesignMainStrands);


UiFactory<DesignMainStrandsProps> DesignMainStrands = _$DesignMainStrands;


mixin DesignMainStrandsProps on UiProps {
  BuiltList<Strand> strands;
  BuiltMap<int, Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
  SelectablesStore selectables_store;
  SelectModeState select_mode_state;
  BuiltSet<EditModeChoice> edit_modes;
  bool show_modifications;
  bool drawing_potential_crossover;
  bool moving_dna_ends;
  bool is_origami;
  bool currently_moving;
  bool assign_complement_to_bound_strands_default;
  bool warn_on_change_strand_dna_assign_default;
}


class DesignMainStrandsComponent extends UiComponent2<DesignMainStrandsProps> {
  bool origami_type_is_selectable(Strand strand) {
    if (!props.is_origami) {
      return true;
    }
    if (strand.is_scaffold) {
      return props.select_mode_state.modes.contains(SelectModeChoice.scaffold);
    } else {
      return props.select_mode_state.modes.contains(SelectModeChoice.staple);
    }
  }

  bool strand_is_selectable(Strand strand) {
    if (!(props.select_mode_state.modes.contains(SelectModeChoice.strand) &&
        props.edit_modes.contains(EditModeChoice.select))) {
      return false;
    }
    return origami_type_is_selectable(strand);
  }

  @override
  render() {
    List<ReactElement> elts = [];
    for (var strand in props.strands) {
      Map<int, Helix> helices_used_in_strand_mutable = {};
      for (var ss in strand.bound_substrands()) {
        helices_used_in_strand_mutable[ss.helix] = props.helices[ss.helix];
      }
      var helices_used_in_strand = BuiltMap<int, Helix>(helices_used_in_strand_mutable);
      elts.add((DesignMainStrand()
        ..strand = strand
        ..side_selected_helix_idxs = props.side_selected_helix_idxs
        ..selected = props.selectables_store.selected(strand)
        ..selectable = strand_is_selectable(strand)
        ..origami_type_is_selectable = origami_type_is_selectable(strand)
        ..helices = helices_used_in_strand // props.helices
        ..selectables_store = props.selectables_store
        ..select_mode_state = props.select_mode_state
        ..edit_modes = props.edit_modes
        ..show_modifications = props.show_modifications
        ..currently_moving = props.currently_moving
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends
        ..assign_complement_to_bound_strands_default = props.assign_complement_to_bound_strands_default
        ..warn_on_change_strand_dna_assign_default = props.warn_on_change_strand_dna_assign_default
        ..key = strand.toString())());
    }

    return (Dom.g()..className = 'strands-main-view')(elts);
  }
}
