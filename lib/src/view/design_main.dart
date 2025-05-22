library view_main;

import 'package:web/web.dart';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/app_ui_state.dart';
import 'package:scadnano/src/state/base_pair_display_type.dart';
import 'package:scadnano/src/view/design_main_unpaired_insertion_deletions.dart';
import 'package:scadnano/src/view/design_main_slice_bar.dart';
import 'package:scadnano/src/view/potential_extensions_view.dart';

import '../state/selection_rope.dart';
import 'design_main_base_pair_rectangle.dart';
import 'design_main_domains_moving.dart';
import 'selection_rope_view.dart';
import '../actions/actions.dart' as actions;
import '../state/design.dart';
import '../state/edit_mode.dart';
import '../state/potential_vertical_crossover.dart';
import '../state/strand_creation.dart';
import '../state/strands_move.dart';
import 'design_main_domain_name_mismatches.dart';
import 'design_main_loopout_extension_lengths.dart';
import 'design_main_strand_creating.dart';
import 'design_main_dna_mismatches.dart';
import 'design_main_base_pair_lines.dart';
import 'design_main_helices.dart';
import 'design_main_potential_vertical_crossovers.dart';
import 'design_main_strands.dart';
import 'design_main_dna_sequences.dart';
import '../state/app_state.dart';
import 'design_main_strands_moving.dart';
import 'helix_group_moving.dart';
import 'potential_crossover_view.dart';
import 'selection_box_view.dart';
import 'react_dnd.dart';
import '../util.dart' as util;
import '../app.dart';

part 'design_main.over_react.g.dart';

// final USING_REACT_DND = false;

UiFactory<DesignMainProps> ConnectedDesignMain =
    connect<AppState, DesignMainProps>(mapStateToProps: (state) => DesignMain()..state = state)(DesignMain);

UiFactory<DesignMainProps> DesignMain = _$DesignMain;

mixin DesignMainProps on UiProps {
  late AppState state;
}

class DesignMainComponent extends UiComponent2<DesignMainProps> {
  @override
  render() {
    AppState state = props.state;
    if (state.has_error) {
      return null;
    }
    assert(state.maybe_design != null);
    Design design = state.design;
    AppUIState ui_state = state.ui_state;

    ReactElement main_elt = (Dom.g()..id = 'main-view-group')([
      if (ui_state.show_helix_components_main_view)
        (DesignMainHelices()
          ..helices = design.helices
          ..groups = design.groups
          ..helix_idxs_in_group = design.helix_idxs_in_group
          ..geometry = design.geometry
          ..major_tick_offset_font_size = ui_state.major_tick_offset_font_size
          ..major_tick_width_font_size = ui_state.major_tick_width_font_size
          ..helix_change_apply_to_all = ui_state.helix_change_apply_to_all
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..show_dna = ui_state.show_dna
          ..show_domain_labels = ui_state.show_domain_names
          ..show_helix_circles = ui_state.show_helix_circles_main_view
          ..display_base_offsets_of_major_ticks = ui_state.display_base_offsets_of_major_ticks
          ..display_base_offsets_of_major_ticks_only_first_helix =
              ui_state.display_base_offsets_of_major_ticks_only_first_helix
          ..display_major_tick_widths = ui_state.display_major_tick_widths
          ..display_major_tick_widths_all_helices = ui_state.display_major_tick_widths_all_helices
          // ..slice_bar_offset = props.slice_bar_offset
          // ..displayed_group_name = props.displayed_group_name
          ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
          ..invert_y = ui_state.invert_y
          ..key = 'helices')(),

      if (ui_state.show_mismatches)
        (DesignMainDNAMismatches()
          ..design = design
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..helix_idx_to_svg_position_y_map = state.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'mismatches')(),

      if (ui_state.show_domain_name_mismatches)
        (DesignMainDomainNameMismatches()
          ..design = design
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
          ..key = 'domain-name-mismatches')(),

      if (ui_state.show_unpaired_insertion_deletions)
        (DesignMainUnpairedInsertionDeletions()
          ..design = design
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..helix_idx_to_svg_position_y_map = state.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'unpaired-insertion-deletions')(),

      if (ui_state.base_pair_display_type == BasePairDisplayType.lines)
        (DesignMainBasePairLines()
          ..with_mismatches = ui_state.show_base_pair_lines_with_mismatches
          ..design = design
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..helix_idx_to_svg_position_y_map = state.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'base-pair-lines')(),

      if (ui_state.base_pair_display_type == BasePairDisplayType.rectangle)
        (DesignMainBasePairRectangle()
          ..with_mismatches = ui_state.show_base_pair_lines_with_mismatches
          ..design = design
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..helix_idx_to_svg_position_y_map = state.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'base-pair-rectangle')(),

      (set_design_main_strands_props(ConnectedDesignMainStrands()..key = 'strands', state))(),

      // after strands so can click when crossover overlaps potential crossover
      if (ui_state.edit_modes.contains(EditModeChoice.pencil) && !ui_state.drawing_potential_crossover)
        (DesignMainPotentialVerticalCrossovers()
          ..potential_vertical_crossovers = design.potential_vertical_crossovers
          ..helices = design.helices
          ..groups = design.groups
          ..geometry = design.geometry
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..helix_idx_to_svg_position_y_map = state.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'potential-vertical-crossovers')(),

      if (ui_state.strand_creation != null)
        (DesignMainStrandCreating()
          ..helix = ui_state.strand_creation!.helix
          ..forward = ui_state.strand_creation!.forward
          ..start = ui_state.strand_creation!.start
          ..end = ui_state.strand_creation!.end
          ..color = ui_state.strand_creation!.color
          ..helices = {ui_state.strand_creation!.helix.idx: ui_state.strand_creation!.helix}.build()
          ..groups = {
            ui_state.strand_creation!.helix.group: design.groups[ui_state.strand_creation!.helix.group]!
          }.build()
          ..geometry = design.geometry
          ..svg_position_y = state.helix_idx_to_svg_position_map[ui_state.strand_creation!.helix.idx]!.y
          ..key = 'strand-creating')(),

      if (ui_state.show_dna)
        (DesignMainDNASequences()
          ..helices = design.helices
          ..groups = design.groups
          ..geometry = design.geometry
          ..strands = design.strands
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..dna_sequence_png_uri = ui_state.dna_sequence_png_uri
          ..dna_sequence_png_horizontal_offset = ui_state.dna_sequence_png_horizontal_offset
          ..dna_sequence_png_vertical_offset = ui_state.dna_sequence_png_vertical_offset
          ..is_zoom_above_threshold = ui_state.is_zoom_above_threshold
          ..export_svg_action_delayed_for_png_cache = ui_state.export_svg_action_delayed_for_png_cache
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
          ..disable_png_caching_dna_sequences = ui_state.disable_png_caching_dna_sequences
          ..retain_strand_color_on_selection = ui_state.retain_strand_color_on_selection
          ..display_reverse_DNA_right_side_up = ui_state.display_reverse_DNA_right_side_up
          ..key = 'dna-sequences')(),

      if (ui_state.show_loopout_extension_length)
        (DesignMainLoopoutExtensionLengths()
          ..geometry = design.geometry
          ..strands = design.strands
          ..show_length = ui_state.show_loopout_extension_length
          ..key = 'loopout-extension-length')(),

      // slice_bar_offset null means displayed helix group has no helices, so omit slice bar
      if (ui_state.show_slice_bar && ui_state.slice_bar_offset != null)
        (DesignMainSliceBar()
          ..slice_bar_offset = ui_state.slice_bar_offset!
          ..helices = design.helices
          ..groups = design.groups
          ..geometry = design.geometry
          ..displayed_group_name = ui_state.displayed_group_name
          ..helix_idxs_in_group = design.helix_idxs_in_group
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
          ..key = 'slice-bar')(),

      (set_potential_crossover_props(ConnectedPotentialCrossoverView()..key = 'potential-crossover', null))(),
      (ConnectedPotentialExtensionsView()
        ..id_ = 'potential-extensions-main'
        ..key = 'potential-extensions')(),
      (ConnectedSelectionBoxView()
        //FIXME: this makes the DesignMain React component not a pure function of AppState,
        // but currently no way around it since zoom is defined outside of React by the svg-pan-zoom library
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_main_js())
        ..is_main = true
        ..id_ = 'selection-box-main'
        ..key = 'selection-box')(),

      (ConnectedSelectionRopeView()
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_main_js())
        ..is_main = true
        ..id_ = 'selection-rope-main'
        ..key = 'selection-rope')(),

      // Need to set 4 props here because this is a specialized store
      if (ui_state.helix_group_is_moving)
        (set_helix_group_moving_props(ConnectedHelixGroupMoving(), app.store_helix_group_move.state)
          ..side_selected_helix_idxs = ui_state.side_selected_helix_idxs
          ..only_display_selected_helices = ui_state.only_display_selected_helices
          ..show_helix_circles = ui_state.show_helix_circles_main_view
          ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
          ..major_tick_offset_font_size = ui_state.major_tick_offset_font_size
          ..major_tick_width_font_size = ui_state.major_tick_width_font_size
          ..show_domain_labels = ui_state.show_domain_labels
          ..key = 'helix-group-moving')(),

      (set_design_main_strands_moving_props(
          ConnectedDesignMainStrandsMoving()..key = 'strands-moving', state))(),

      // (ConnectedDesignMainDomainsMoving()..key = 'domains-moving')(),
      (set_design_main_domains_moving_props(
          ConnectedDesignMainDomainsMoving()..key = 'domains-moving', state))(),
    ]);

    // if (USING_REACT_DND) {
    //   ReactComponent dnd_provider_comp = DndProvider({'backend': HTML5Backend}, main_elt);
    //   return dnd_provider_comp;
    // } else {
    return main_elt;
    // }
  }
}
