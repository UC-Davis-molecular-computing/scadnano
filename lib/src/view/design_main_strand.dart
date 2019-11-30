import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:built_collection/built_collection.dart';

import '../model/model.dart';
import '../model/select_mode.dart';
import '../app.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths.dart';

part 'design_main_strand.over_react.g.dart';

// There's a bit of a lag re-rendering the whole strand just to change its class to "hover", so we
// go around React when _OPTIMIZE=true and set the class directly by querying the element by ID.
const _OPTIMIZE = true;
//const _OPTIMIZE = false;

UiFactory<_$DesignMainStrandProps> ConnectedDesignMainStrand = connect<Model, DesignMainStrandProps>(
  mapStateToProps: (model) => (DesignMainStrand()..side_selected_helix_idxs = model.ui_model.side_selected_helix_idxs),
)(DesignMainStrand);

@Factory()
UiFactory<DesignMainStrandProps> DesignMainStrand = _$DesignMainStrand;

@Props()
class _$DesignMainStrandProps extends UiProps {
  Strand strand;
  BuiltSet<int> side_selected_helix_idxs;
  bool selected; // needed separately to compare in shouldComponentUpdated, since Strand is mutated in place
}

@Component2()
class DesignMainStrandComponent extends UiComponent2<DesignMainStrandProps> {
  @override
  Map getDefaultProps() => (newProps()..selected = false);

  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    Strand strand = props.strand;
    Strand next_strand = nextProps['DesignMainStrandProps.strand'];
    bool prev_selected = props.selected;
    bool next_selected = nextProps['DesignMainStrandProps.selected'];
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    BuiltSet<int> side_selected_helix_idxs_next = nextProps['DesignMainStrandProps.side_selected_helix_idxs'];

    bool should = !(strand == next_strand &&
        prev_selected == next_selected &&
        side_selected_helix_idxs == side_selected_helix_idxs_next);
//    print('shouldComponentUpdate() for strand ${strand.toString()}');
//    print(' prev_selected: $prev_selected');
//    print(' next_selected: $next_selected');
    return should;
  }

  @override
  render() {
    Strand strand = props.strand;
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
//    print('DesignMainStrand.render(): ${strand.toString()}');

    if (strand.substrands.length == 0) {
      return null;
    } else {
      //TODO: make strand selectable, but decide how it will interact with selecting other elements.
      var classname = 'strand';
      if (app.model.ui_model.select_mode_state.modes.contains(SelectModeChoice.strand)) {
        classname += ' selectable';
      }
//      if (state.selected) {
      if (strand.selected()) {
        classname += ' selected';
      }

      var strand_id = strand.id();
      return (Dom.g()
        ..id = strand_id
        ..onPointerDown = strand.handle_selection
        ..className = classname)([
//        (DesignMainStrandPaths()
        (ConnectedDesignMainStrandPaths()
          ..strand = strand
          ..key = 'strand-paths')(),
        ..._insertion_paths(strand, side_selected_helix_idxs),
        ..._deletion_paths(strand, side_selected_helix_idxs),
      ]);
    }
  }
}

bool draw_bound_ss(BoundSubstrand ss, BuiltSet<int> side_selected_helix_idxs) =>
    side_selected_helix_idxs.isEmpty || side_selected_helix_idxs.contains(ss.helix);

List<ReactElement> _insertion_paths(Strand strand, BuiltSet<int> side_selected_helix_idxs) {
  List<ReactElement> paths = [];
  for (BoundSubstrand substrand in strand.bound_substrands()) {
    if (draw_bound_ss(substrand, side_selected_helix_idxs)) {
      for (var insertion in substrand.insertions) {
        int offset = insertion.offset;
        ReactElement insertion_path = _insertion_path(substrand, offset, strand.color);
        ReactElement text_num_insertions = _svg_text_number_of_insertions(insertion, substrand, offset);
        paths.add(insertion_path);
        paths.add(text_num_insertions);
      }
    }
  }
  return paths;
}

ReactElement _insertion_path(BoundSubstrand substrand, int offset, Color color) {
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
  String id = util.id_insertion(substrand, offset);
  ReactElement insertion_path = (Dom.path()
    ..key = id
    ..id = id
    ..className = 'insertion-line'
    ..stroke = color.toRgbColor().toCssString()
    ..fill = 'none'
    ..d = 'M $x0 $y0 '
        'C $x1 $y1, $x2 $y2, $x3 $y2 '
        'C $x4 $y2, $x5 $y1, $x0 $y0 ')();
  return insertion_path;
}

ReactElement _svg_text_number_of_insertions(Insertion insertion, BoundSubstrand substrand, int offset) {
  // write number of insertions inside insertion loop
  int length = insertion.length;

  var dy_text = '${0.2 * constants.BASE_WIDTH_SVG}';
  if (browser.isFirefox) {
    // le sigh
    dy_text = '${0.14 * constants.BASE_WIDTH_SVG}';
  }

  String key = 'num-insertion-H${substrand.helix}-${offset}';
  SvgProps text_path_props = Dom.textPath()
    ..className = 'insertion-length'
    ..startOffset = '50%'
    ..href = '#${util.id_insertion(substrand, offset)}';
  return (Dom.text()
    ..key = key
    ..id = key
    ..dy = dy_text)(text_path_props('${length}'));
}

List<ReactElement> _deletion_paths(Strand strand, BuiltSet<int> side_selected_helix_idxs) {
  List<ReactElement> deletions = [];
  for (BoundSubstrand substrand in strand.bound_substrands()) {
    if (draw_bound_ss(substrand, side_selected_helix_idxs)) {
      for (var deletion in substrand.deletions) {
        ReactElement deletion_path = _deletion_path(substrand, deletion, strand);
        deletions.add(deletion_path);
      }
    }
  }
  return deletions;
}

ReactElement _deletion_path(BoundSubstrand substrand, int deletion_offset, Strand strand) {
//  print('app.model.dna_design.helices: ${app.model.dna_design.helices}');
//  print('  substrand: ${substrand}');
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
