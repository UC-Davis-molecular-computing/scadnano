import 'dart:math';
import 'dart:svg' hide Point;

import 'model.dart';
import 'app.dart';

const String SIDE_VIEW_PREFIX = 'side-view';

/// Holds side view of grid of helices in this.element as a SVG group element
/// (<g> in html; GElement in dart:html)
class SideViewElement {
  final GElement element = GElement();
  final Map<Point<int>, HelixSideViewElement> helix_elts_map = {};

  SideViewElement() {
    for (var helix in app.model.dna_design.helices) {
      var helix_side_view_elt = HelixSideViewElement(helix);
      element.children.add(helix_side_view_elt.element);
      var grid_pos = helix.grid_position;
      helix_elts_map[grid_pos] = helix_side_view_elt;
    }
  }

  /// Redraw elements in place
  //TODO: handle changed number of total helices
  render() {
    for (var helix_side_view_elt in helix_elts_map.values) {
      helix_side_view_elt.render();
    }
  }
}

const String HELIX_EMPTY_COLOR = 'lightgoldenrodyellow';
const String HELIX_NONEMPTY_COLOR = 'goldenrod';

class HelixSideViewElement {
  final Helix helix;
  final GElement element;
  final CircleElement circle;
  final TextElement text;

  static const RADIUS = 25.0;

  g2c(num gCoordinate) => 2 * RADIUS * (gCoordinate + 1);

  HelixSideViewElement(Helix this.helix)
      : element = GElement(),
        circle = CircleElement(),
        text = TextElement() {
    element.children.add(circle);
    var cx = g2c(helix.gx);
    var cy = g2c(helix.gy);
    element.setAttribute('transform', 'translate($cx $cy)');
    circle.setAttribute('class', '$SIDE_VIEW_PREFIX-helix-circle');
    text.setAttribute('class', '$SIDE_VIEW_PREFIX-helix-text');
    circle.setAttribute('r', '$RADIUS');
    render();
  }

  render() {
    if (!helix.used) {
      circle.classes.remove('used');
      text.innerHtml = '';
      element.children.remove(text);
    } else {
      circle.classes.add('used');
      text.innerHtml = helix.idx.toString();
      if (!element.children.contains(text)) {
        element.children.add(text);
      }
    }
  }
}
