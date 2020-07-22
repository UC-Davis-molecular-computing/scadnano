import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:scadnano/src/state/geometry.dart';

import '../state/helix.dart';
import '../state/selectable.dart';
import '../state/app_state.dart';
import '../state/strand.dart';
import 'design_main_strand.dart';
import 'pure_component.dart';

part 'design_main_strands.over_react.g.dart';

UiFactory<DesignMainStrandsProps> ConnectedDesignMainStrands =
    connect<AppState, DesignMainStrandsProps>(mapStateToProps: (state) {
  return DesignMainStrands()
    ..strands = state.design.strands
    ..helices = state.design.helices
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..selectables_store = state.ui_state.selectables_store
    ..show_modifications = state.ui_state.show_modifications
    ..currently_moving = state.ui_state.strands_move != null || state.ui_state.moving_dna_ends
    ..drawing_potential_crossover = state.ui_state.drawing_potential_crossover
    ..moving_dna_ends = state.ui_state.moving_dna_ends
    ..assign_complement_to_bound_strands_default = state.ui_state.assign_complement_to_bound_strands_default
    ..warn_on_change_strand_dna_assign_default = state.ui_state.warn_on_change_strand_dna_assign_default
    ..only_display_selected_helices = state.ui_state.only_display_selected_helices
    ..modification_font_size = state.ui_state.modification_font_size
    ..modification_display_connector = state.ui_state.modification_display_connector
  ..geometry = state.design.geometry;
})(DesignMainStrands);

UiFactory<DesignMainStrandsProps> DesignMainStrands = _$DesignMainStrands;

mixin DesignMainStrandsProps on UiProps {
  BuiltList<Strand> strands;
  BuiltMap<int, Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
  SelectablesStore selectables_store;
  bool show_modifications;
  bool drawing_potential_crossover;
  bool moving_dna_ends;
  bool currently_moving;
  bool assign_complement_to_bound_strands_default;
  bool warn_on_change_strand_dna_assign_default;
  bool only_display_selected_helices;
  bool modification_display_connector;
  num modification_font_size;
  Geometry geometry;
}

class DesignMainStrandsComponent extends UiComponent2<DesignMainStrandsProps> with PureComponent {
  @override
  render() {
    List<ReactElement> elts = [];
    for (var strand in props.strands) {
      Map<int, Helix> helices_used_in_strand_mutable = {};
      for (var ss in strand.domains()) {
        helices_used_in_strand_mutable[ss.helix] = props.helices[ss.helix];
      }
      var helices_used_in_strand = helices_used_in_strand_mutable.build();
      var selected_ends_in_strand = props.selectables_store.selected_ends_in_strand(strand);
      var selected_crossovers_in_strand = props.selectables_store.selected_crossovers_in_strand(strand);
      var selected_loopouts_in_strand = props.selectables_store.selected_loopouts_in_strand(strand);

      elts.add((DesignMainStrand()
        ..strand = strand
        ..side_selected_helix_idxs =
            props.only_display_selected_helices ? props.side_selected_helix_idxs : null
        ..selected = props.selectables_store.selected(strand)
        ..helices = helices_used_in_strand
        ..selected_ends_in_strand = selected_ends_in_strand
        ..selected_crossovers_in_strand = selected_crossovers_in_strand
        ..selected_loopouts_in_strand = selected_loopouts_in_strand
        ..show_modifications = props.show_modifications
        ..currently_moving = props.currently_moving
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends
        ..assign_complement_to_bound_strands_default = props.assign_complement_to_bound_strands_default
        ..warn_on_change_strand_dna_assign_default = props.warn_on_change_strand_dna_assign_default
        ..only_display_selected_helices = props.only_display_selected_helices
        ..modification_font_size = props.modification_font_size
        ..modification_display_connector = props.modification_display_connector
        ..geometry = props.geometry
        ..key = strand.toString())());
    }

    return (Dom.g()..className = 'strands-main-view')(elts);
  }
}
