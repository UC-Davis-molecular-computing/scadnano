import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';

import '../app.dart';
import '../model/helix.dart';
import '../model/dna_design.dart';
import '../model/strand.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths_crossover.dart';

part 'design_main_strand_paths.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandPathsProps> DesignMainStrandPaths = _$DesignMainStrandPaths;

@Props()
class _$DesignMainStrandPathsProps extends UiProps {
  Strand strand;
}

@Component()
class DesignMainStrandPathsComponent extends UiComponent<DesignMainStrandPathsProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    return (Dom.g()..className = 'strand-paths')(_strand_paths(this.props.strand));
  }
}

List<ReactElement> _strand_paths(Strand strand) {
  if (strand.substrands.first is Loopout) {
    throw StrandError(strand, 'loopouts at beginning of strand not supported');
  }
  if (strand.substrands.last is Loopout) {
    throw StrandError(strand, 'loopouts at end of strand not supported');
  }

  List<ReactElement> paths = [];

  var substrand = strand.substrands.first;
  for (int i = 0; i < strand.substrands.length; i++) {
    substrand = strand.substrands[i];
    if (substrand.is_bound_substrand()) {
      paths.add(_bound_substrand_line(substrand));
      if (i < strand.substrands.length - 1 && strand.substrands[i + 1].is_bound_substrand()) {
//        paths.add(_crossover_arc(strand, i));
        paths.add((DesignMainStrandPathsCrossover()
          ..strand = strand
          ..key = 'crossover-paths-$i'
          ..idx = i)());
      }
    } else {
      paths.add(_loopout_arc(strand, i));
    }
  }

  return paths;
}

ReactElement _bound_substrand_line(BoundSubstrand substrand) {
  Helix helix = app.model.dna_design.helices[substrand.helix];
  Point<num> start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
  Point<num> end_svg = helix.svg_base_pos(substrand.offset_3p, substrand.forward);
  String id = util.substrand_line_id(substrand);
  ReactElement substrand_line = (Dom.line()
    ..stroke = substrand.strand.color.toRgbColor().toCssString()
    ..x1 = '${start_svg.x}'
    ..y1 = '${start_svg.y}'
    ..x2 = '${end_svg.x}'
    ..y2 = '${end_svg.y}'
    ..onMouseUp = ((ev) => _handle_mouse_up(ev, id))
    ..key = id
    ..id = id
    ..className = 'substrand-line')();
  return substrand_line;
}

_handle_mouse_up(SyntheticMouseEvent event_syn, String id) {
  MouseEvent event = event_syn.nativeEvent;
  event_syn.stopPropagation();
  var elt = querySelector('#$id');
  print('mouse clicked on Substrand $id');
}

/// loopout arc at position i in Strand (i.e., connect bound substrands i-1 and i+1
ReactElement _loopout_arc(Strand strand, int i) {
  assert(0 < i);
  assert(i < strand.substrands.length - 1);

  var prev_ss = strand.substrands[i - 1] as BoundSubstrand;
  var next_ss = strand.substrands[i + 1] as BoundSubstrand;
  var classname = 'substrand-line';

  Loopout loopout = strand.substrands[i];
  if (util.is_hairpin(prev_ss, next_ss)) {
    // special case for hairpin so it's not a short straight line
    return _hairpin_arc(prev_ss, next_ss, loopout, classname);
  } else {
    return arc(prev_ss, next_ss, classname, id: util.loopout_id(loopout, prev_ss, next_ss));
  }
}

ReactElement _hairpin_arc(
    BoundSubstrand prev_substrand, BoundSubstrand next_substrand, Loopout loopout, String classname) {
  var helix = app.model.dna_design.helices[prev_substrand.helix];
  var start_svg = helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var end_svg = helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);
  var strand = prev_substrand.strand;

  //TODO: make a design with all loopout lengths 1-20 and calibrate this
  var w = 1.5 * util.sigmoid(loopout.length - 1) * constants.BASE_WIDTH_SVG;
  var h = 10 * util.sigmoid(loopout.length - 5) * constants.BASE_HEIGHT_SVG;
//    print('w = ${w}');
//    print('h = ${h}');

  var x_offset1, x_offset2, y_offset1, y_offset2;
  if (prev_substrand.forward) {
    x_offset1 = start_svg.x + w;
    y_offset1 = start_svg.y - h;
    x_offset2 = end_svg.x + w;
    y_offset2 = end_svg.y + h;
  } else {
    x_offset1 = start_svg.x - w;
    y_offset1 = start_svg.y + h;
    x_offset2 = end_svg.x - w;
    y_offset2 = end_svg.y - h;
  }

  var c1 = Point<num>(x_offset1, y_offset1);
  var c2 = Point<num>(x_offset2, y_offset2);

  String id = util.loopout_id(loopout, prev_substrand, next_substrand);
  ReactElement arc = (Dom.path()
    ..key = id
    ..id = id
    ..className = classname
    ..stroke = strand.color.toRgbColor().toCssString()
    ..d = 'M ${start_svg.x} ${start_svg.y} C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${end_svg.x} ${end_svg.y}')();
  return arc;
}

ReactElement arc(BoundSubstrand prev_substrand, BoundSubstrand next_substrand, String classname,
    {String id = null,
    on_mouse_up = null,
    on_mouse_enter = null,
    on_mouse_leave = null,
    String color = null}) {
  var prev_helix = app.model.dna_design.helices[prev_substrand.helix];
  var next_helix = app.model.dna_design.helices[next_substrand.helix];
  var start_svg = prev_helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var control = _control_point_for_crossover_bezier_curve(prev_substrand, next_substrand);
  var end_svg = next_helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);

  var path = 'M ${start_svg.x} ${start_svg.y} Q ${control.x} ${control.y} ${end_svg.x} ${end_svg.y}';
  if (color == null) {
    var strand = prev_substrand.strand;
    color = strand.color.toRgbColor().toCssString();
  }

  SvgProps arc_props = (Dom.path()
    ..d = path
    ..stroke = color
    ..className = classname);

  if (on_mouse_up != null) {
    arc_props.onMouseUp = on_mouse_up;
  }
  if (on_mouse_enter != null) {
    arc_props.onMouseEnter = on_mouse_enter;
  }
  if (on_mouse_leave != null) {
    arc_props.onMouseLeave = on_mouse_leave;
  }
  if (id != null) {
    arc_props.id = id;
    arc_props.key = id;
  }

  return arc_props();
}

Point<num> _control_point_for_crossover_bezier_curve(BoundSubstrand from_ss, BoundSubstrand to_ss) {
  var helix_distance = (from_ss.helix - to_ss.helix).abs();
  var from_helix = app.model.dna_design.helices[from_ss.helix];
  var to_helix = app.model.dna_design.helices[to_ss.helix];
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
