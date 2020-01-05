import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/reducers/strands_reducer.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_end.dart';

import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/view/design_main_strand_dna_end_moving.dart';

import 'design_main_strand_paths.dart';

part 'design_main_strand_moving.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandMovingProps> DesignMainStrandMoving = _$DesignMainStrandMoving;

@Props()
class _$DesignMainStrandMovingProps extends UiProps {
  Strand strand;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltList<Helix> helices;
  int delta_helix_idx;
  int delta_offset;
  bool delta_forward;
  bool allowable;
}

@Component2()
class DesignMainStrandMovingComponent extends UiComponent2<DesignMainStrandMovingProps> {
  @override
  render() {
    if (props.strand.substrands.length == 0) {
      return null;
    }

    BoundSubstrand first_ss = props.strand.first_bound_substrand();
    BoundSubstrand last_ss = props.strand.last_bound_substrand();
    DNAEnd end_5p = first_ss.dnaend_5p;
    DNAEnd end_3p = last_ss.dnaend_3p;
    return (Dom.g()..className = 'strand-moving')([
//        (ConnectedDesignMainStrandPaths()
      _draw_strand_lines_single_path(),
      (EndMoving()
        ..dna_end = end_5p
        ..original_offset = end_5p.offset_inclusive
        ..color = props.strand.color
        ..forward = props.delta_forward != first_ss.forward
        ..helix = props.helices[first_ss.helix + props.delta_helix_idx]
        ..is_5p = true
        ..allowable = props.allowable
        ..current_offset =
            (props.delta_forward ? end_3p.offset_inclusive : end_5p.offset_inclusive) + props.delta_offset
        ..key = 'end-5p')(),
      (EndMoving()
        ..dna_end = end_3p
        ..original_offset = end_3p.offset_inclusive
        ..color = props.strand.color
        ..forward = props.delta_forward != last_ss.forward
        ..helix = props.helices[last_ss.helix + props.delta_helix_idx]
        ..is_5p = false
        ..allowable = props.allowable
        ..current_offset =
            (props.delta_forward ? end_5p.offset_inclusive : end_3p.offset_inclusive) + props.delta_offset
        ..key = 'end-3p')(),
    ]);
  }

  ReactElement _draw_strand_lines_single_path() {
    Strand strand_moved = moved_strand(props.strand,
        delta_helix_idx: props.delta_helix_idx,
        delta_offset: props.delta_offset,
        delta_forward: props.delta_forward);

    List<BoundSubstrand> bound_substrands = strand_moved.bound_substrands();
    BoundSubstrand substrand = bound_substrands.first;

    var helix = props.helices[substrand.helix];
    var start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
    var path_cmds = ['M ${start_svg.x} ${start_svg.y}'];

    for (int i = 0; i < bound_substrands.length; i++) {
      // substrand line
      var end_svg = helix.svg_base_pos(substrand.offset_3p, substrand.forward);
      path_cmds.add('L ${end_svg.x} ${end_svg.y}');

      // crossover/loopout line/arc
      if (i < bound_substrands.length - 1) {
        var old_substrand = substrand;
        substrand = bound_substrands[i + 1];
        helix = props.helices[substrand.helix];
        start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
        var control = control_point_for_crossover_bezier_curve(old_substrand, substrand);
        path_cmds.add('Q ${control.x} ${control.y} ${start_svg.x} ${start_svg.y}');
      }
    }

    int key = 0;
    var path = (Dom.path()
//      ..id= substrand_line_id(substrand),
      ..className = 'substrand-line' + (props.allowable ? '' : ' disallowed')
      ..stroke = props.strand.color.toRgbColor().toCssString()
      ..fill = 'none'
      ..d = path_cmds.join(' ')
      ..key = key++)();

    return path;
  }
}
