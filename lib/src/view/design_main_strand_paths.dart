import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/dispatcher/actions.dart';

import '../app.dart';
import '../model/helix.dart';
import '../model/dna_design.dart';
import '../model/strand.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_mouseover_rect_helix.dart';
import 'design_main_strand_paths_crossover.dart';

part 'design_main_strand_paths.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandPathsProps> DesignMainStrandPaths = _$DesignMainStrandPaths;

@Props()
class _$DesignMainStrandPathsProps extends UiProps {
  Strand strand;
  String strand_id;
}

@Component()
class DesignMainStrandPathsComponent extends UiComponent<DesignMainStrandPathsProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    return (Dom.g()..className = 'strand-paths')(_strand_paths(this.props.strand, this.props.strand_id));
  }
}

List<ReactElement> _strand_paths(Strand strand, String strand_id) {
  if (strand.substrands.first is Loopout) {
    throw StrandError(strand, 'loopouts at beginning of strand not supported');
  }
  if (strand.substrands.last is Loopout) {
    throw StrandError(strand, 'loopouts at end of strand not supported');
  }

  List<ReactElement> paths = [];
  List<ReactElement> ends = []; // add after so clicking on ends takes priority
  var substrand = strand.substrands.first;

  for (int i = 0; i < strand.substrands.length; i++) {
    substrand = strand.substrands[i];
    if (substrand.is_bound_substrand()) {
      paths.add(_bound_substrand_line(substrand, strand_id));
      ends.add(_5p_end(substrand, i));
      ends.add(_3p_end(substrand, i));
      if (i < strand.substrands.length - 1 && strand.substrands[i + 1].is_bound_substrand()) {
        paths.add((DesignMainStrandPathsCrossover()
          ..strand = strand
          ..idx = i
          ..key = 'crossover-paths-$i')());
      }
    } else {
      paths.add(_loopout_arc(strand, i));
    }
  }

  return paths + ends;
}

ReactElement _5p_end(BoundSubstrand substrand, int substrand_order) {
//  var first_ss = strand.first_bound_substrand();
  var helix = app.model.dna_design.helices[substrand.helix];
  var offset = substrand.offset_5p;
  var right = substrand.forward;
  var pos = helix.svg_base_pos(offset, right);

  bool is_first_substrand = substrand_order == 0;
  var classname = 'five-prime-end' + (is_first_substrand ? '-first-substrand' : '');

  //XXX: width, height, rx, ry should be do-able in CSS, but Firefox won't display properly
  // if they are specified in CSS, but it will if they are specified here
  String key = "5'-end-$substrand_order";
  ReactElement box = (Dom.rect()
    ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
    ..onMouseMove = ((event) => update_mouseover(event, helix))
    ..key = key
    ..id = key
    ..className = classname
    ..x = '${pos.x - 3.5}'
    ..y = '${pos.y - 3.5}'
    ..width = '7px'
    ..height = '7px'
    ..rx = '1.5px'
    ..ry = '1.5px'
    ..fill = substrand.strand.color.toRgbColor().toCssString())();
  return box;
}

ReactElement _3p_end(BoundSubstrand substrand, int substrand_order) {
  var offset = substrand.offset_3p;
  var direction = substrand.forward;
  var helix = app.model.dna_design.helices[substrand.helix];
  var pos = helix.svg_base_pos(offset, direction);
  var points;
  num scale = 3.7;
  if (!substrand.forward) {
    points = '${pos.x - scale},${pos.y} '
        '${pos.x + 0.9 * scale},${pos.y + scale} '
        '${pos.x + 0.9 * scale},${pos.y - scale}';
  } else {
    points = '${pos.x + scale},${pos.y} '
        '${pos.x - 0.9 * scale},${pos.y + scale} '
        '${pos.x - 0.9 * scale},${pos.y - scale}';
  }

  bool is_last_substrand = substrand_order == substrand.strand.bound_substrands().length - 1;
  var classname = 'three-prime-end' + (is_last_substrand ? '-last-substrand' : '');
  String key = "3'-end-$substrand_order";
  ReactElement triangle = (Dom.polygon()
    ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
    ..onMouseMove = ((event) => update_mouseover(event, helix))
    ..key = key
    ..id = key
    ..className = classname
    ..points = points
    ..fill = substrand.strand.color.toRgbColor().toCssString())();
  return triangle;
}

// There's a bit of a lag re-rendering the whole strand just to change its class to "hover", so we
// go around React when OPT=true and set the class directly by querying the element by ID.
const OPT = true;
//const OPT = false;

ReactElement _bound_substrand_line(BoundSubstrand substrand, String strand_id) {
  Helix helix = app.model.dna_design.helices[substrand.helix];
  Point<num> start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
  Point<num> end_svg = helix.svg_base_pos(substrand.offset_3p, substrand.forward);
  String id = util.substrand_line_id(substrand);
  Strand strand = substrand.strand;
  ReactElement substrand_line = (Dom.line()
    ..onMouseEnter = ((_) {
      if (OPT) {
        print('querying for elt with id #${strand_id}');
        Element strand_elt = querySelector('#${strand_id}');
        strand_elt.classes.add('hover');
      } else {
        Actions.add_strand_hover(strand);
      }
    })
    ..onMouseLeave = ((_) {
      if (OPT) {
        Element strand_elt = querySelector('#${strand_id}');
        strand_elt.classes.remove('hover');
      } else {
        Actions.remove_strand_hover(strand);
      }
      mouse_leave_update_mouseover();
    })
    ..onMouseMove = ((event) => update_mouseover(event, helix))
    ..stroke = substrand.strand.color.toRgbColor().toCssString()
    ..x1 = '${start_svg.x}'
    ..y1 = '${start_svg.y}'
    ..x2 = '${end_svg.x}'
    ..y2 = '${end_svg.y}'
    ..key = id
    ..id = id
    ..className = 'substrand-line')();
  return substrand_line;
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
    String path = crossover_path_description(prev_ss, next_ss);
    String id = util.loopout_id(loopout, prev_ss, next_ss);
    String color = strand.color.toRgbColor().toCssString();
    return (Dom.path()
      ..d = path
      ..stroke = color
      ..className = classname
      ..id = id
      ..key = id)();
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

String crossover_path_description(BoundSubstrand prev_substrand, BoundSubstrand next_substrand) {
  var prev_helix = app.model.dna_design.helices[prev_substrand.helix];
  var next_helix = app.model.dna_design.helices[next_substrand.helix];
  var start_svg = prev_helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var control = _control_point_for_crossover_bezier_curve(prev_substrand, next_substrand);
  var end_svg = next_helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);

  var path = 'M ${start_svg.x} ${start_svg.y} Q ${control.x} ${control.y} ${end_svg.x} ${end_svg.y}';

  return path;
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
