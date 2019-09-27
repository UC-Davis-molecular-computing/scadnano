import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:tuple/tuple.dart';

import '../model/helix.dart';
import '../app.dart';
import '../model/dna_design.dart';
import '../model/strand.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'design_main_strand.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandProps> DesignMainStrand = _$DesignMainStrand;

@Props()
class _$DesignMainStrandProps extends UiProps {
  Strand strand;
}

@Component()
class DesignMainStrandComponent extends UiComponent<DesignMainStrandProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    if (this.props.strand.substrands.length == 0) {
      return null;
    } else {
      return (Dom.g()..className = 'strand')([
        ..._strand_paths(this.props.strand),
        _5p_end(this.props.strand),
        _3p_end(this.props.strand),
        ..._insertion_paths(this.props.strand),
        ..._deletion_paths(this.props.strand),
      ]);
    }
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
        paths.add(_crossover_arc(strand, i));
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
    ..key = id
    ..id = id
    ..className = 'substrand-line'
    ..stroke = substrand.strand.color.toRgbColor().toCssString()
    ..x1 = '${start_svg.x}'
    ..y1 = '${start_svg.y}'
    ..x2 = '${end_svg.x}'
    ..y2 = '${end_svg.y}')();
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
    return _arc(prev_ss, next_ss, classname, id: util.loopout_id(loopout, prev_ss, next_ss));
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

/// crossover arc from bound substrand i to bound substrand i+1
ReactElement _crossover_arc(Strand strand, int i) {
  assert(i < strand.substrands.length - 1);
  assert(strand.substrands[i].is_bound_substrand());
  assert(strand.substrands[i + 1].is_bound_substrand());

  var prev_substrand = strand.substrands[i] as BoundSubstrand;
  var next_substrand = strand.substrands[i + 1] as BoundSubstrand;
  var classname = 'crossover-curve';

  return _arc(prev_substrand, next_substrand, classname, id: 'crossover-${i}-${strand.toString()}');
}

ReactElement _arc(BoundSubstrand prev_substrand, BoundSubstrand next_substrand, String classname,
    {String id = null}) {
  var prev_helix = app.model.dna_design.helices[prev_substrand.helix];
  var next_helix = app.model.dna_design.helices[next_substrand.helix];
  var start_svg = prev_helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var control = _control_point_for_crossover_bezier_curve(prev_substrand, next_substrand);
  var end_svg = next_helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);
  var strand = prev_substrand.strand;

  SvgProps arc_props = (Dom.path()
    ..className = classname
    ..stroke = strand.color.toRgbColor().toCssString()
    ..d = 'M ${start_svg.x} ${start_svg.y} Q ${control.x} ${control.y} ${end_svg.x} ${end_svg.y}');
  if (id != null) {
    arc_props.addProp('id', id);
    arc_props.addProp('key', id);
  }
  return arc_props();
}

ReactElement _5p_end(Strand strand) {
  var first_ss = strand.first_bound_substrand();
  var helix = app.model.dna_design.helices[first_ss.helix];
  var offset = first_ss.offset_5p;
  var right = first_ss.forward;
  var pos = helix.svg_base_pos(offset, right);

  //XXX: width, height, rx, ry should be do-able in CSS, but Firefox won't display properly
  // if they are specified in CSS, but it will if they are specified here
  String key = "5'-end";
  ReactElement box = (Dom.rect()
    ..key = key
    ..id = key
    ..className = 'five-prime-end'
    ..x = '${pos.x - 3}'
    ..y = '${pos.y - 3}'
    ..width = '6px'
    ..height = '6px'
    ..rx = '1.5px'
    ..ry = '1.5px'
    ..fill = strand.color.toRgbColor().toCssString())();
  return box;
}

ReactElement _3p_end(Strand strand) {
  var last_ss = strand.last_bound_substrand();
  var offset = last_ss.offset_3p;
  var direction = last_ss.forward;
  var helix = app.model.dna_design.helices[last_ss.helix];
  var pos = helix.svg_base_pos(offset, direction);
  var points;
  num scale = 3.5;
  if (!last_ss.forward) {
    points = '${pos.x - scale * 0.8},${pos.y} '
        '${pos.x + scale},${pos.y + scale} '
        '${pos.x + scale},${pos.y - scale}';
  } else {
    points = '${pos.x + scale * 0.8},${pos.y} '
        '${pos.x - scale},${pos.y + scale} '
        '${pos.x - scale},${pos.y - scale}';
  }
  String key = "3'-end";
  ReactElement triangle = (Dom.polygon()
    ..key = key
    ..id = key
    ..className = 'three-prime-end'
    ..points = points
    ..fill = strand.color.toRgbColor().toCssString())();
  return triangle;
}

List<ReactElement> _insertion_paths(Strand strand) {
  List<ReactElement> paths = [];
  for (BoundSubstrand substrand in strand.bound_substrands()) {
    for (var insertion in substrand.insertions) {
      int offset = insertion.item1;
      ReactElement insertion_path = _insertion_path(substrand, offset);
      ReactElement text_num_insertions = _svg_text_number_of_insertions(insertion, substrand, offset);
      paths.add(insertion_path);
      paths.add(text_num_insertions);
    }
  }
  return paths;
}

ReactElement _insertion_path(BoundSubstrand substrand, int offset) {
  var helix = app.model.dna_design.helices[substrand.helix];
  Point<num> pos = helix.svg_base_pos(offset, substrand.forward);

  num dx1 = constants.BASE_WIDTH_SVG;
  num dx2 = 0.5 * constants.BASE_WIDTH_SVG;
  num dy1 = 2 * constants.BASE_HEIGHT_SVG;
  num dy2 = 2 * constants.BASE_HEIGHT_SVG;
  if (substrand.forward) {
    dy1 = -dy1;
    dy2 = -dy2;
    dx1 = -dx1;
    dx2 = -dx2;
  }
  num x0 = pos.x;
  num y0 = pos.y;
  var x1 = (x0 + dx1).toStringAsFixed(2);
  var x2 = (x0 + dx2).toStringAsFixed(2);
  var x3 = x0.toStringAsFixed(2);
  var x4 = (x0 - dx2).toStringAsFixed(2);
  var x5 = (x0 - dx1).toStringAsFixed(2);

  var y1 = (y0 + dy1).toStringAsFixed(2);
  var y2 = (y0 + dy2).toStringAsFixed(2);

//  String key = 'insertion-H${substrand.helix}-${offset}';
  String id = util.insertion_id(substrand, offset);
  ReactElement insertion_path = (Dom.path()
    ..key = id
    ..id = id
    ..className = 'insertion-line'
    ..stroke = substrand.strand.color.toRgbColor().toCssString()
    ..fill = 'none'
    ..d = 'M $x0 $y0 '
        'C $x1 $y1, $x2 $y2, $x3 $y2 '
        'C $x4 $y2, $x5 $y1, $x0 $y0 ')();
  return insertion_path;
}

ReactElement _svg_text_number_of_insertions(
    Tuple2<int, int> insertion, BoundSubstrand substrand, int offset) {
  // write number of insertions inside insertion loop
  int length = insertion.item2;

  var dy_text = '${0.2 * constants.BASE_WIDTH_SVG}';
  if (browser.isFirefox) {
    // le sigh
    dy_text = '${0.14 * constants.BASE_WIDTH_SVG}';
  }

  String key = 'num-insertion-H${substrand.helix}-${offset}';
  String key_textpath = 'textpath-$key';
  SvgProps text_path_props = Dom.textPath()
//    ..key = key_textpath
//    ..id = key_textpath
    ..className = 'insertion-length'
    ..href = '#${util.insertion_id(substrand, offset)}';
  text_path_props.addProp('startOffset', '50%');
  return (Dom.text()
    ..key = key
    ..id = key
    ..dy = dy_text)(text_path_props('${length}'));
}

List<ReactElement> _deletion_paths(Strand strand) {
  List<ReactElement> deletions = [];
  for (BoundSubstrand substrand in strand.bound_substrands()) {
    for (var deletion in substrand.deletions) {
      ReactElement deletion_path = _deletion_path(substrand, deletion, strand);
      deletions.add(deletion_path);
    }
  }
  return deletions;
}

ReactElement _deletion_path(BoundSubstrand substrand, int deletion_offset, Strand strand) {
  var helix = app.model.dna_design.helices[substrand.helix];
  Point<num> pos = helix.svg_base_pos(deletion_offset, substrand.forward);

  var width = 0.8 * constants.BASE_WIDTH_SVG;
  var half_width = 0.5 * width;
  var path_cmds = 'M ${pos.x - half_width} ${pos.y - half_width} '
      'l ${width} ${width} m ${-width} ${0} l ${width} ${-width}';

  String key = 'deletion-H${substrand.helix}-${deletion_offset}';
  ReactElement deletion_path = (Dom.path()
    ..key = key
    ..id = key
    ..className = 'deletion-cross'
    ..stroke = strand.color.toRgbColor().toCssString()
    ..fill = 'none'
    ..d = path_cmds)();
  return deletion_path;
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
