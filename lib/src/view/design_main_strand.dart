import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/select_mode_state.dart';
import '../state/app_state.dart';
import '../state/select_mode.dart';
import '../app.dart';
import '../state/strand.dart';
import '../state/bound_substrand.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths.dart';

part 'design_main_strand.over_react.g.dart';

UiFactory<_$DesignMainStrandProps> ConnectedDesignMainStrand =
    connect<AppState, DesignMainStrandProps>(mapStateToPropsWithOwnProps: (state, props) {
  bool selected = DEBUG_SELECT ? false : state.ui_state.selectables_store.selected(props.strand);
  bool selectable =
      DEBUG_SELECT ? false : state.ui_state.select_mode_state.modes.contains(SelectModeChoice.strand);
  return DesignMainStrand()
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..selected = selected
    ..selectable = selectable;
})(DesignMainStrand);

@Factory()
UiFactory<DesignMainStrandProps> DesignMainStrand = _$DesignMainStrand;

@Props()
class _$DesignMainStrandProps extends UiProps {
  Strand strand;
  BuiltSet<int> side_selected_helix_idxs;
  bool selected;
  bool selectable;
}

@Component2()
class DesignMainStrandComponent extends UiComponent2<DesignMainStrandProps> {
  @override
  Map get defaultProps => (newProps()
    ..selected = false
    ..selectable = false);

  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    Strand strand = nextProps['DesignMainStrandProps.strand'];
    bool selected = nextProps['DesignMainStrandProps.selected'];
    BuiltSet<int> side_selected_helix_idxs = nextProps['DesignMainStrandProps.side_selected_helix_idxs'];

    bool should = !(props.strand == strand &&
        props.side_selected_helix_idxs == side_selected_helix_idxs &&
        props.selected == selected);
    if (!OPTIMIZE_SELECTABLE_CSS_CLASS_MODIFICATION) {
      bool selectable = nextProps['DesignMainStrandProps.selectable'];
      should = should || (props.selectable != selectable);
    }
    return should;
  }

  @override
  render() {
    Strand strand = props.strand;
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool selected = props.selected;
    bool selectable = props.selectable;

    if (strand.substrands.length == 0) {
      return null;
    } else {
      var classname = 'strand';
      if (selectable) {
//        print('DesignMainStrand.render(): adding selectable class to strand');
        classname += ' selectable';
      } else {
//        print('DesignMainStrand.render(): not adding selectable class to strand');
      }
      if (selectable && selected) {
        classname += ' selected';
      }

      return (Dom.g()
        ..id = strand.id()
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
  var helix = app.state.dna_design.helices[substrand.helix];
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
//  print('app.state.dna_design.helices: ${app.state.dna_design.helices}');
//  print('  substrand: ${substrand}');
  var helix = app.state.dna_design.helices[substrand.helix];
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
