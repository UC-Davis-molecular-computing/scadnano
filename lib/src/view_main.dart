import 'dart:html' as html;
import 'dart:math';
import 'dart:svg' as svg; // hide Point;

import 'package:platform_detect/platform_detect.dart';

import 'model.dart';
import 'app.dart';

const String MAIN_VIEW_PREFIX = 'main-view';

final num WIDTH_SVG_TEXT_SYMBOL = width_svg_text('A');

num width_svg_text(String string) {
  var text_elt = svg.TextElement();
  text_elt.innerHtml = string;
  text_elt.attributes = {'class': 'dna-base'};
  var svg_elt = svg.SvgSvgElement();
  svg_elt.children.add(text_elt);

  html.document.body.children.add(svg_elt);
  var bbox = text_elt.getBBox();
  html.document.body.children.remove(svg_elt);

  return bbox.width;
}

class MainViewComponent {
  final svg.GElement element = svg.GElement();
  final Map<Strand, StrandComponent> strand_elts_map = {};
  final Map<Point<int>, HelixMainViewComponent> helix_elts_map = {};
  final List<HelixMainViewComponent> used_helix_elts =
      List<HelixMainViewComponent>(app.model.dna_design.used_helices.length);
  final svg.CircleElement _dummy_elt = svg.CircleElement()
    ..setAttribute('id', 'dummy-elt-main-view')
    ..setAttribute('fill', 'white')
    ..setAttribute('fill-opacity', '0.0') // transparent so it doesn't hide other elts
    ..setAttribute('cx', '0')
    ..setAttribute('cy', '0')
    ..setAttribute('r', '300')
    ..setInnerHtml('dummy elt for svg-pan-zoom not to have a divide-by-0 error due to 0 width/height');

  MainViewComponent() {
    // draw helices
    for (var helix in app.model.dna_design.helices) {
      helix_elts_map[helix.grid_position] = HelixMainViewComponent(this.element, helix);
    }
    for (var helix in app.model.dna_design.used_helices) {
      var helix_elt = helix_elts_map[helix.grid_position];
      element.children.add(helix_elt.element);
      used_helix_elts[helix.idx] = helix_elt;
    }
    // draw strands
    for (var strand in app.model.dna_design.strands) {
      var strand_elt = StrandComponent(strand);
      element.children.add(strand_elt.element);
      strand_elts_map[strand] = strand_elt;
    }

    // Adds a dummy SVG element (white circle that can't be seen)
    // to prevent the svg-pan-zoom library from dividing by 0 if there are no elements.
    // The dummy element placed here in index.html is sufficient to prevent the divide-by-0 error
    // in the local web server, but that element is removed dynamically once we render the main view.
    // For some reason the deployed server has the error unless we maintain that a dummy element is
    // always there.
    this.element.children.add(_dummy_elt);
  }

  /// Redraw elements
  render() {
    var pane = html.querySelector('#main-view-svg-viewport');
    pane.children.clear();
    pane.children.add(element);
    for (var helix_elt in helix_elts_map.values) {
      helix_elt.render();
    }
    for (var strand_elt in strand_elts_map.values) {
      strand_elt.render();
    }
  }
}

class HelixMainViewComponent {
  final svg.GElement parent;
  final svg.GElement element = svg.GElement();
  final Helix helix;

  HelixMainViewComponent(this.parent, this.helix) {
    element.setAttribute("class", "helix-lines");
  }

  //TODO: test whether getting rid of some of these transforms and putting
  // "absolute coordinates" (other than the top-level transform from panzoom)
  // speeds up the rendering while panning and zooming
  // Also look into the idea of defining a "symbol" in SVG and reusing it.
  // UPDATE: looked into it, looks like it is not faster:
  //   https://stackoverflow.com/questions/8604999/does-reusing-symbols-improve-svg-performance

  render() {
    element.children.clear();
    var x = helix.position.x;
    var y = helix.position.y;
    element.setAttribute('transform', 'translate($x $y)');
    if (!helix.used) {
      parent.children.remove(element);
    } else {
      var lines_group = svg.GElement();
      element.children.add(lines_group);
      draw_horz_lines(lines_group);
      draw_vert_lines(lines_group);
      var side_helix_group = svg.GElement();
      element.children.add(side_helix_group);
      draw_side_helix(side_helix_group);

      //TODO: this is ugly, and I need to build in some better assumptions about when/where
      // elements get created
      if (!parent.children.contains(element)) {
        parent.children.add(element);
      }
    }
  }

  draw_horz_lines(svg.SvgElement lines_group, {bool inline_style = false}) {
    var max_bases = app.model.dna_design.max_bases();
    var x0 = 0;
    var x1 = BASE_WIDTH_SVG * max_bases;
    var y0 = 0;
    var y1 = BASE_HEIGHT_SVG;
    var y2 = 2 * BASE_HEIGHT_SVG;

    var path_horz = svg.PathElement();
    path_horz.attributes = {
      'class': 'helix-horz-line',
      'd': 'M $x0 $y0 H $x1 M $x0 $y1 H $x1 M $x0 $y2 H $x1',
    };
    lines_group.children.add(path_horz);
  }

  draw_vert_lines(svg.SvgElement lines_group, {bool inline_style = false}) {
    var max_bases = app.model.dna_design.max_bases();
    var major_tick_distance = app.model.dna_design.major_tick_distance;
    var path_cmds_vert_minor = [];
    var path_cmds_vert_major = [];

    var x = 0;
    var y = 2 * BASE_HEIGHT_SVG;
    for (int base = 0; base <= max_bases; base++) {
      var major = major_tick_distance > 0 && base % major_tick_distance == 0;
      var path_cmds = major ? path_cmds_vert_major : path_cmds_vert_minor;
      path_cmds.add('M $x 0');
      path_cmds.add('v $y');
      x += BASE_WIDTH_SVG;
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
    var xoffset = '-${2 * BASE_WIDTH_SVG + DISTANCE_BETWEEN_HELICES_SVG / 2}';
    var yoffset = '${BASE_WIDTH_SVG}';
    circle.attributes = {
      'class': '$MAIN_VIEW_PREFIX-helix-circle',
      'cx': xoffset,
      'cy': yoffset,
      'r': '${DISTANCE_BETWEEN_HELICES_SVG / 2}',
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

//  create_cached_lines() {
//    //TODO: pull code that creates cached image out of draw_cached_lines; use same image for all helices
//  }
//
//  /// Makes a PNG drawing of a main view of a helix to be used in an SVG <image> element,
//  /// which renders faster than the SVG lines when the number of vertical lines is in the hundreds.
//  draw_cached_lines(svg.GElement linesGroup, {double resolution = 100}) {
////    var image = ImageElement();
////    image.setAttribute('href', 'helix_main_view.png');
//////    image.setAttribute('href', 'helix_main_view_hi_res.png');
////    image.setAttribute('width', '1000');
////    image.setAttribute('height', '20');
////    linesGroup.children.add(image);
//
//    //TODO: canvas width cannot be too large: https://github.com/jhildenbiddle/canvas-size#test-results
//    // make the largest png image of
//    svg.SvgSvgElement svg_elt = svg.SvgSvgElement();
////    svgElt.setAttribute('width', '100%');
//    svg.GElement lines_group_internal = svg.GElement();
//    lines_group_internal.setAttribute(
//        'transform', 'translate(${0.1 * resolution} ${1.05 * resolution}) scale(${resolution})');
//    svg_elt.children.add(lines_group_internal);
//
//    draw_horz_lines(lines_group_internal, inline_style: true);
//    draw_vert_lines(lines_group_internal, inline_style: true);
//
//    html.CanvasElement canvas = html.CanvasElement()..id = 'canvas-${helix.idx}';
//    html.SpanElement pngContainer = html.SpanElement()..id = 'png-container-${helix.idx}';
//
//    var max_bases = app.model.dna_design.max_bases();
//    canvas.setAttribute('width', '${1.03 * resolution * max_bases}px');
//    canvas.setAttribute('height', '${2.1 * resolution}px');
//    pngContainer.setAttribute('width', '${1.03 * resolution * max_bases}px');
//    pngContainer.setAttribute('height', '${2.1 * resolution}px');
//
////    canvas.setAttribute('width', '103000');
//
//    // taken from http://bl.ocks.org/biovisualize/8187844
//    var xmlSerializer = html.XmlSerializer();
//    var svgString = xmlSerializer.serializeToString(svg_elt);
//
//    var ctx = canvas.context2D;
//    var svgBlob = html.Blob([svgString], "image/svg+xml;charset=utf-8");
//    var url = html.Url.createObjectUrl(svgBlob);
//
//    var img = html.ImageElement();
//    img.src = url;
//    img.onLoad.listen((html.Event e) {
//      ctx.drawImage(img, 0, 0);
//      var png = canvas.toDataUrl("image/png", 1.0);
//      html.ImageElement imgElt = html.ImageElement()..src = png;
//      pngContainer.children.add(imgElt);
//
//      var svgImg = svg.ImageElement();
//      svgImg.setAttribute('href', png);
//      svgImg.setAttribute('width', '${BASE_WIDTH_SVG * max_bases}');
//      svgImg.setAttribute('height', '${2 * BASE_HEIGHT_SVG}');
//      linesGroup.children.add(svgImg);
//
//      html.Url.revokeObjectUrl(png);
//    });
//  }
}

class StrandComponent {
  final Strand strand;
  svg.GElement element = svg.GElement();
  DNASequenceComponent dna_sequence_component;

  StrandComponent(Strand this.strand) {
    this.dna_sequence_component = DNASequenceComponent(this.strand);
    this.element.attributes = {
      'class': 'strand',
    };
  }

  render() {
    //TODO: figure out how to layer SVG elements so these are drawn on top of Helix elements and in proper order relative to each other (e.g., DNA bases on top)
    this.element.children.clear();
    render_strand_lines();
    render_5p_end();
    render_3p_end();
    for (var substrand in this.strand.substrands) {
      render_deletions(substrand);
      render_insertions(substrand);
    }

    this.element.children.add(this.dna_sequence_component.element);
    this.dna_sequence_component.render();
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

  render_strand_lines() {
    if (this.strand.substrands.length == 0) {
      return;
    }
    var substrand = this.strand.substrands.first;
    var start_svg = Helix.svg_base_pos(substrand.helix_idx, substrand.offset_5p, substrand.direction);
    var path_cmds = ['M ${start_svg.x} ${start_svg.y}'];
    for (int i = 0; i < this.strand.substrands.length; i++) {
      // substrand line
      var end_svg = Helix.svg_base_pos(substrand.helix_idx, substrand.offset_3p, substrand.direction);
      path_cmds.add('L ${end_svg.x} ${end_svg.y}');

      // crossover line/arc
      if (i < this.strand.substrands.length - 1) {
        var old_substrand = substrand;
        substrand = this.strand.substrands[i + 1];
        start_svg = Helix.svg_base_pos(substrand.helix_idx, substrand.offset_5p, substrand.direction);
        var control = control_point_for_crossover_bezier_curve(old_substrand, substrand);
        path_cmds.add('Q ${control.x} ${control.y} ${start_svg.x} ${start_svg.y}');
      }
    }

    var path = svg.PathElement();
    path.attributes = {
      'class': 'substrand-line',
      'stroke': strand.color.toRgbColor().toCssString(),
      'fill': 'none',
      'd': path_cmds.join(' '),
    };
    this.element.children.add(path);
  }

  Point<num> control_point_for_crossover_bezier_curve(Substrand from_ss, Substrand to_ss) {
    var helix_distance = (from_ss.helix_idx - to_ss.helix_idx).abs();
    var start_pos = Helix.svg_base_pos(from_ss.helix_idx, from_ss.offset_3p, from_ss.direction);
    var end_pos = Helix.svg_base_pos(to_ss.helix_idx, to_ss.offset_5p, to_ss.direction);
    bool from_strand_below = from_ss.helix_idx - to_ss.helix_idx > 0;
    num midX = (start_pos.x + end_pos.x) / 2;
    num midY = (start_pos.y + end_pos.y) / 2;
    Point<num> mid = Point<num>(midX, midY);
    Point<num> control;
    Point<num> vector = end_pos - start_pos;
    Point<num> normal = Point<num>(vector.y, -vector.x);
    if (from_ss.direction == Direction.left && from_strand_below ||
        from_ss.direction == Direction.right && !from_strand_below) {
      normal = Point<num>(-vector.y, vector.x);
    }
    Point<num> unit_normal = normal * (1 / normal.magnitude);
    // This scale seems to look good even with many crossovers at same column,
    // e.g., long_range_crossovers.py in the examples directory.
    double scale = helix_distance * 0.5;
    Point<num> scale_normal = unit_normal * scale;
    control = mid + scale_normal * (BASE_WIDTH_SVG / 2);
    return control;
  }

  render_5p_end() {
    var helix_idx = strand.substrands.first.helix_idx;
    var offset = strand.substrands.first.offset_5p;
    var direction = strand.substrands.first.direction;
    var pos = Helix.svg_base_pos(helix_idx, offset, direction);
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
    element.children.add(box);
  }

  render_3p_end() {
    var helix_idx = strand.substrands.last.helix_idx;
    var offset = strand.substrands.last.offset_3p;
    var direction = strand.substrands.last.direction;
    var pos = Helix.svg_base_pos(helix_idx, offset, direction);
    var triangle = svg.PolygonElement();
    var points;
    num scale = 3.5;
    if (strand.substrands.last.direction == Direction.left) {
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
    element.children.add(triangle);
  }

  render_deletions(Substrand substrand) {
    for (var deletion in substrand.deletions) {
      Point<num> pos = Helix.svg_base_pos(substrand.helix_idx, deletion, substrand.direction);

      //TODO: make this a single SVG path for efficiency
      num inner_len = 4.0;
      num outer_len = 4.2;
      var top_cross_outer = svg.LineElement();
      top_cross_outer.attributes = {
        'class': 'deletion-cross-outer',
        'x1': '${pos.x - outer_len}',
        'y1': '${pos.y + outer_len}',
        'x2': '${pos.x + outer_len}',
        'y2': '${pos.y - outer_len}',
      };
      var bot_cross_outer = svg.LineElement();
      bot_cross_outer.attributes = {
        'class': 'deletion-cross-outer',
        'x1': '${pos.x - outer_len}',
        'y1': '${pos.y - outer_len}',
        'x2': '${pos.x + outer_len}',
        'y2': '${pos.y + outer_len}',
      };
      var top_cross_inner = svg.LineElement();
      top_cross_inner.attributes = {
        'class': 'deletion-cross-inner',
        'x1': '${pos.x - inner_len}',
        'y1': '${pos.y + inner_len}',
        'x2': '${pos.x + inner_len}',
        'y2': '${pos.y - inner_len}',
      };
      var bot_cross_inner = svg.LineElement();
      bot_cross_inner.attributes = {
        'class': 'deletion-cross-inner',
        'x1': '${pos.x - inner_len}',
        'y1': '${pos.y - inner_len}',
        'x2': '${pos.x + inner_len}',
        'y2': '${pos.y + inner_len}',
      };

      var deletion_group = svg.GElement();
      deletion_group.children.add(top_cross_outer);
      deletion_group.children.add(bot_cross_outer);
      deletion_group.children.add(top_cross_inner);
      deletion_group.children.add(bot_cross_inner);
      this.element.children.add(deletion_group);
    }
  }

  render_insertions(Substrand substrand) {
    for (var insertion in substrand.insertions) {
      int offset = insertion.item1;

      bool going_right = substrand.direction == Direction.right;
      Point<num> pos = Helix.svg_base_pos(substrand.helix_idx, offset, substrand.direction);
      num x0 = pos.x;
      num y0 = pos.y;
      num dx = BASE_WIDTH_SVG;
      num dy = 1.4 * BASE_HEIGHT_SVG;
      if (going_right) {
        dy = -dy;
        dx = -dx;
      }
      var x1 = (x0 + dx).toStringAsFixed(2);
      var x2 = (x0 - dx).toStringAsFixed(2);
      var y1 = (y0 + dy).toStringAsFixed(2);
      var y2 = (y0 + dy).toStringAsFixed(2);
      var path_insertion = svg.PathElement();
      path_insertion.attributes = {
        'id': insertion_id(substrand, offset, substrand.direction),
        'class': 'strand',
        'stroke': this.strand.color.toRgbColor().toCssString(),
        'fill': 'none',
        'd': 'M $x0 $y0 C $x1 $y1, $x2 $y2, $x0 $y0',
      };

      this.element.children.add(path_insertion);
    }
  }

  static String insertion_id(Substrand substrand, int offset, Direction direction) =>
      'insertion-H${substrand.helix_idx}-O${offset}-${direction_to_json(direction)}';
}

class DNASequenceComponent {
  svg.GElement element = svg.GElement();
  Strand strand;
  static const classname_dna_sequence = 'dna-seq';

  DNASequenceComponent(this.strand) {
    this.element.attributes = {
      'class': 'dna-sequence-elts',
    };
  }

  render() {
    element.children.clear();
    if (app.model.show_dna && this.strand.dna_sequence != null) {
      for (var substrand in this.strand.substrands) {
        this._draw_dna_sequence(substrand);
        for (var insertion in substrand.insertions) {
          int offset = insertion.item1;
          int length = insertion.item2;
          this._draw_insertion_dna_sequence(substrand, offset, length);
        }
      }
    }
  }

  // This is not declarative rendering; it makes some assumptions about what render_dna_sequences() did
  _draw_dna_sequence(Substrand substrand) {
    var seq_elt = svg.TextElement();
    seq_elt.innerHtml = substrand.dna_sequence_deletions_insertions_to_spaces();

    var rotate_degrees = 0;
    int offset = substrand.offset_5p;
    Point<num> pos = Helix.svg_base_pos(substrand.helix_idx, offset, substrand.direction);
    var rotate_x = pos.x;
    var rotate_y = pos.y;
    // this is needed to make complementary DNA bases line up more nicely (still not perfect)
    var x_adjust = -BASE_WIDTH_SVG * 0.1;
    if (substrand.direction == Direction.left) {
      rotate_degrees = 180;
    }
    var dy = '0.75px';
    if (browser.isFirefox) {
      dy = '0px';
    }

    var text_length = BASE_WIDTH_SVG * (substrand.visual_length - 1) + (WIDTH_SVG_TEXT_SYMBOL / 2);
    seq_elt.attributes = {
      'class': classname_dna_sequence,
      'x': '${pos.x + x_adjust}',
      'y': '${pos.y}',
      'textLength': '$text_length',
      'transform': 'rotate(${rotate_degrees} ${rotate_x} ${rotate_y})',
      'dy': dy,
    };

    this.element.children.add(seq_elt);
  }

  _draw_insertion_dna_sequence(Substrand substrand, int offset, int length) {
    bool going_right = substrand.direction == Direction.right;
    svg.TextPathElement textpath_elt;
    // I can't find documentation for a constructor that can be called for TextPathElement:
    // https://api.dartlang.org/stable/2.4.0/dart-svg/TextPathElement-class.html
    // so instead we look it up by the tag name
//    seq_elt = svg.TextPathElement();
    // Got this from https://stackoverflow.com/questions/3492322/javascript-createelement-and-svg
    var xmlns = "http://www.w3.org/2000/svg";
    textpath_elt = html.document.createElementNS(xmlns, 'textPath');

//    seq_elt = html.document.createElement('textPath');
    var subseq = substrand.dna_sequence_in(offset, offset);
    textpath_elt.setInnerHtml(subseq);

    //TODO: make these constants calculated once when program starts
    var dy = '-${0.5 * BASE_WIDTH_SVG}px';
    // hard to read, but this uses space nicely no matter how many insertions there are,
    // when there are more bases, it starts earlier and ends later on the arc
    var start_offset = '${(1.0 - min(1.0, (length-1)*0.25)) * BASE_WIDTH_SVG}px';
    var text_length = '${(0.5 + min(2.0, 2*(length-1)*0.25))* BASE_WIDTH_SVG}';
    var side = 'right';
    if (browser.isFirefox) {
      dy = '-${0.55 * BASE_WIDTH_SVG}px';
      side = 'left';
    }

    var text_elt = svg.TextElement();
    text_elt.children.add(textpath_elt);
    textpath_elt.attributes = {
      'class': classname_dna_sequence,
      'href': '#${StrandComponent.insertion_id(substrand, offset, substrand.direction)}',
      'startOffset': start_offset,
      'side': side,
    };
    text_elt.attributes = {
      'dy': dy,
    };

    if (browser.isChrome) {
      textpath_elt.setAttribute('textLength', text_length);
    } else if (browser.isFirefox) {
      text_elt.setAttribute('textLength', text_length);
    } else {
      // ??
      text_elt.setAttribute('textLength', text_length);
    }



    this.element.children.add(text_elt);
  }
}
