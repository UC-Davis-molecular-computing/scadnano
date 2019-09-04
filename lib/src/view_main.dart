@JS()
library view_main;

import 'dart:html';
import 'dart:math';
import 'dart:svg' as svg; // hide Point;

import 'package:js/js.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:quiver/iterables.dart' as iter;

import 'strand.dart';
import 'actions.dart';
import 'package:tuple/tuple.dart';
import 'view.dart';
import 'model.dart';
import 'app.dart';
import 'util.dart' as util;
import 'constants.dart' as constants;

//const DEBUG_PRINT_MOUSEOVER = false;
const DEBUG_PRINT_MOUSEOVER = true;

const String MAIN_VIEW_PREFIX = 'main-view';

//TODO: display width of each column lightly above helix 0; alternately, display as mouseover information

class MainViewComponent {
  final svg.GElement root_element;

  // There's no layering in SVG, so we need to make sure we draw DNA sequences last so they are on top.
  // So the component is stored with the strand, but it is not rendered into the same group as
  // the various other SVG elements representing the strands.
  // Similarly we want the helices group to appear before the strands group so helices appear underneath.
  final svg.GElement helices_element = svg.GElement()..attributes = {'id': 'main-view-helices'};
  final svg.GElement strands_element = svg.GElement()..attributes = {'id': 'main-view-strands'};
  final svg.GElement dna_sequences_element = svg.GElement()..attributes = {'id': 'main-view-dna-sequences'};
  final svg.GElement mismatches_element = svg.GElement()..attributes = {'id': 'main-view-mismatches'};
  final svg.GElement helix_invisible_boxes_element = svg.GElement()
    ..attributes = {'id': 'main-view-helix-invisible-boxes'};

  List<HelixMainViewComponent> used_helix_elts = [];
  final Map<Strand, StrandComponent> strand_elts_map = {};
  final Map<GridPosition, HelixMainViewComponent> helix_elts_map = {};

  final svg.CircleElement _dummy_elt = svg.CircleElement()
    ..setAttribute('id', 'dummy-elt-main-view')
    ..setAttribute('fill', 'white')
    ..setAttribute('fill-opacity', '0.0') // transparent so it doesn't hide other elts
    ..setAttribute('cx', '0')
    ..setAttribute('cy', '0')
    ..setAttribute('r', '1')
    ..setInnerHtml('dummy elt for svg-pan-zoom not to have a divide-by-0 error due to 0 width/height');

  MainViewComponent(this.root_element) {
    // Adds a dummy SVG element (white circle that can't be seen)
    // to prevent the svg-pan-zoom library from dividing by 0 if there are no elements.
    // The dummy element placed here in index.html is sufficient to prevent the divide-by-0 error
    // in the local web server, but that element is removed dynamically once we render the main view.
    // For some reason the deployed server has the error unless we maintain that a dummy element is
    // always there.
    this.root_element.children.add(_dummy_elt);
  }

  /// Redraw elements
  render() {
    // clear data
    this.used_helix_elts = List<HelixMainViewComponent>(app.model.dna_design.used_helices.length);
    this.helix_elts_map.clear();
    this.strand_elts_map.clear();

    this.root_element.children.clear();
    this.helices_element.children.clear();
    this.strands_element.children.clear();
    this.helix_invisible_boxes_element.children.clear();

    // order of these groups determines which appears underneath
    this.root_element.children.add(this.helices_element);
    this.root_element.children.add(this.mismatches_element);
    this.root_element.children.add(this.strands_element);
    this.root_element.children.add(this.dna_sequences_element);
    this.root_element.children.add(this.helix_invisible_boxes_element);

    // draw helices
    for (var helix in app.model.dna_design.helices) {
      this.helix_elts_map[helix.grid_position] = HelixMainViewComponent(this.helices_element, helix);
    }

    for (var helix in app.model.dna_design.used_helices) {
      var helix_elt = helix_elts_map[helix.grid_position];
      this.helices_element.children.add(helix_elt.root_element);
      this.used_helix_elts[helix.idx] = helix_elt;
    }

    // draw strands
    this.strand_elts_map.clear();
    for (var strand in app.model.dna_design.strands) {
      var strand_elt = StrandComponent(strand);
      this.strands_element.children.add(strand_elt.root_element);
      this.strand_elts_map[strand] = strand_elt;
    }

    for (var helix_elt in helix_elts_map.values) {
      helix_elt.render();
    }

    for (var strand_elt in strand_elts_map.values) {
      strand_elt.render();
    }

    // render DNA sequences
    this.render_dna_sequences();

    // render mismatches
    this.render_mismatches();

    // render invisible helix boxes
    for (var helix_elt in this.helix_elts_map.values) {
      helix_elt.render_invisible_box();
    }
  }

  render_dna_sequences() {
    this.dna_sequences_element.children.clear();
    if (app.model.show_dna) {
      // these need to be rendered even if we are also rendering by HelixDNASequenceComponent, since the
      // insertions are handled by individual DNASequenceComponents contained within StrandComponents
      for (var strand_elt in this.strand_elts_map.values) {
        this.dna_sequences_element.children.add(strand_elt.dna_sequence_component.root_element);
        strand_elt.dna_sequence_component.render();
      }
//      for (var helix_elt in this.helix_elts_map.values) {
//        this.dna_sequences_element.children.add(helix_elt.dna_sequence_component.root_element);
//        helix_elt.dna_sequence_component.render();
//      }
    }
  }

  render_mismatches() {
    this.mismatches_element.children.clear();
    if (app.model.show_mismatches) {
      for (var strand_elt in this.strand_elts_map.values) {
        this.mismatches_element.children.add(strand_elt.mismatches_component.root_element);
        strand_elt.mismatches_component.render();
      }
    }
  }
}

@JS(constants.js_function_name_current_zoom)
external num current_zoom();

@JS(constants.js_function_name_current_pan)
external List<num> current_pan_js();

Point<num> current_pan() {
  var ret = current_pan_js();
  return Point<num>(ret[0], ret[1]);
}

class HelixMainViewComponent extends ReactiveComponent {
  final svg.GElement parent;
  final svg.GElement root_element = svg.GElement();
  final svg.GElement invisible_box_group = svg.GElement();
  final Helix helix;
  svg.RectElement invisible_box;

//  HelixDNASequenceComponent dna_sequence_component;

  HelixMainViewComponent(this.parent, this.helix) {
//    this.dna_sequence_component = HelixDNASequenceComponent(this.helix.idx);
    root_element.setAttribute("class", "helix-lines");
    this.listen(helix);
  }

  register_mouse_events() {
    this.invisible_box.onMouseLeave.listen((MouseEvent event) {
      app.send_action(RemoveMouseOverDataAction());
    });

    this.invisible_box.onMouseMove.listen((MouseEvent event) {
      Point<num> pan = current_pan();
      num zoom = current_zoom();

      var svg_coord = util.transform(event.offset, pan, zoom);
      num svg_x = svg_coord.x;
      num svg_y = svg_coord.y;

      int helix_idx = this.helix.idx;
      int offset = this.helix.svg_x_to_offset(svg_x);
      bool forward = this.helix.svg_y_is_forward(svg_y);

      if (DEBUG_PRINT_MOUSEOVER) {
        print('mouse event: '
            'x = ${event.offset.x},   '
            'y = ${event.offset.y},   '
            'pan = (${pan.x.toStringAsFixed(2)}, ${pan.y.toStringAsFixed(2)}),   '
            'zoom = ${zoom.toStringAsFixed(2)},   '
            'svg_x = ${svg_x.toStringAsFixed(2)},   '
            'svg_y = ${svg_y.toStringAsFixed(2)},   '
            'helix = ${helix_idx},   '
            'offset = ${offset},   '
            'forward = ${forward}');
      }

      app.send_action(UpdateMouseOverDataAction(helix_idx, offset, forward));
    });
  }

  render() {
    this.root_element.children.clear();
    var x = helix.svg_position.x;
    var y = helix.svg_position.y;
    this.root_element.setAttribute('transform', 'translate($x $y)');
    this.invisible_box_group.setAttribute('transform', 'translate($x $y)');
    app.view.design_view.main_view.helix_invisible_boxes_element.children.add(this.invisible_box_group);
    if (!helix.used) {
      //XXX: do this better
      parent.children.remove(this.root_element);
    } else {
      var side_helix_group = svg.GElement();
      this.root_element.children.add(side_helix_group);
      var lines_group = svg.GElement();
      this.root_element.children.add(lines_group);
      this.draw_side_helix(side_helix_group);
      this.draw_horz_lines(lines_group);
      this.draw_vert_lines(lines_group);
      this.render_invisible_box();

      //TODO: this is ugly, and I need to build in some better assumptions about how elements get created
      if (!parent.children.contains(this.root_element)) {
        parent.children.add(this.root_element);
      }
    }
  }

  /// This isn't shown, but it is used for mouseover events to display useful information in the footer.
  render_invisible_box() {
    var width = constants.BASE_WIDTH_SVG * this.helix.max_bases;
    var height = 2 * constants.BASE_HEIGHT_SVG;

    this.invisible_box_group.children.clear();

    this.invisible_box = svg.RectElement();
    invisible_box.attributes = {
      'class': 'helix-invisible-box',
      'x': '0',
      'y': '0',
      'width': '$width',
      'height': '$height',
    };
    this.invisible_box_group.children.add(this.invisible_box);
    this.register_mouse_events();
  }

  draw_horz_lines(svg.SvgElement lines_group, {bool inline_style = false}) {
    var x0 = 0;
    var x1 = constants.BASE_WIDTH_SVG * this.helix.max_bases;
    var y0 = 0;
    var y1 = constants.BASE_HEIGHT_SVG;
    var y2 = 2 * constants.BASE_HEIGHT_SVG;

    var path_horz = svg.PathElement();
    path_horz.attributes = {
      'class': 'helix-horz-line',
      'd': 'M $x0 $y0 H $x1 M $x0 $y1 H $x1 M $x0 $y2 H $x1',
    };
    lines_group.children.add(path_horz);
  }

  List<int> regularly_spaced_ticks(int distance, int end) {
    if (distance < 0) {
      throw ArgumentError('distance between major ticks must be positive');
    } else if (distance == 0) {
      return [];
    } else {
      return [for (int offset in iter.range(0, end + 1, distance)) offset];
    }
  }

  draw_vert_lines(svg.SvgElement lines_group, {bool inline_style = false}) {
    var max_bases = this.helix.max_bases;
    var major_tick_distance = this.helix.has_major_tick_distance()
        ? this.helix.major_tick_distance
        : app.model.dna_design.major_tick_distance;
    var path_cmds_vert_minor = [];
    var path_cmds_vert_major = [];

    Set<int> major_ticks = (this.helix.has_major_ticks()
            ? this.helix.major_ticks
            : regularly_spaced_ticks(major_tick_distance, this.helix.max_bases))
        .toSet();

    var x = 0;
    var y = 2 * constants.BASE_HEIGHT_SVG;
    for (int base = 0; base <= max_bases; base++) {
//      var major = major_tick_distance > 0 && base % major_tick_distance == 0;
      var path_cmds = major_ticks.contains(base) ? path_cmds_vert_major : path_cmds_vert_minor;
      path_cmds.add('M $x 0');
      path_cmds.add('v $y');
      x += constants.BASE_WIDTH_SVG;
    }

    var path_vert_minor = svg.PathElement();
    var path_vert_major = svg.PathElement();
    path_vert_minor.attributes = {
      'class': 'helix-vert-minor-line',
      'd': path_cmds_vert_minor.join(' '),
    };
    path_vert_major.attributes = {
      'class': 'helix-vert-major-line',
      'd': path_cmds_vert_major.join(' '),
    };
    lines_group.children.add(path_vert_minor);
    lines_group.children.add(path_vert_major);
  }

  draw_side_helix(svg.GElement side_helix_group) {
    var circle = svg.CircleElement();
    var text = svg.TextElement();
    var xoffset = '-${2 * constants.BASE_WIDTH_SVG + constants.DISTANCE_BETWEEN_HELICES_SVG / 2}';
    var yoffset = '${constants.BASE_WIDTH_SVG}';
    circle.attributes = {
      'class': '$MAIN_VIEW_PREFIX-helix-circle',
      'cx': xoffset,
      'cy': yoffset,
      'r': '${constants.DISTANCE_BETWEEN_HELICES_SVG / 2}',
    };
    text.attributes = {
      'class': '$MAIN_VIEW_PREFIX-helix-text',
      'x': xoffset,
      'y': yoffset,
    };
    text.innerHtml = helix.idx.toString();
    side_helix_group.children.add(circle);
    side_helix_group.children.add(text);
  }
}

/// Indicates if loopout between two given strands is a hairpin.
bool _is_hairpin(BoundSubstrand prev_ss, BoundSubstrand next_ss) {
  bool is_hairpin = prev_ss.helix == next_ss.helix &&
      prev_ss.forward != next_ss.forward &&
      (prev_ss.offset_3p - next_ss.offset_5p).abs() < 3;
  return is_hairpin;
}

class StrandComponent {
  final Strand strand;
  svg.GElement root_element = svg.GElement();
  DNASequenceComponent dna_sequence_component;
  MismatchesComponent mismatches_component;

  StrandComponent(Strand this.strand) {
    this.dna_sequence_component = DNASequenceComponent(this.strand);
    this.mismatches_component = MismatchesComponent(this.strand);
    this.root_element.attributes = {
      'class': 'strand',
    };
  }

  render() {
    this.root_element.children.clear();

    this._draw_strand_lines();
//    this.render_strand_lines_single_path();

    this._draw_5p_end();
    this._draw_3p_end();
    for (var substrand in this.strand.bound_substrands()) {
      this._draw_deletions(substrand);
      this._draw_insertions(substrand);
    }
    //XXX: note DNA sequence is not rendered here, or else later-rendered Strands would cover the DNA
    // Instead all DNA sequences are rendered into their own SVG group after all strands are rendered.
    // Similarly mismatches are rendered separately so that they appear behind all other elements,
    // and so that Strands need not be re-rendered when the "Show Mismatches" tickbox is checked/unchecked.
    // But the components are stored here (maybe should change that.)
  }

  // keep this around in case this is how we want to export to an SVG file
//  draw_dna_sequence_old(Substrand substrand) {
//    var seq_group = svg.GElement();
//    seq_group.attributes = {'class': 'dna-subsequence'};
//    element.children.add(seq_group);
//    String dna_sequence = substrand.dna_sequence();
//    for (int i = 0; i < substrand.dna_length && i < dna_sequence.length; i++) {
//      String base = dna_sequence[i];
//      var base_elt = svg.TextElement();
//      base_elt.innerHtml = base;
//      var offset_from_start = i;
//      var rotate_degrees = 0;
//      if (substrand.direction == Direction.left) {
//        offset_from_start = -i;
//      }
//      int offset = substrand.offset_5p + offset_from_start;
//      Point<num> pos = Helix.svg_base_pos(substrand.helix_idx, offset, substrand.direction);
//      var rotate_x = pos.x;
//      var rotate_y = pos.y;
//      if (substrand.direction == Direction.left) {
//        rotate_degrees = 180;
//      }
//      var dy = '0.75px';
//      if (browser.isFirefox) {
//        dy = '0px';
//      }
//      base_elt.attributes = {
//        'class': 'dna-base',
//        'x': '${pos.x}',
//        'y': '${pos.y}',
//        'transform': 'rotate(${rotate_degrees} ${rotate_x} ${rotate_y})',
//        'dy': dy,
//      };
//      seq_group.children.add(base_elt);
//    }
//  }

  //TODO: draw loopout lines

  _draw_strand_lines() {
    if (this.strand.substrands.length == 0) {
      return;
    }

    if (this.strand.substrands.first is Loopout) {
      throw StrandError(this.strand, 'loopouts at beginning of strand not supported');
    }
    if (this.strand.substrands.last is Loopout) {
      throw StrandError(this.strand, 'loopouts at end of strand not supported');
    }

    List<Element> paths = [];

    var substrand = this.strand.substrands.first;
    for (int i = 0; i < this.strand.substrands.length; i++) {
      substrand = this.strand.substrands[i];
      if (substrand.is_bound_substrand()) {
        paths.add(_create_bound_substrand_line(substrand));
        if (i < this.strand.substrands.length - 1 && this.strand.substrands[i + 1].is_bound_substrand()) {
          paths.add(_create_crossover_arc(strand, i));
        }
      } else {
        paths.add(_create_loopout_arc(strand, i));
      }
    }

    this.root_element.children.addAll(paths);
  }

  svg.LineElement _create_bound_substrand_line(BoundSubstrand substrand) {
    Helix helix = app.model.dna_design.helices[substrand.helix];
    Point<num> start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
    var end_svg = helix.svg_base_pos(substrand.offset_3p, substrand.forward);
    var substrand_line = svg.LineElement()
      ..attributes = {
        'id': substrand_line_id(substrand),
        'class': 'substrand-line',
        'stroke': strand.color.toRgbColor().toCssString(),
        'x1': '${start_svg.x}',
        'y1': '${start_svg.y}',
        'x2': '${end_svg.x}',
        'y2': '${end_svg.y}',
      };
    return substrand_line;
  }

  /// loopout arc at position i in Strand (i.e., connect bound substrands i-1 and i+1
  svg.PathElement _create_loopout_arc(Strand strand, int i) {
    assert(0 < i);
    assert(i < strand.substrands.length - 1);

    var prev_ss = strand.substrands[i - 1] as BoundSubstrand;
    var next_ss = strand.substrands[i + 1] as BoundSubstrand;
    var classname = 'substrand-line';

    Loopout loopout = strand.substrands[i];
    if (_is_hairpin(prev_ss, next_ss)) {
      // special case for hairpin so it's not a short straight line
      return _create_hairpin_arc(prev_ss, next_ss, loopout, classname);
    } else {
      return _create_arc(prev_ss, next_ss, classname, id: loopout_id(loopout, prev_ss, next_ss));
    }
  }

  svg.PathElement _create_hairpin_arc(
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

    var arc = svg.PathElement()
      ..attributes = {
        'id': loopout_id(loopout, prev_substrand, next_substrand),
        'class': classname,
        'stroke': strand.color.toRgbColor().toCssString(),
        'd': 'M ${start_svg.x} ${start_svg.y} C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${end_svg.x} ${end_svg.y}'
      };
    return arc;
  }

  /// crossover arc from bound substrand i to bound substrand i+1
  svg.PathElement _create_crossover_arc(Strand strand, int i) {
    assert(i < strand.substrands.length - 1);
    assert(strand.substrands[i].is_bound_substrand());
    assert(strand.substrands[i + 1].is_bound_substrand());

    var prev_substrand = strand.substrands[i] as BoundSubstrand;
    var next_substrand = strand.substrands[i + 1] as BoundSubstrand;
    var classname = 'crossover-curve';

    return _create_arc(prev_substrand, next_substrand, classname);
  }

  svg.PathElement _create_arc(BoundSubstrand prev_substrand, BoundSubstrand next_substrand, String classname,
      {String id = null}) {
    var prev_helix = app.model.dna_design.helices[prev_substrand.helix];
    var next_helix = app.model.dna_design.helices[next_substrand.helix];
    var start_svg = prev_helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
    var control = _control_point_for_crossover_bezier_curve(prev_substrand, next_substrand);
    var end_svg = next_helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);
    var strand = prev_substrand.strand;

    var arc = svg.PathElement()
      ..attributes = {
        'class': classname,
        'stroke': strand.color.toRgbColor().toCssString(),
        'd': 'M ${start_svg.x} ${start_svg.y} Q ${control.x} ${control.y} ${end_svg.x} ${end_svg.y}'
      };
    if (id != null) {
      arc.setAttribute('id', id);
    }
    return arc;
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

  _draw_5p_end() {
    var first_ss = strand.first_bound_substrand();
    var helix = app.model.dna_design.helices[first_ss.helix];
    var offset = first_ss.offset_5p;
    var right = first_ss.forward;
    var pos = helix.svg_base_pos(offset, right);
    var box = svg.RectElement();
    //XXX: width, height, rx, ry should be do-able in CSS, but Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here
    box.attributes = {
      'class': 'five-prime-end',
      'x': '${pos.x - 3}',
      'y': '${pos.y - 3}',
      'width': '6px',
      'height': '6px',
      'rx': '1.5px',
      'ry': '1.5px',
      'fill': strand.color.toRgbColor().toCssString(),
    };
    root_element.children.add(box);
  }

  _draw_3p_end() {
    var last_ss = strand.last_bound_substrand();
    var offset = last_ss.offset_3p;
    var direction = last_ss.forward;
    var helix = app.model.dna_design.helices[last_ss.helix];
    var pos = helix.svg_base_pos(offset, direction);
    var triangle = svg.PolygonElement();
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
    triangle.attributes = {
      'class': 'three-prime-end',
      'points': points,
      'fill': strand.color.toRgbColor().toCssString(),
    };
    root_element.children.add(triangle);
  }

  _draw_deletions(BoundSubstrand substrand) {
    for (var deletion in substrand.deletions) {
      var helix = app.model.dna_design.helices[substrand.helix];
      Point<num> pos = helix.svg_base_pos(deletion, substrand.forward);

      var width = 0.8 * constants.BASE_WIDTH_SVG;
      var half_width = 0.5 * width;
      var path_cmds = 'M ${pos.x - half_width} ${pos.y - half_width} '
          'l ${width} ${width} m ${-width} ${0} l ${width} ${-width}';
      var deletion_path = svg.PathElement();
      deletion_path.attributes = {
        'class': 'deletion-cross',
        'stroke': strand.color.toRgbColor().toCssString(),
        'fill': 'none',
        'd': path_cmds,
      };
      this.root_element.children.add(deletion_path);
    }
  }

  _draw_insertions(BoundSubstrand substrand) {
    for (var insertion in substrand.insertions) {
      int offset = insertion.item1;

      svg.PathElement insertion_path = _draw_insertion(substrand, offset);

      _draw_text_number_of_insertions(insertion, insertion_path, substrand, offset);
    }
  }

  svg.PathElement _draw_insertion(BoundSubstrand substrand, int offset) {
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

    var insertion_path = svg.PathElement();

    insertion_path.attributes = {
      'id': insertion_id(substrand, offset),
      'class': 'insertion-line',
      'stroke': this.strand.color.toRgbColor().toCssString(),
      'fill': 'none',
      'd': 'M $x0 $y0 '
          'C $x1 $y1, $x2 $y2, $x3 $y2 '
          'C $x4 $y2, $x5 $y1, $x0 $y0 ',
    };
    return insertion_path;
  }

  void _draw_text_number_of_insertions(
      Tuple2<int, int> insertion, svg.PathElement insertion_path, BoundSubstrand substrand, int offset) {
    // write number of insertions inside insertion loop
    int length = insertion.item2;
    var xmlns = "http://www.w3.org/2000/svg";
    svg.TextPathElement textpath_elt = document.createElementNS(xmlns, 'textPath');
    textpath_elt.setInnerHtml('${length}');

    this.root_element.children.add(insertion_path);

    var dy_text = '${0.2 * constants.BASE_WIDTH_SVG}';
    if (browser.isFirefox) {
      // le sigh
      dy_text = '${0.14 * constants.BASE_WIDTH_SVG}';
    }

    var text_elt = svg.TextElement();
    text_elt.children.add(textpath_elt);
    textpath_elt.attributes = {
      'class': 'insertion-length',
      'startOffset': '50%',
      'href': '#${insertion_id(substrand, offset)}',
    };
    text_elt.attributes = {
      'dy': dy_text,
    };

    this.root_element.children.add(text_elt);
  }
}

String substrand_line_id(BoundSubstrand substrand) =>
    'substrand-H${substrand.helix}-O${substrand.start}-${substrand.forward ? 'right' : 'left'}';

String insertion_id(BoundSubstrand substrand, int offset) =>
    'insertion-H${substrand.helix}-O${offset}-${substrand.forward ? 'right' : 'left'}';

String loopout_id(Loopout loopout, BoundSubstrand prev_ss, BoundSubstrand next_ss) =>
    'loopout-H${prev_ss.helix}-O${prev_ss.offset_3p}-H${next_ss.helix}-O${next_ss.offset_5p}';

class MismatchesComponent {
  svg.GElement root_element = svg.GElement();
  Strand strand;

  MismatchesComponent(this.strand) {
    this.root_element.attributes = {
      'class': 'mismatches-elts',
    };
  }

  render() {
    root_element.children.clear();
    if (app.model.show_mismatches) {
      for (var substrand in this.strand.bound_substrands()) {
        this._draw_mismatches(substrand);
      }
    }
  }

  _draw_mismatches(BoundSubstrand substrand) {
    List<Mismatch> mismatches = app.model.dna_design.mismatches_on_substrand(substrand);
    for (Mismatch mismatch in mismatches) {
      // For now, if there is a mismatch in an insertion we simply display it for the whole insertion,
      // not for a specific base.
      var helix = app.model.dna_design.used_helices[substrand.helix];
      var base_pos = helix.svg_base_pos(mismatch.offset, substrand.forward);
      var star = create_mismatch_svg_star(base_pos, substrand.forward);
      this.root_element.children.add(star);
    }
  }
}

class DNASequenceComponent {
  svg.GElement root_element = svg.GElement();
  Strand strand;
  static const classname_dna_sequence = 'dna-seq';

  DNASequenceComponent(this.strand) {
    this.root_element.attributes = {
      'class': 'dna-sequence-elts',
    };
  }

  //TODO: draw loopout DNA

  render() {
    root_element.children.clear();
    if (app.model.show_dna && this.strand.dna_sequence != null) {
//      for (var substrand in this.strand.substrands) {
      for (int i = 0; i < this.strand.substrands.length; i++) {
        var substrand = this.strand.substrands[i];
        if (substrand.is_bound_substrand()) {
          var bound_ss = substrand as BoundSubstrand;
          this._draw_dna_sequence_on_bound_substrand(substrand);
          for (var insertion in bound_ss.insertions) {
            int offset = insertion.item1;
            int length = insertion.item2;
            this._draw_insertion_dna_sequence(bound_ss, offset, length);
          }
        } else {
          assert(0 < i);
          assert(i < this.strand.substrands.length - 1);
          BoundSubstrand prev_ss = this.strand.substrands[i - 1];
          BoundSubstrand next_ss = this.strand.substrands[i + 1];
          this._draw_dna_sequence_on_loopout(substrand, prev_ss, next_ss);
        }
      }
    }
  }

  //TODO: try converting SVG text to paths for efficiency:
  // https://pub.dev/packages/text_to_path_maker
  // https://github.com/shrhdk/text-to-svg

  // This is not declarative rendering; it makes some assumptions about what render_dna_sequences() did
  // In general "draw" means it just draws (possibly over the top of something incorrectly),
  // whereas "render" means "draw as though from scratch"
  _draw_dna_sequence_on_bound_substrand(BoundSubstrand substrand) {
    var seq_elt = svg.TextElement();
    var seq_to_draw = substrand.dna_sequence_deletions_insertions_to_spaces();
    seq_elt.setInnerHtml(seq_to_draw);

    var rotate_degrees = 0;
    int offset = substrand.offset_5p;
    var helix = app.model.dna_design.helices[substrand.helix];
    Point<num> pos = helix.svg_base_pos(offset, substrand.forward);
    var rotate_x = pos.x;
    var rotate_y = pos.y;

    // this is needed to make complementary DNA bases line up more nicely (still not perfect)
    var x_adjust = -constants.BASE_WIDTH_SVG * 0.32;
    if (!substrand.forward) {
      rotate_degrees = 180;
    }
    var dy = -constants.BASE_HEIGHT_SVG * 0.25;

    var text_length = constants.BASE_WIDTH_SVG * (substrand.visual_length - 0.342);

    seq_elt.attributes = {
      'class': classname_dna_sequence,
      'x': '${pos.x + x_adjust}',
      'y': '${pos.y}',
      'textLength': '$text_length',
      'transform': 'rotate(${rotate_degrees} ${rotate_x} ${rotate_y})',
      'dy': '$dy',
    };

    this.root_element.children.add(seq_elt);
  }

  _draw_insertion_dna_sequence(BoundSubstrand substrand, int offset, int length) {
    svg.TextPathElement textpath_elt;
    // I can't find documentation for a constructor that can be called for TextPathElement:
    // https://api.dartlang.org/stable/2.4.0/dart-svg/TextPathElement-class.html
    // so instead we look it up by the tag name
//    seq_elt = svg.TextPathElement();
    // Got this from https://stackoverflow.com/questions/3492322/javascript-createelement-and-svg
    var xmlns = "http://www.w3.org/2000/svg";
    textpath_elt = document.createElementNS(xmlns, 'textPath');

//    seq_elt = html.document.createElement('textPath');
    var subseq = substrand.dna_sequence_in(offset, offset);
    textpath_elt.setInnerHtml(subseq);

    //XXX: path_length appears to return different results depending on the computer (probably resolution??)
    // don't rely on it. This caused Firefox for example to render different on the same version.
//    num path_length = insertion_path_elt.getTotalLength();

    var start_offset = '50%';
    var dy = '${0.1 * constants.BASE_WIDTH_SVG}';

    Tuple2<num, num> ls_fs = _calculate_letter_spacing_and_font_size_insertion(length);
    num letter_spacing = ls_fs.item1;
    num font_size = ls_fs.item2;

    String style_string;
    if (letter_spacing != null) {
      style_string = 'letter-spacing: ${letter_spacing}em; font-size: ${font_size}px';
    } else {
      style_string = 'font-size: ${font_size}px';
    }

    var text_elt = svg.TextElement();
    text_elt.children.add(textpath_elt);
    textpath_elt.attributes = {
      'class': classname_dna_sequence + '-insertion',
      'href': '#${insertion_id(substrand, offset)}',
      'startOffset': start_offset,
      'style': style_string,
    };
    text_elt.attributes = {
      'dy': dy,
    };

    this.root_element.children.add(text_elt);
  }

  _draw_dna_sequence_on_loopout(Loopout loopout, BoundSubstrand prev_ss, BoundSubstrand next_ss) {
    svg.TextPathElement textpath_elt;
    var xmlns = "http://www.w3.org/2000/svg";
    textpath_elt = document.createElementNS(xmlns, 'textPath');

    //TODO: write this

    var subseq = loopout.dna_sequence();
    var length = subseq.length;
    textpath_elt.setInnerHtml(subseq);

    var start_offset = '50%';
    var dy = '${0.1 * constants.BASE_WIDTH_SVG}';

    Tuple2<num, num> ls_fs;
    if (_is_hairpin(prev_ss, next_ss)) {
      ls_fs = _calculate_letter_spacing_and_font_size_hairpin(length);
    } else {
      ls_fs = _calculate_letter_spacing_and_font_size_loopout(length);
    }
    num letter_spacing = ls_fs.item1;
    num font_size = ls_fs.item2;

    String style_string;
    if (letter_spacing != null) {
      style_string = 'letter-spacing: ${letter_spacing}em; font-size: ${font_size}px';
    } else {
      style_string = 'font-size: ${font_size}px';
    }

    var text_elt = svg.TextElement();
    text_elt.children.add(textpath_elt);
    textpath_elt.attributes = {
      'class': classname_dna_sequence + '-loopout',
      'href': '#${loopout_id(loopout, prev_ss, next_ss)}',
      'startOffset': start_offset,
      'style': style_string,
    };
    text_elt.attributes = {
      'dy': dy,
    };

    this.root_element.children.add(text_elt);
  }
}

svg.PolygonElement create_mismatch_svg_star(Point<num> base_svg_pos, bool right) {
  num x0 = base_svg_pos.x;
  num y0 = base_svg_pos.y - 1.0 * constants.BASE_HEIGHT_SVG;

  // assume bottom points of star are at origin
  List<num> xs = [];
  List<num> ys = [];

  num inner_radius = 0.2 * constants.BASE_WIDTH_SVG;
  num outer_radius = 0.45 * constants.BASE_WIDTH_SVG;

  num num_points = 12;
  num inner_angle = 0;
  num outer_angle = inner_angle + pi / num_points;
  for (int i = 0; i < num_points; i++) {
    num x_inner = inner_radius * cos(inner_angle);
    num y_inner = inner_radius * sin(inner_angle);
    num x_outer = outer_radius * cos(outer_angle);
    num y_outer = outer_radius * sin(outer_angle);
    xs.add(x_inner);
    xs.add(x_outer);
    ys.add(y_inner);
    ys.add(y_outer);
    inner_angle += 2 * pi / num_points;
    outer_angle += 2 * pi / num_points;
  }

  num rotate_degrees = 0;
  if (!right) {
    rotate_degrees = 180;
  }

  // translate from origin
  for (int i = 0; i < xs.length; i++) {
    xs[i] += x0;
    ys[i] += y0;
  }

  List<String> points = [];
  for (int i = 0; i < xs.length; i++) {
    points.add('${xs[i].toStringAsFixed(2)},${ys[i].toStringAsFixed(2)}');
  }

  var ret = svg.PolygonElement()
    ..attributes = {
      'class': 'mismatch-star',
      'points': points.join(' '),
      'transform': 'rotate(${rotate_degrees} ${base_svg_pos.x} ${base_svg_pos.y})',
    };
  return ret;
}

//TODO: calibrate these based on real usages

Tuple2<num, num> _calculate_letter_spacing_and_font_size_loopout(int len) {
  num letter_spacing = 0;
  num font_size = 12;
  return Tuple2<num, num>(letter_spacing, font_size);
}

Tuple2<num, num> _calculate_letter_spacing_and_font_size_hairpin(int len) {
  num letter_spacing;
  num font_size = max(6, 12 - max(0, len - 6));
  if (browser.isChrome) {
    if (len == 1) {
      letter_spacing = 0;
    } else if (len == 2) {
      letter_spacing = -0.1;
    } else if (len == 3) {
      letter_spacing = -0.1;
    } else if (len == 4) {
      letter_spacing = -0.1;
    } else if (len == 5) {
      letter_spacing = -0.15;
    } else if (len == 6) {
      letter_spacing = -0.18;
    } else {
      letter_spacing = null;
    }
  }
  if (browser.isFirefox) {
    // Firefox ignores the "letter-spacing" property so we only have font-size to play with
    font_size = max(6, 12 - (len - 1));
    if (len > 3 && font_size > 6) {
      font_size -= 1;
    }
    letter_spacing = null;
  }
  return Tuple2<num, num>(letter_spacing, font_size);
}

Tuple2<num, num> _calculate_letter_spacing_and_font_size_insertion(int num_insertions) {
  // UGGG
  num letter_spacing;
  num font_size = max(6, 12 - (num_insertions - 1));
  if (browser.isChrome) {
    if (num_insertions == 1) {
      letter_spacing = 0;
    } else if (num_insertions == 2) {
      letter_spacing = -0.1;
    } else if (num_insertions == 3) {
      letter_spacing = -0.1;
    } else if (num_insertions == 4) {
      letter_spacing = -0.1;
    } else if (num_insertions == 5) {
      letter_spacing = -0.15;
    } else if (num_insertions == 6) {
      letter_spacing = -0.18;
    } else {
      letter_spacing = null;
    }
  }
  if (browser.isFirefox) {
    // Firefox ignores the "letter-spacing" property so we only have font-size to play with
    font_size = max(6, 12 - (num_insertions - 1));
    if (num_insertions > 3 && font_size > 6) {
      font_size -= 1;
    }
    letter_spacing = null;
  }
  return Tuple2<num, num>(letter_spacing, font_size);
}

// HelixDNASequenceComponent was an attempted performance optimization to render a single line of text
// for all DNA sequences for all Substrands on a Helix, but it did not speed up rendering at all.
///// Draws single svg text element for all DNA sequences on a given Helix. Renders much faster than
///// having an individual text element for each substrand. There are still individual elements for each
///// insertion.
//class HelixDNASequenceComponent {
//  svg.GElement root_element = svg.GElement();
//  int helix_idx;
//  static const classname_dna_sequence = 'dna-seq';
//
//  HelixDNASequenceComponent(this.helix_idx) {
//    this.root_element.attributes = {
//      'class': 'dna-sequence-elts',
//    };
//  }
//
//  render() {
//    root_element.children.clear();
//    if (app.model.show_dna) {
//      // gather substrands from each helix to render (separate right from left substrands)
//      Helix helix = app.model.dna_design.helices[this.helix_idx];
//      List<Substrand> substrands =
//          List<Substrand>.from(app.model.dna_design.helix_idx_substrands_map[this.helix_idx]);
//      List<Substrand> substrands_right = [for (var ss in substrands) if (ss.right) ss];
//      List<Substrand> substrands_left = [for (var ss in substrands) if (!ss.right) ss];
//      // sort right-pointing strands left-to-right, and left-pointing strands right-to-left
//      substrands_right.sort((Substrand ss1, Substrand ss2) => ss1.start.compareTo(ss2.start));
//      substrands_left.sort((Substrand ss1, Substrand ss2) => -ss1.start.compareTo(ss2.start));
//      if (substrands_right.isNotEmpty) {
//        this._render_substrands_on_helix(helix, substrands_right);
//      }
//      if (substrands_left.isNotEmpty) {
//        this._render_substrands_on_helix(helix, substrands_left);
//      }
//    }
//  }
//
//  _render_substrands_on_helix(Helix helix, List<Substrand> substrands) {
//    var ss_first = substrands.first;
//    var ss_last = substrands.last;
//
//    Point<num> pos = helix.svg_base_pos(ss_first.offset_5p, ss_first.right);
//    var rotate_x = pos.x;
//    var rotate_y = pos.y;
//    // this is needed to make complementary DNA bases line up more nicely (still not perfect)
//    var x_adjust = -constants.BASE_WIDTH_SVG * 0.1;
//    var rotate_degrees = 0;
//    if (!ss_first.right) {
//      rotate_degrees = 180;
//    }
//    var dy = '0.75px';
//    if (browser.isFirefox) {
//      dy = '0px';
//    }
//
//    int visual_length = (ss_last.offset_3p - ss_first.offset_5p).abs();
//    var text_length = constants.BASE_WIDTH_SVG * visual_length + (WIDTH_SVG_TEXT_SYMBOL / 2);
//
//    var seq_elt = svg.TextElement();
//    var seq_to_draw = _get_seq_for_whole_helix(ss_first, substrands);
//    seq_elt.setInnerHtml(seq_to_draw);
//
//    seq_elt.attributes = {
//      'class': classname_dna_sequence,
//      'x': '${pos.x + x_adjust}',
//      'y': '${pos.y}',
//      'textLength': '$text_length',
//      'transform': 'rotate(${rotate_degrees} ${rotate_x} ${rotate_y})',
//      'dy': dy,
//    };
//
//    this.root_element.children.add(seq_elt);
//  }
//
//  String _get_seq_for_whole_helix(Substrand ss_first, List<Substrand> substrands) {
//    List<String> seqs = [];
//    int end_idx_prev = ss_first.offset_3p;
//    for (int i = 0; i < substrands.length; i++) {
//      var ss_prev = substrands[i];
//      seqs.add(ss_prev.dna_sequence_deletions_insertions_to_spaces());
//      if (i < substrands.length - 1) {
//        var ss_next = substrands[i + 1];
//        int start_idx_next = ss_next.offset_5p;
//        var spaces = ' ' * (start_idx_next - end_idx_prev - 1);
//        seqs.add(spaces);
//      }
//    }
//    String long_seq = seqs.join('');
//
//    return long_seq;
//  }
//
//}
