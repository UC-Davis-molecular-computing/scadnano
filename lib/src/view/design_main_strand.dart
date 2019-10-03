import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:tuple/tuple.dart';

import '../app.dart';
import '../model/strand.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths.dart';

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
        (DesignMainStrandPaths()
          ..strand = this.props.strand
          ..key = 'strand-paths')(),
        _5p_end(this.props.strand),
        _3p_end(this.props.strand),
        ..._insertion_paths(this.props.strand),
        ..._deletion_paths(this.props.strand),
      ]);
    }
  }
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
  SvgProps text_path_props = Dom.textPath()
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
