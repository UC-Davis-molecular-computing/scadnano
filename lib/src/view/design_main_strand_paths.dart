import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/model/app_state.dart';

import '../model/crossover.dart';
import 'design_main_strand_3p_end.dart';
import 'design_main_strand_5p_end.dart';
import '../app.dart';
import '../model/dna_design.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import '../model/loopout.dart';
import '../constants.dart' as constants;
import 'design_main_strand_bound_substrand.dart';
import 'design_main_strand_loopout.dart';
import 'design_main_strand_crossover.dart';

part 'design_main_strand_paths.over_react.g.dart';

UiFactory<_$DesignMainStrandPathsProps> ConnectedDesignMainStrandPaths =
    connect<AppState, DesignMainStrandPathsProps>(
  mapStateToProps: (state) =>
      (DesignMainStrandPaths()..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs),
)(DesignMainStrandPaths);

@Factory()
UiFactory<DesignMainStrandPathsProps> DesignMainStrandPaths = _$DesignMainStrandPaths;

@Props()
class _$DesignMainStrandPathsProps extends UiProps {
  Strand strand;
  BuiltSet<int> side_selected_helix_idxs;
}

@Component2()
class DesignMainStrandPathsComponent extends UiComponent2<DesignMainStrandPathsProps> {
  @override
  render() {
    return (Dom.g()..className = 'strand-paths')(_strand_paths(props.strand, props.side_selected_helix_idxs));
  }
}

bool draw_bound_ss(BoundSubstrand ss, BuiltSet<int> side_selected_helix_idxs) =>
    side_selected_helix_idxs.isEmpty || side_selected_helix_idxs.contains(ss.helix);

List<ReactElement> _strand_paths(Strand strand, BuiltSet<int> side_selected_helix_idxs) {
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

    if (substrand.is_bound_substrand()) {
      BoundSubstrand bound_ss = substrand as BoundSubstrand;
      bool draw_cur_ss = draw_bound_ss(bound_ss, side_selected_helix_idxs);
      draw_prev_ss = draw_cur_ss;
      if (draw_cur_ss) {
        paths.add((ConnectedDesignMainBoundSubstrand()
          ..substrand = substrand
          ..color = strand.color
          ..key = "bound-substrand-$i")());

        ends.add((ConnectedDesignMain5pEnd()
          ..substrand = substrand
          ..color = strand.color
          ..is_first_substrand = (i == 0)
          ..key = "5'-end-$i")());

        ends.add((ConnectedDesignMain3pEnd()
          ..substrand = substrand
          ..color = strand.color
          ..is_last_substrand = (i == strand.substrands.length - 1)
          ..key = "3'-end-$i")());
      }

      if (i < strand.substrands.length - 1 && strand.substrands[i + 1].is_bound_substrand() && draw_cur_ss) {
        BoundSubstrand prev_ss = substrand;
        BoundSubstrand next_ss = strand.substrands[i + 1];
        bool draw_next_ss = draw_bound_ss(next_ss, side_selected_helix_idxs);

        if (draw_next_ss) {
          Crossover crossover = Crossover(prev_ss, next_ss);

//          paths.add((DesignMainStrandCrossover()
          paths.add((ConnectedDesignMainStrandCrossover()
            ..crossover = crossover
            ..strand = strand
            ..key = 'crossover-paths-$i')());
        }
      }
    } else {
      BoundSubstrand next_ss = strand.substrands[i + 1];
      bool draw_next_ss = draw_bound_ss(next_ss, side_selected_helix_idxs);
      if (draw_prev_ss && draw_next_ss) {
        paths.add((ConnectedDesignMainLoopout()
          ..loopout = substrand
          ..color = strand.color
          ..key = "loopout-$i")());
      }
    }
  }

  return paths + ends;
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
//    var helix = app.model.dna_design.helices[substrand.helix_idx];
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
//        helix = app.model.dna_design.helices[substrand.helix_idx];
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
