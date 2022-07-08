library view_main;

import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:scadnano/src/view/design_main_insertion_deletion_mismatches.dart';
import 'package:scadnano/src/view/design_main_slice_bar.dart';

import '../state/selection_rope.dart';
import 'design_main_domains_moving.dart';
import 'selection_rope_view.dart';
import '../actions/actions.dart' as actions;
import '../state/design.dart';
import '../state/edit_mode.dart';
import '../state/potential_vertical_crossover.dart';
import '../state/strand_creation.dart';
import '../state/strands_move.dart';
import 'design_main_domain_name_mismatches.dart';
import 'design_main_loopout_lengths.dart';
import 'design_main_strand_creating.dart';
import 'design_main_dna_mismatches.dart';
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

part 'design_main.over_react.g.dart';

final USING_REACT_DND = false;

UiFactory<DesignMainProps> ConnectedDesignMain = connect<AppState, DesignMainProps>(
  mapStateToProps: (state) {
    if (state.has_error) {
      return (DesignMain()..has_error = true);
    } else {
      return (DesignMain()
        ..design = state.design
        ..helix_change_apply_to_all = state.ui_state.helix_change_apply_to_all
        ..potential_vertical_crossovers = state.design.potential_vertical_crossovers
        ..drawing_potential_crossover = state.ui_state.potential_crossover_is_drawing
        ..domain_label_font_size = state.ui_state.domain_name_font_size
        ..major_tick_offset_font_size = state.ui_state.major_tick_offset_font_size
        ..major_tick_width_font_size = state.ui_state.major_tick_width_font_size
        ..has_error = state.has_error
        ..edit_modes = state.ui_state.edit_modes
        ..strands_move = state.ui_state.strands_move
        ..strand_creation = state.ui_state.strand_creation
        ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
        ..show_mismatches = state.ui_state.show_mismatches
        ..show_slice_bar = state.ui_state.show_slice_bar
        ..slice_bar_offset = state.ui_state.slice_bar_offset
        ..displayed_group_name = state.ui_state.displayed_group_name
        ..show_domain_name_mismatches = state.ui_state.show_domain_name_mismatches
        ..show_insertion_deletion_mismatches = state.ui_state.show_insertion_deletion_mismatches
        ..show_dna = state.ui_state.show_dna
        ..show_domain_names = state.ui_state.show_domain_names
        ..show_strand_names = state.ui_state.show_strand_names
        ..show_helix_circles = state.ui_state.show_helix_circles_main_view
        ..show_helix_components = state.ui_state.show_helix_components_main_view
        ..dna_sequence_png_uri = state.ui_state.dna_sequence_png_uri
        ..dna_sequence_png_horizontal_offset = state.ui_state.dna_sequence_png_horizontal_offset
        ..dna_sequence_png_vertical_offset = state.ui_state.dna_sequence_png_vertical_offset
        ..disable_png_cache_until_action_completes = state.ui_state.disable_png_cache_until_action_completes
        ..is_zoom_above_threshold = state.ui_state.is_zoom_above_threshold
        ..only_display_selected_helices = state.ui_state.only_display_selected_helices
        ..display_base_offsets_of_major_ticks = state.ui_state.display_base_offsets_of_major_ticks
        ..show_loopout_length = state.ui_state.show_loopout_length
        ..display_base_offsets_of_major_ticks_only_first_helix =
            state.ui_state.display_base_offsets_of_major_ticks_only_first_helix
        ..display_major_tick_widths = state.ui_state.display_major_tick_widths
        ..display_major_tick_widths_all_helices = state.ui_state.display_major_tick_widths_all_helices
        ..helix_group_is_moving = state.ui_state.helix_group_is_moving
        ..helix_idx_to_svg_position_map = state.helix_idx_to_svg_position_map
        ..invert_y = state.ui_state.invert_y
        ..selection_rope = state.ui_state.selection_rope);
    }
  },
)(DesignMain);

@Factory()
UiFactory<DesignMainProps> DesignMain = _$DesignMain;

@Props()
mixin DesignMainPropsMixin on UiProps {
  Design design;
  BuiltList<PotentialVerticalCrossover> potential_vertical_crossovers;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltSet<EditModeChoice> edit_modes;
  StrandsMove strands_move;
  StrandCreation strand_creation;
  bool has_error;
  bool show_mismatches;
  bool show_domain_name_mismatches;
  bool show_insertion_deletion_mismatches;
  bool show_dna;
  bool show_domain_names;
  bool show_strand_names;
  num domain_label_font_size;
  num major_tick_offset_font_size;
  num major_tick_width_font_size;
  bool drawing_potential_crossover;
  String dna_sequence_png_uri;
  num dna_sequence_png_horizontal_offset;
  num dna_sequence_png_vertical_offset;
  actions.Action disable_png_cache_until_action_completes;
  bool is_zoom_above_threshold;
  bool only_display_selected_helices;
  bool helix_change_apply_to_all;
  bool display_base_offsets_of_major_ticks;
  bool display_base_offsets_of_major_ticks_only_first_helix;
  bool display_major_tick_widths;
  bool display_major_tick_widths_all_helices;
  bool show_helix_circles;
  bool show_helix_components;
  bool helix_group_is_moving;
  bool show_loopout_length;
  bool show_slice_bar;
  int slice_bar_offset;
  String displayed_group_name;
  SelectionRope selection_rope;
  BuiltMap<int, Point<num>> helix_idx_to_svg_position_map;
  bool invert_y;
}

@Props()
class DesignMainProps = UiProps with DesignMainPropsMixin;

@Component2()
class DesignMainComponent extends UiComponent2<DesignMainProps> {
  @override
  get consumedProps => propsMeta.forMixins({DesignMainPropsMixin});

  @override
  render() {
    if (props.has_error) {
      return null;
    }

    ReactElement main_elt = (Dom.g()..id = 'main-view-group')([
      if (props.show_helix_components)
        (DesignMainHelices()
          ..helices = props.design.helices
          ..groups = props.design.groups
          ..helix_idxs_in_group = props.design.helix_idxs_in_group
          ..geometry = props.design.geometry
          ..major_tick_offset_font_size = props.major_tick_offset_font_size
          ..major_tick_width_font_size = props.major_tick_width_font_size
          ..helix_change_apply_to_all = props.helix_change_apply_to_all
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..show_dna = props.show_dna
          ..show_domain_labels = props.show_domain_names
          ..show_helix_circles = props.show_helix_circles
          ..display_base_offsets_of_major_ticks = props.display_base_offsets_of_major_ticks
          ..display_base_offsets_of_major_ticks_only_first_helix =
              props.display_base_offsets_of_major_ticks_only_first_helix
          ..display_major_tick_widths = props.display_major_tick_widths
          ..display_major_tick_widths_all_helices = props.display_major_tick_widths_all_helices
          // ..slice_bar_offset = props.slice_bar_offset
          // ..displayed_group_name = props.displayed_group_name
          ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
          ..invert_y = props.invert_y
          ..key = 'helices')(),
      if (props.show_mismatches)
        (DesignMainDNAMismatches()
          ..design = props.design
          ..only_display_selected_helices = props.only_display_selected_helices
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..helix_idx_to_svg_position_y_map = props.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'mismatches')(),
      if (props.show_domain_name_mismatches)
        (DesignMainDomainNameMismatches()
          ..design = props.design
          ..only_display_selected_helices = props.only_display_selected_helices
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
          ..key = 'domain-name-mismatches')(),
      if (props.show_insertion_deletion_mismatches)
        (DesignMainUnpairedInsertionDeletion()
          ..design = props.design
          ..only_display_selected_helices = props.only_display_selected_helices
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..helix_idx_to_svg_position_y_map = props.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'insertion_deletion_mismatches')(),
      (ConnectedDesignMainStrands()..key = 'strands')(),
      // after strands so can click when crossover overlaps potential crossover
      if (props.edit_modes.contains(EditModeChoice.pencil) && !props.drawing_potential_crossover)
        (DesignMainPotentialVerticalCrossovers()
          ..potential_vertical_crossovers = props.potential_vertical_crossovers
          ..helices = props.design.helices
          ..only_display_selected_helices = props.only_display_selected_helices
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..groups = props.design.groups
          ..geometry = props.design.geometry
          ..helix_idx_to_svg_position_y_map = props.helix_idx_to_svg_position_map
              .map((helix_idx, svg_position) => MapEntry(helix_idx, svg_position.y))
          ..key = 'potential-vertical-crossovers')(),
      if (props.strand_creation != null)
        (DesignMainStrandCreating()
          ..helix = props.strand_creation.helix
          ..forward = props.strand_creation.forward
          ..start = props.strand_creation.start
          ..end = props.strand_creation.end
          ..color = props.strand_creation.color
          ..helices = {props.strand_creation.helix.idx: props.strand_creation.helix}.build()
          ..groups = {
            props.strand_creation.helix.group: props.design.groups[props.strand_creation.helix.group]
          }.build()
          ..geometry = props.design.geometry
          ..svg_position_y = props.helix_idx_to_svg_position_map[props.strand_creation.helix.idx].y
          ..key = 'strand-creating')(),
      if (props.show_dna)
        (DesignMainDNASequences()
          ..helices = props.design.helices
          ..groups = props.design.groups
          ..geometry = props.design.geometry
          ..strands = props.design.strands
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..dna_sequence_png_uri = props.dna_sequence_png_uri
          ..dna_sequence_png_horizontal_offset = props.dna_sequence_png_horizontal_offset
          ..dna_sequence_png_vertical_offset = props.dna_sequence_png_vertical_offset
          ..is_zoom_above_threshold = props.is_zoom_above_threshold
          ..disable_png_cache_until_action_completes = props.disable_png_cache_until_action_completes
          ..only_display_selected_helices = props.only_display_selected_helices
          ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
          ..key = 'dna-sequences')(),
      if (props.show_loopout_length)
        (DesignMainLoopoutLengths()
          ..geometry = props.design.geometry
          ..strands = props.design.strands
          ..show_loopout_length = props.show_loopout_length
          ..key = 'loopout-length')(),
      // slice_bar_offset null means displayed helix group has no helices, so omit slice bar
      if (props.show_slice_bar && props.slice_bar_offset != null)
        (DesignMainSliceBar()
          ..helices = props.design.helices
          ..groups = props.design.groups
          ..helix_idxs_in_group = props.design.helix_idxs_in_group
          ..geometry = props.design.geometry
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..slice_bar_offset = props.slice_bar_offset
          ..displayed_group_name = props.displayed_group_name
          ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
          ..key = 'slice-bar')(),
      (ConnectedPotentialCrossoverView()
        ..id = 'potential-crossover-main'
        ..key = 'potential-crossover')(),
      (ConnectedSelectionBoxView()
        //FIXME: this makes the DesignMain React component not a pure function of AppState,
        // but currently no way around it since zoom is defined outside of React by the svg-pan-zoom library
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_main_js())
        ..is_main = true
        ..id = 'selection-box-main'
        ..key = 'selection-box')(),
      (ConnectedSelectionRopeView()
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_main_js())
        ..is_main = true
        ..id = 'selection-rope-main'
        ..key = 'selection-rope')(),
      if (props.helix_group_is_moving)
        (ConnectedHelixGroupMoving()
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..show_helix_circles = props.show_helix_circles
          ..helix_idx_to_svg_position_map = props.helix_idx_to_svg_position_map
          ..key = 'helix-group-moving')(),
      (ConnectedDesignMainStrandsMoving()..key = 'strands-moving')(),
      (ConnectedDesignMainDomainsMoving()..key = 'domains-moving')(),
    ]);

    if (USING_REACT_DND) {
      ReactComponent dnd_provider_comp = DndProvider({'backend': HTML5Backend}, main_elt);
      return dnd_provider_comp;
    } else {
      return main_elt;
    }
  }
}
