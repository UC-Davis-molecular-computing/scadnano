import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/select_mode_state.dart';
import 'package:scadnano/src/state/selectable.dart';

import '../app.dart';
import '../state/dna_design.dart';
import '../state/strand.dart';
import '../state/bound_substrand.dart';
import '../state/loopout.dart';
import '../constants.dart' as constants;
import 'design_main_strand_dna_end.dart';
import 'design_main_strand_bound_substrand.dart';
import 'design_main_strand_loopout.dart';
import 'design_main_strand_crossover.dart';
import 'pure_component.dart';

part 'design_main_strand_paths.over_react.g.dart';

UiFactory<_$DesignMainStrandPathsProps> ConnectedDesignMainStrandPaths =
    connect<AppState, DesignMainStrandPathsProps>(
  mapStateToProps: (state) => (DesignMainStrandPaths()
    ..helices = state.dna_design.helices
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..selectables_store = state.ui_state.selectables_store
    ..select_mode_state = state.ui_state.select_mode_state
    ..select_mode = state.ui_state.edit_modes.contains(EditModeChoice.select)
    ..pencil_mode = state.ui_state.edit_modes.contains(EditModeChoice.pencil)
    ..ligate_mode = state.ui_state.edit_modes.contains(EditModeChoice.ligate)
    ..loopout_mode = state.ui_state.edit_modes.contains(EditModeChoice.loopout)
    ..nick_mode = state.ui_state.edit_modes.contains(EditModeChoice.nick)
    ..drawing_potential_crossover = state.ui_state.drawing_potential_crossover
    ..moving_dna_ends = state.ui_state.moving_dna_ends
    ..show_mouseover_rect = state.ui_state.edit_modes.contains(EditModeChoice.backbone)),
)(DesignMainStrandPaths);

@Factory()
UiFactory<DesignMainStrandPathsProps> DesignMainStrandPaths = _$DesignMainStrandPaths;

@Props()
class _$DesignMainStrandPathsProps extends UiProps {
  Strand strand;
  BuiltSet<int> side_selected_helix_idxs;

  BuiltList<Helix> helices;
  SelectablesStore selectables_store;
  SelectModeState select_mode_state;
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
class DesignMainStrandPathsComponent extends UiComponent2<DesignMainStrandPathsProps> with PureComponent {
  @override
  render() {
    return (Dom.g()..className = 'strand-paths')(_strand_paths());
  }

  bool should_draw_bound_ss(int helix_idx, BuiltSet<int> side_selected_helix_idxs) =>
      side_selected_helix_idxs.isEmpty || side_selected_helix_idxs.contains(helix_idx);

  List<ReactElement> _strand_paths() {
    Strand strand = props.strand;
    if (strand.substrands.first is Loopout) {
      throw StrandError(strand, 'loopouts at beginning of strand not supported');
    }
    if (strand.substrands.last is Loopout) {
      throw StrandError(strand, 'loopouts at end of strand not supported');
    }

    List<ReactElement> paths = [];
    List<ReactElement> ends = []; // add after so clicking on ends takes priority
    var substrand = strand.substrands.first;

    bool draw_prev_ss = false;
    for (int i = 0; i < strand.substrands.length; i++) {
      substrand = strand.substrands[i];

      if (substrand is BoundSubstrand) {
        Helix helix = props.helices[substrand.helix];
        bool draw_cur_ss = should_draw_bound_ss(substrand.helix, props.side_selected_helix_idxs);
        draw_prev_ss = draw_cur_ss;
        if (draw_cur_ss) {
//          paths.add((ConnectedDesignMainBoundSubstrand()
          paths.add((DesignMainBoundSubstrand()
            ..substrand = substrand
            ..color = strand.color
            ..dna_sequence = strand.dna_sequence_in(substrand)
            ..helix = helix
            ..nick_mode_enabled = props.nick_mode
            ..key = "bound-substrand-$i")());

//        ends.add((ConnectedDesignMainDNAEnd()
          bool is_5p = true;
          for (DNAEnd end in [substrand.dnaend_5p, substrand.dnaend_3p]) {
            String key = is_5p
                ? "5'-end-$i${substrand.is_first ? '-is_first' : ''}"
                : "3'-end-$i${substrand.is_last ? '-is_last' : ''}";
            bool selected = props.selectables_store.selected(end);
            ends.add((DesignMainDNAEnd()
              ..substrand = substrand
              ..is_5p = is_5p
              ..color = strand.color
              ..helix = helix
              ..selected = selected
              ..selectable = props.select_mode_state.is_selectable(end)
              ..select_mode = props.select_mode
              ..pencil_mode = props.pencil_mode
              ..ligate_mode = props.ligate_mode
              ..moving_this_dna_end = props.moving_dna_ends && selected
              ..drawing_potential_crossover = props.drawing_potential_crossover
              ..key = key)());
            is_5p = false;
          }
        }
      } else if (substrand is Loopout) {
        BoundSubstrand next_ss = strand.substrands[i + 1];
        bool draw_next_ss = should_draw_bound_ss(next_ss.helix, props.side_selected_helix_idxs);
        if (draw_prev_ss && draw_next_ss) {
//          paths.add((ConnectedDesignMainLoopout()
          paths.add((DesignMainLoopout()
            ..loopout = substrand
            ..strand = strand
            ..color = strand.color
            ..selected = props.selectables_store.selected(substrand)
            ..selectable = props.select_mode_state.is_selectable(substrand)
            ..select_mode = props.select_mode
            ..show_mouseover_rect = props.show_mouseover_rect
            ..prev_substrand = strand.substrands[i - 1]
            ..next_substrand = next_ss
            ..loopout_edit_mode_enabled = props.loopout_mode
            ..key = "loopout-$i")());
        }
      }
    }

    int idx_crossover = 0;
    for (var crossover in strand.crossovers) {
      BoundSubstrand next_ss = strand.substrands[crossover.next_substrand_idx];
      bool draw_next_ss = should_draw_bound_ss(next_ss.helix, props.side_selected_helix_idxs);
      if (draw_next_ss) {
        var crossover = strand.crossovers[idx_crossover++];

        int prev_idx = crossover.prev_substrand_idx;
        int next_idx = crossover.next_substrand_idx;
        var prev_ss = strand.substrands[prev_idx];
        var next_ss = strand.substrands[next_idx];
        bool selected = props.selectables_store.selected(crossover);
        bool selectable = props.select_mode_state.is_selectable(crossover);

//        paths.add((ConnectedDesignMainStrandCrossover()
        paths.add((DesignMainStrandCrossover()
          ..crossover = crossover
          ..strand = strand
          ..selected = selected
          ..selectable = selectable
          ..select_mode = props.select_mode
          ..show_mouseover_rect = props.show_mouseover_rect
          ..prev_substrand = prev_ss
          ..next_substrand = next_ss
          ..loopout_edit_mode_enabled = props.loopout_mode
          ..key = 'crossover-paths-${idx_crossover - 1}')());
      }
    }

    return paths + ends;
  }
}

String crossover_path_description(BoundSubstrand prev_substrand, BoundSubstrand next_substrand) {
  var prev_helix = app.state.dna_design.helices[prev_substrand.helix];
  var next_helix = app.state.dna_design.helices[next_substrand.helix];
  var start_svg = prev_helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var control = _control_point_for_crossover_bezier_curve(prev_substrand, next_substrand);
  var end_svg = next_helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);

  var path = 'M ${start_svg.x} ${start_svg.y} Q ${control.x} ${control.y} ${end_svg.x} ${end_svg.y}';

  return path;
}

Point<num> _control_point_for_crossover_bezier_curve(BoundSubstrand from_ss, BoundSubstrand to_ss) {
  var helix_distance = (from_ss.helix - to_ss.helix).abs();
  var from_helix = app.state.dna_design.helices[from_ss.helix];
  var to_helix = app.state.dna_design.helices[to_ss.helix];
  var start_pos = from_helix.svg_base_pos(from_ss.offset_3p, from_ss.forward);
  var end_pos = to_helix.svg_base_pos(to_ss.offset_5p, to_ss.forward);
  bool from_strand_below = from_ss.helix - to_ss.helix > 0;
  num midX = (start_pos.x + end_pos.x) / 2;
  num midY = (start_pos.y + end_pos.y) / 2;
  Point<num> mid = Point<num>(midX, midY);
  Point<num> control;
  Point<num> vector = end_pos - start_pos;
  Point<num> normal = Point<num>(vector.y, -vector.x);
  if ((!from_ss.forward && from_strand_below) || (from_ss.forward && !from_strand_below)) {
    normal = Point<num>(-vector.y, vector.x);
  }
  Point<num> unit_normal = normal * (1 / normal.magnitude);
  // This scale seems to look good even with many crossovers at same column,
  // e.g., long_range_crossovers.py in the examples directory.
  double scale = helix_distance * 0.5;
  Point<num> scale_normal = unit_normal * scale;
  control = mid + scale_normal * (constants.BASE_WIDTH_SVG / 2);
  return control;
}

//  _draw_strand_lines_single_path() {
//    if (this.strand.substrands.length == 0) {
//      return;
//    }
//    var substrand = this.strand.substrands.first;
//    var helix = app.state.dna_design.helices[substrand.helix_idx];
//    var start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
//    var path_cmds = ['M ${start_svg.x} ${start_svg.y}'];
//    for (int i = 0; i < this.strand.substrands.length; i++) {
//      // substrand line
//      var end_svg = helix.svg_base_pos(substrand.offset_3p, substrand.forward);
//      path_cmds.add('L ${end_svg.x} ${end_svg.y}');
//
//      // crossover line/arc
//      if (i < this.strand.substrands.length - 1) {
//        var old_substrand = substrand;
//        substrand = this.strand.substrands[i + 1];
//        helix = app.state.dna_design.helices[substrand.helix_idx];
//        start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
//        var control = _control_point_for_crossover_bezier_curve(old_substrand, substrand);
//        path_cmds.add('Q ${control.x} ${control.y} ${start_svg.x} ${start_svg.y}');
//      }
//    }
//
//    var path = svg.PathElement();
//    path.attributes = {
//      'id': substrand_line_id(substrand),
//      'class': 'substrand-line',
//      'stroke': strand.color.toRgbColor().toCssString(),
//      'fill': 'none',
//      'd': path_cmds.join(' '),
//    };
//    this.root_element.children.add(path);
//  }
