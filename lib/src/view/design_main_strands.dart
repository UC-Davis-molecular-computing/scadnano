import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:scadnano/src/state/dna_assign_options.dart';

import '../state/group.dart';
import '../state/geometry.dart';
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
    ..groups = state.design.groups
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..selectables_store = state.ui_state.selectables_store
    ..drawing_potential_crossover = state.ui_state.potential_crossover_is_drawing
    ..moving_dna_ends = state.ui_state.dna_ends_are_moving
    ..dna_assign_options = state.ui_state.dna_assign_options
    ..only_display_selected_helices = state.ui_state.only_display_selected_helices
    ..show_dna = state.ui_state.show_dna
    ..show_modifications = state.ui_state.show_modifications
    ..modification_font_size = state.ui_state.modification_font_size
    ..modification_display_connector = state.ui_state.modification_display_connector
    ..show_strand_names = state.ui_state.show_strand_names
    ..show_strand_labels = state.ui_state.show_strand_labels
    ..show_domain_names = state.ui_state.show_domain_names
    ..show_domain_labels = state.ui_state.show_domain_labels
    ..strand_name_font_size = state.ui_state.strand_name_font_size
    ..strand_label_font_size = state.ui_state.strand_label_font_size
    ..domain_name_font_size = state.ui_state.domain_name_font_size
    ..domain_label_font_size = state.ui_state.domain_label_font_size
    ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
    ..display_reverse_DNA_right_side_up = state.ui_state.display_reverse_DNA_right_side_up
    ..geometry = state.design.geometry
    ..retain_strand_color_on_selection = state.ui_state.retain_strand_color_on_selection;
})(DesignMainStrands);

UiFactory<DesignMainStrandsProps> DesignMainStrands = _$DesignMainStrands;

mixin DesignMainStrandsProps on UiProps {
  BuiltList<Strand> strands;
  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  BuiltSet<int> side_selected_helix_idxs;
  SelectablesStore selectables_store;
  bool show_dna;
  bool show_modifications;
  bool show_strand_names;
  bool show_strand_labels;
  bool show_domain_names;
  bool show_domain_labels;
  num strand_name_font_size;
  num strand_label_font_size;
  num domain_name_font_size;
  num domain_label_font_size;
  num modification_font_size;
  bool drawing_potential_crossover;
  bool moving_dna_ends;
  DNAAssignOptions dna_assign_options;
  bool only_display_selected_helices;
  bool modification_display_connector;
  bool display_reverse_DNA_right_side_up;
  Geometry geometry;
  BuiltMap<int, Point<num>> helix_idx_to_svg_position_map;
  bool retain_strand_color_on_selection;
}

class DesignMainStrandsComponent extends UiComponent2<DesignMainStrandsProps> with PureComponent {
  @override
  render() {
    List<ReactElement> elts = [];
    for (var strand in props.strands) {
      Map<int, Helix> helices_used_in_strand_mutable = {};
      for (var domain in strand.domains) {
        helices_used_in_strand_mutable[domain.helix] = props.helices[domain.helix];
      }
      var helices_used_in_strand = helices_used_in_strand_mutable.build();
      var group_names_in_strand = helices_used_in_strand.values.map((helix) => helix.group);
      BuiltMap<String, HelixGroup> groups_in_strand =
          {for (var name in group_names_in_strand) name: props.groups[name]}.build();
      var selected_ends_in_strand = props.selectables_store.selected_ends_in_strand(strand);
      var selected_crossovers_in_strand = props.selectables_store.selected_crossovers_in_strand(strand);
      var selected_loopouts_in_strand = props.selectables_store.selected_loopouts_in_strand(strand);
      var selected_extensions_in_strand = props.selectables_store.selected_extensions_in_strand(strand);
      var selected_domains_in_strand = props.selectables_store.selected_domains_in_strand(strand);
      var selected_deletions_in_strand = props.selectables_store.selected_deletions_in_strand(strand);
      var selected_insertions_in_strand = props.selectables_store.selected_insertions_in_strand(strand);
      var selected_modifications_in_strand = props.selectables_store.selected_modifications_in_strand(strand);

      elts.add((DesignMainStrand()
        ..strand = strand
        ..side_selected_helix_idxs =
            props.only_display_selected_helices ? props.side_selected_helix_idxs : null
        ..selected = props.selectables_store.selected(strand)
        ..helices = helices_used_in_strand
        ..groups = groups_in_strand
        ..selected_ends_in_strand = selected_ends_in_strand
        ..selected_crossovers_in_strand = selected_crossovers_in_strand
        ..selected_loopouts_in_strand = selected_loopouts_in_strand
        ..selected_extensions_in_strand = selected_extensions_in_strand
        ..selected_domains_in_strand = selected_domains_in_strand
        ..selected_deletions_in_strand = selected_deletions_in_strand
        ..selected_insertions_in_strand = selected_insertions_in_strand
        ..selected_modifications_in_strand = selected_modifications_in_strand
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends
        ..dna_assign_options = props.dna_assign_options
        ..only_display_selected_helices = props.only_display_selected_helices
        ..show_dna = props.show_dna
        ..show_modifications = props.show_modifications
        ..show_strand_names = props.show_strand_names
        ..show_strand_labels = props.show_strand_labels
        ..show_domain_names = props.show_domain_names
        ..show_domain_labels = props.show_domain_labels
        ..strand_name_font_size = props.strand_name_font_size
        ..strand_label_font_size = props.strand_label_font_size
        ..domain_name_font_size = props.domain_name_font_size
        ..domain_label_font_size = props.domain_label_font_size
        ..modification_font_size = props.modification_font_size
        ..modification_display_connector = props.modification_display_connector
        ..geometry = props.geometry
        ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
        ..display_reverse_DNA_right_side_up = props.display_reverse_DNA_right_side_up
        ..retain_strand_color_on_selection = props.retain_strand_color_on_selection
        ..key = strand.toString())());
    }

    return (Dom.g()..className = 'strands-main-view')(elts);
  }
}
