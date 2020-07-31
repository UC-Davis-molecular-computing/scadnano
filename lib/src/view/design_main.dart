library view_main;

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react_client/react_interop.dart';

import '../actions/actions.dart' as actions;
import '../state/design.dart';
import '../state/edit_mode.dart';
import '../state/grid.dart';
import '../state/potential_vertical_crossover.dart';
import '../state/strand_creation.dart';
import '../state/strands_move.dart';
import 'design_main_strand_creating.dart';
import 'design_main_strands_moving.dart';
import 'design_main_mismatches.dart';
import 'design_main_helices.dart';
import 'design_main_potential_vertical_crossovers.dart';
import 'design_main_strands.dart';
import 'design_main_dna_sequences.dart';
import 'design_main_mouseover_rect_helices.dart';
import '../state/app_state.dart';
import 'potential_crossover_view.dart';
import 'selection_box_view.dart';
import 'react_dnd.dart';
import '../util.dart' as util;

part 'design_main.over_react.g.dart';

final USING_REACT_DND = false;

UiFactory<DesignMainProps> ConnectedDesignMain = connect<AppState, DesignMainProps>(
  mapStateToProps: (state) {
    if (state.has_error()) {
      return (DesignMain()..has_error = true);
    } else {
      return (DesignMain()
        ..design = state.design
        ..helix_change_apply_to_all = state.ui_state.helix_change_apply_to_all
        ..potential_vertical_crossovers = state.design.potential_vertical_crossovers
        ..drawing_potential_crossover = state.ui_state.drawing_potential_crossover
        ..major_tick_offset_font_size = state.ui_state.major_tick_offset_font_size
        ..major_tick_width_font_size = state.ui_state.major_tick_width_font_size
        ..has_error = state.has_error()
        ..edit_modes = state.ui_state.edit_modes
        ..strands_move = state.ui_state.strands_move
        ..strand_creation = state.ui_state.strand_creation
        ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
        ..show_mismatches = state.ui_state.show_mismatches
        ..show_dna = state.ui_state.show_dna
        ..show_helix_circles = state.ui_state.show_helix_circles_main_view
        ..dna_sequence_png_uri = state.ui_state.dna_sequence_png_uri
        ..disable_png_cache_until_action_completes = state.ui_state.disable_png_cache_until_action_completes
        ..is_zoom_above_threshold = state.ui_state.is_zoom_above_threshold
        ..only_display_selected_helices = state.ui_state.only_display_selected_helices
        ..display_base_offsets_of_major_ticks = state.ui_state.display_base_offsets_of_major_ticks
        ..display_base_offsets_of_major_ticks_only_first_helix =
            state.ui_state.display_base_offsets_of_major_ticks_only_first_helix
        ..display_major_tick_widths = state.ui_state.display_major_tick_widths
        ..display_major_tick_widths_all_helices = state.ui_state.display_major_tick_widths_all_helices);
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
  bool show_dna;
  num major_tick_offset_font_size;
  num major_tick_width_font_size;
  bool drawing_potential_crossover;
  String dna_sequence_png_uri;
  actions.Action disable_png_cache_until_action_completes;
  bool is_zoom_above_threshold;
  bool only_display_selected_helices;
  bool helix_change_apply_to_all;
  bool display_base_offsets_of_major_ticks;
  bool display_base_offsets_of_major_ticks_only_first_helix;
  bool display_major_tick_widths;
  bool display_major_tick_widths_all_helices;
  bool show_helix_circles;
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
        ..show_helix_circles = props.show_helix_circles
        ..display_base_offsets_of_major_ticks = props.display_base_offsets_of_major_ticks
        ..display_base_offsets_of_major_ticks_only_first_helix =
            props.display_base_offsets_of_major_ticks_only_first_helix
        ..display_major_tick_widths = props.display_major_tick_widths
        ..display_major_tick_widths_all_helices = props.display_major_tick_widths_all_helices
        ..key = 'helices')(),
      if (props.show_mismatches)
        (DesignMainMismatches()
          ..design = props.design
          ..only_display_selected_helices = props.only_display_selected_helices
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..key = 'mismatches')(),
      (ConnectedDesignMainStrands()..key = 'strands')(),
      // after strands so can click when crossover overlaps potential crossover
      if (props.edit_modes.contains(EditModeChoice.pencil) && !props.drawing_potential_crossover)
        (DesignMainPotentialVerticalCrossovers()
          ..potential_vertical_crossovers = props.potential_vertical_crossovers
          ..helices = props.design.helices
          ..groups = props.design.groups
          ..geometry = props.design.geometry
          ..key = 'potential-vertical-crossovers')(),
      if (props.strand_creation != null)
        (DesignMainStrandCreating()
          ..helix = props.strand_creation.helix
          ..forward = props.strand_creation.forward
          ..start = props.strand_creation.start
          ..end = props.strand_creation.end
          ..color = props.strand_creation.color
          ..key = 'strand-creating')(),
      if (props.show_dna)
        (DesignMainDNASequences()
          ..helices = props.design.helices
          ..strands = props.design.strands
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..dna_sequence_png_uri = props.dna_sequence_png_uri
          ..is_zoom_above_threshold = props.is_zoom_above_threshold
          ..disable_png_cache_until_action_completes = props.disable_png_cache_until_action_completes
          ..only_display_selected_helices = props.only_display_selected_helices
          ..key = 'dna-sequences')(),
      (ConnectedPotentialCrossoverView()
        ..id = 'potential-crossover-main'
        ..key = 'potential-crossover')(),
      (ConnectedSelectionBoxView()
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_main_js())
        ..is_main = true
        ..id = 'selection-box-main'
        ..key = 'selection-box')(),
      if (props.edit_modes.contains(EditModeChoice.backbone))
        (DesignMainMouseoverRectHelices()
          ..helices = props.design.helices
          ..key = 'mouseover-rect')(),
      (ConnectedDesignMainStrandsMoving()..key = 'strands-moving')(),
    ]);

    if (USING_REACT_DND) {
      ReactComponent dnd_provider_comp = DndProvider({'backend': HTML5Backend}, main_elt);
      return dnd_provider_comp;
    } else {
      return main_elt;
    }
  }
}
