library view_main;

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/potential_vertical_crossover.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/strand_creation.dart';
import 'package:scadnano/src/state/strands_move.dart';
import 'package:scadnano/src/view/design_main_strand_creating.dart';
import 'package:scadnano/src/view/design_main_strands_moving.dart';

import 'design_main_mismatches.dart';
import 'design_main_helices.dart';
import 'design_main_potential_vertical_crossovers.dart';
import 'design_main_strands.dart';
import 'design_main_dna_sequences.dart';
import 'design_main_mouseover_rect_helices.dart';
import '../state/app_state.dart';
import 'edit_mode_queryable.dart';
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
        ..helices = state.dna_design.helices
        ..strands = state.dna_design.strands
        ..potential_vertical_crossovers = state.dna_design.potential_vertical_crossovers
        ..drawing_potential_crossover = state.ui_state.drawing_potential_crossover
        ..has_error = state.has_error()
        ..edit_modes = state.ui_state.edit_modes
        ..strands_move = state.ui_state.strands_move
        ..strand_creation = state.ui_state.strand_creation
        ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
        ..show_mismatches = state.ui_state.show_mismatches
        ..show_dna = state.ui_state.show_dna
        ..design_major_tick_distance = state.dna_design.major_tick_distance
        ..dna_sequence_png_uri = state.ui_state.dna_sequence_png_uri
        ..disable_png_cache_until_action_completes = state.ui_state.disable_png_cache_until_action_completes
        ..is_zoom_above_threshold = state.ui_state.is_zoom_above_threshold
        ..only_display_selected_helices = state.ui_state.only_display_selected_helices);
    }
  },
)(DesignMain);

@Factory()
UiFactory<DesignMainProps> DesignMain = _$DesignMain;

@Props()
mixin DesignMainPropsMixin on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltList<Strand> strands;
  BuiltList<PotentialVerticalCrossover> potential_vertical_crossovers;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltSet<EditModeChoice> edit_modes;
  StrandsMove strands_move;
  StrandCreation strand_creation;
  bool has_error;
  bool show_mismatches;
  bool show_dna;
  int design_major_tick_distance;
  bool drawing_potential_crossover;
  String dna_sequence_png_uri;
  Action disable_png_cache_until_action_completes;
  bool is_zoom_above_threshold;
  bool only_display_selected_helices;
}

@Props()
class DesignMainProps = UiProps with EditModePropsMixin, DesignMainPropsMixin;

@Component2()
class DesignMainComponent extends UiComponent2<DesignMainProps> with EditModeQueryable<DesignMainProps> {
  @override
  get consumedProps => propsMeta.forMixins({DesignMainPropsMixin});

  @override
  render() {
    if (props.has_error) {
      return null;
    }

    ReactElement main_elt = (Dom.g()..id = 'main-view-group')([
      (DesignMainHelices()
        ..helices = props.helices
        ..strand_create_enabled = props.edit_modes.contains(EditModeChoice.pencil)
        ..side_selected_helix_idxs = props.side_selected_helix_idxs
        ..design_major_tick_distance = props.design_major_tick_distance
        ..only_display_selected_helices = props.only_display_selected_helices
        ..key = 'helices')(),
      (DesignMainMismatches()
        ..show_mismatches = props.show_mismatches
        ..strands = props.strands
        ..key = 'mismatches')(),
      (ConnectedDesignMainStrands()..key = 'strands')(),
      // after strands so can click when crossover overlaps potential crossover
      if (pencil_mode && !props.drawing_potential_crossover)
        (DesignMainPotentialVerticalCrossovers()
          ..potential_vertical_crossovers = props.potential_vertical_crossovers
          ..helices = props.helices
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
          ..helices = props.helices
          ..strands = props.strands
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..dna_sequence_png_uri = props.dna_sequence_png_uri
          ..is_zoom_above_threshold = props.is_zoom_above_threshold
          ..disable_png_cache_until_action_completes = props.disable_png_cache_until_action_completes
          ..only_display_selected_helices = props.only_display_selected_helices
          ..key = 'dna')(),
      (ConnectedPotentialCrossoverView()
        ..id = 'potential-crossover-main'
        ..key = 'potential-crossover')(),
      (ConnectedSelectionBoxView()
        ..stroke_width_getter = (() => 2.0 / util.current_zoom_main_js())
        ..is_main = true
        ..id = 'selection-box-main'
        ..key = 'selection-box')(),
      if (backbone_mode)
        (DesignMainMouseoverRectHelices()
          ..helices = props.helices
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
