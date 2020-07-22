import 'dart:math';

import 'package:over_react/over_react.dart';
import '../state/modification.dart';

import '../state/strand.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_strand_modification_domain.over_react.g.dart';


UiFactory<DesignMainStrandModificationDomainProps> DesignMainStrandModificationDomain =
    _$DesignMainStrandModificationDomain;


mixin DesignMainStrandModificationDomainProps on UiProps {
  Address address;
  Helix helix;
  Modification modification;
  bool display_connector;
  int font_size;
  bool invert_y;
}


class DesignMainStrandModificationDomainComponent
    extends UiComponent2<DesignMainStrandModificationDomainProps> {
  @override
  render() {
    Point<num> pos = props.helix.svg_base_pos(props.address.offset, props.address.forward);
    bool display_connector = props.display_connector;
    if (props.modification is Modification5Prime) {
      return (Dom.g()..className = "'modification-5'")([
        if (display_connector) _end_connector(pos, props.address.forward),
        _modification_svg(pos, props.address.forward, display_connector),
      ]);
    } else if (props.modification is Modification3Prime) {
      return (Dom.g()..className = "'modification-3'")([
        if (display_connector) _end_connector(pos, props.address.forward),
        _modification_svg(pos, props.address.forward, display_connector),
      ]);
    } else {
      return (Dom.g()..className = 'modification-internal')([
        if (display_connector) _internal_connector(pos, props.address.forward),
        _modification_svg(pos, props.address.forward, display_connector),
      ]);
    }
  }

  ReactElement _end_connector(Point<num> pos, bool forward) {
    num y_delta = Y_DELTA_MOD;
    double y_del_small = (forward ? -y_delta : y_delta) / 4.0;
    double x = -X_DELTA_MOD;
    return (Dom.polyline()
      ..fill = 'none'
      ..stroke = 'black'
      ..strokeWidth = 2
      ..points = ''
          '${pos.x},${pos.y} '
          '${pos.x + x},${pos.y + y_del_small} '
          '${pos.x},${pos.y + 2 * y_del_small} '
          '${pos.x + x},${pos.y + 3 * y_del_small} '
          '${pos.x},${pos.y + 4 * y_del_small}'
      ..key = 'connector')();
  }

  ReactElement _internal_connector(Point<num> pos, bool forward) {
    num y_delta = Y_DELTA_MOD;
    double y_del_small = (forward ? -y_delta : y_delta).toDouble();
    return (Dom.line()
      ..stroke = 'black'
      ..strokeWidth = 2
      ..x1 = pos.x
      ..y1 = pos.y
      ..x2 = pos.x
      ..y2 = pos.y + y_del_small
      ..key = 'connector')();
  }

  ReactElement _modification_svg(Point<num> pos, bool forward, bool display_connector) {
    num y_delta = Y_DELTA_MOD;
    double y_del_small = (forward ? -1.1 * y_delta : y_delta).toDouble();
    int font_size = props.font_size;
    String baseline = forward ? 'baseline' : 'hanging';
    if (!display_connector) {
      baseline = 'middle';
    }
    return (Dom.text()
      ..className = 'modification-text'
      ..fontSize = font_size
      ..x = pos.x
      ..y = display_connector ? pos.y + y_del_small : pos.y
      ..dominantBaseline = baseline
      ..key = 'mod')(props.modification.display_text);
  }
}

//num y_delta_mod(Helix helix) => 1.8 * helix.svg_height() / 2.0;
//num y_delta_mod(Helix helix) => constants.BASE_HEIGHT_SVG * 1.8;
const Y_DELTA_MOD = constants.BASE_HEIGHT_SVG * 1.8;
const X_DELTA_MOD = constants.BASE_WIDTH_SVG / 3.0;
