import 'dart:svg' hide Point;

import 'view.dart';
import '../model/helix.dart';
import '../app.dart';

const String SIDE_VIEW_PREFIX = 'side-view';

/// Holds side view of grid of helices in this.element as a SVG group element
/// (<g> in html; GElement in dart:html)
class SideViewComponent {
  final GElement root_element;
  final Map<GridPosition, HelixSideViewComponent> helix_elts_map = {};

  //TODO: add dummy element as in MainViewComponent in case no helices are rendered

  SideViewComponent(this.root_element) {}

  /// Redraw elements in place
  //TODO: handle changed number of potential helices
  render() {
    this.root_element.children.clear();

    helix_elts_map.clear();
    for (var helix in app.model.dna_design.helices) {
      var helix_side_view_elt = HelixSideViewComponent(helix: helix);
      this.root_element.children.add(helix_side_view_elt.root_element);
      var grid_pos = helix.grid_position();
      helix_elts_map[grid_pos] = helix_side_view_elt;
      helix_side_view_elt.render();
    }

    for (var pot_helix in app.model.dna_design.potential_helices) {
      var helix_side_view_elt = HelixSideViewComponent(potential_helix: pot_helix);
      this.root_element.children.add(helix_side_view_elt.root_element);
      var grid_pos = pot_helix.grid_position();
      helix_elts_map[grid_pos] = helix_side_view_elt;
      helix_side_view_elt.render();
    }


//    for (var helix_side_view_elt in helix_elts_map.values) {
//      this.root_element.children.add(helix_side_view_elt.root_element);
//      helix_side_view_elt.render();
//    }
  }
}

const String HELIX_EMPTY_COLOR = 'lightgoldenrodyellow';
const String HELIX_NONEMPTY_COLOR = 'goldenrod';

/// Used to represent both Helices and PotentialHelices.
/// Exactly one of helix and potential_helix should be null.
class HelixSideViewComponent extends ReactiveComponent {
  final Helix helix;
  final PotentialHelix potential_helix;
  final GElement root_element;
  final CircleElement circle;
  final TextElement text;

  static const RADIUS = 25.0;

  g2c(num gCoordinate) => 2 * RADIUS * (gCoordinate + 1);

  HelixSideViewComponent({Helix this.helix = null, PotentialHelix this.potential_helix = null})
      : root_element = GElement(),
        circle = CircleElement(),
        text = TextElement() {

    assert(this.helix == null && this.potential_helix != null ||
        this.helix != null && this.potential_helix == null);

    //TODO: ChangeNotifier isn't the right tool to use for helices/potential_helices being clicked; they appear and disappear rather than change
    int gh,gv;
    if (this.helix != null) {
      gh = this.helix.gh;
      gv = this.helix.gv;
      this.listen(this.helix);
    } else {
      gh = this.potential_helix.gh;
      gv = this.potential_helix.gv;
      this.listen(this.potential_helix);
    }

    root_element.children.add(circle);
    var cx = g2c(gh);
    var cy = g2c(gv);
    root_element.setAttribute('transform', 'translate($cx $cy)');
    circle.setAttribute('class', '$SIDE_VIEW_PREFIX-helix-circle');
    text.setAttribute('class', '$SIDE_VIEW_PREFIX-helix-text');
    circle.setAttribute('r', '$RADIUS');
  }

  render() {
    if (this.helix == null) {
      circle.classes.remove('used');
      text.innerHtml = '';
      root_element.children.remove(text);
    } else {
      circle.classes.add('used');
      text.innerHtml = helix.idx.toString();
      if (!root_element.children.contains(text)) {
        root_element.children.add(text);
      }
    }
  }
}
