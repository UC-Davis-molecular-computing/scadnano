import 'dart:math';

import '../app.dart';
import '../model/helix.dart';

import 'package:over_react/over_react.dart';

part 'design_side_helix.over_react.g.dart';

const String HELIX_EMPTY_COLOR = 'lightgoldenrodyellow';
const String HELIX_NONEMPTY_COLOR = 'goldenrod';

const String SIDE_VIEW_PREFIX = 'side-view';

@Factory()
UiFactory<DesignSideHelixProps> DesignSideHelix = _$DesignSideHelix;

/// Used to represent both Helices and PotentialHelices.
/// Exactly one of helix and potential_helix should be null.
@Props()
class _$DesignSideHelixProps extends UiProps {
  Helix helix;
  GridPosition grid_position;
  bool used;
}

@Component()
class DesignSideHelixComponent extends UiComponent<DesignSideHelixProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    Point<num> center = _g2c(this.props.grid_position);

    return (Dom.g()..transform = 'translate(${center.x} ${center.y})')([
      (Dom.circle()
        ..className = '$SIDE_VIEW_PREFIX-helix-circle' + (this.props.used ? ' used' : ' potential')
        ..r = '$RADIUS'
        ..key = 'circle'
        ..onClick = (e) => this._handle_click(e))(),
      if (this.props.used)
        (Dom.text()
          ..className = '$SIDE_VIEW_PREFIX-helix-text'
          ..key = 'text'
          ..onClick = (e) => this._handle_click(e))(this.props.helix.idx().toString()),
    ]);
  }

  _handle_click(SyntheticMouseEvent e) {
    if (!e.ctrlKey) {
      return;
    }

    if (this.props.used) {
      if (this.props.helix.has_substrands()) {
        //TODO: detect if any strands are on this helix and warn before deleting
        //TODO: give option to user to remove only substrands on this helix and split the remaining substrands
      }
    }

    int idx = this.props.used ? this.props.helix.idx() : app.model.dna_design.helices.length;
    var params = UseHelixActionParameters(!this.props.used, this.props.grid_position, idx);
    app.model.dna_design.helices_store.use_helix(params);
  }
}

const RADIUS = 25.0;

Point<num> _g2c(GridPosition gp) => Point<num>(2 * RADIUS * (gp.h + 1), 2 * RADIUS * (gp.v + 1));
