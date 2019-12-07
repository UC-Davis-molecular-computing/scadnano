import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:tuple/tuple.dart';

import '../constants.dart' as constants;

part 'design_main_mismatch.over_react.g.dart';

@Factory()
UiFactory<DesignMainMismatchProps> DesignMainMismatch = _$DesignMainMismatch;

@Props()
class _$DesignMainMismatchProps extends UiProps {
  Point<num> base_svg_pos;
  bool forward;
}

@Component2()
class DesignMainMismatchComponent extends UiComponent2<DesignMainMismatchProps> {
  @override
  render() {
    return create_mismatch_svg_star(this.props.base_svg_pos, this.props.forward);
  }
}

ReactElement create_mismatch_svg_star(Point<num> base_svg_pos, bool forward) {
  List<num> xs = List<num>.from(STAR_ORIGIN.item1);
  List<num> ys = List<num>.from(STAR_ORIGIN.item2);

  num rotate_degrees = 0;
  if (!forward) {
    rotate_degrees = 180;
  }

  num x0 = base_svg_pos.x;
  num y0 = base_svg_pos.y - 1.0 * constants.BASE_HEIGHT_SVG;
// translate from origin
  for (int i = 0; i < xs.length; i++) {
    xs[i] += x0;
    ys[i] += y0;
  }

  List<String> points = [];
  for (int i = 0; i < xs.length; i++) {
    points.add('${xs[i].toStringAsFixed(2)},${ys[i].toStringAsFixed(2)}');
  }

  return (Dom.polygon()
    ..className = 'mismatch-star'
    ..points = points.join(' ')
    ..transform = 'rotate(${rotate_degrees} ${base_svg_pos.x} ${base_svg_pos.y})')();
}

final Tuple2<List<num>, List<num>> STAR_ORIGIN = _star_at_origin();

Tuple2<List<num>, List<num>> _star_at_origin() {
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
  return Tuple2<List<num>, List<num>>(xs, ys);
}

