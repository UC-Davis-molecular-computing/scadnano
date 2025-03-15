import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:tuple/tuple.dart';

part 'design_main_warning_star.over_react.g.dart';

UiFactory<DesignMainWarningStarProps> DesignMainWarningStar = _$DesignMainWarningStar;

mixin DesignMainWarningStarProps on UiProps {
  late Point<double> base_svg_pos;
  late bool forward;
  late Geometry geometry;
  late String color;
}

class DesignMainWarningStarComponent extends UiComponent2<DesignMainWarningStarProps> {
  @override
  render() {
    List<double> xs = List<double>.from(_star_at_origin().item1);
    List<double> ys = List<double>.from(_star_at_origin().item2);

    num rotate_degrees = 0;
    if (!props.forward) {
      rotate_degrees = 180;
    }

    num x0 = props.base_svg_pos.x;
    num y0 = props.base_svg_pos.y - 1.0 * props.geometry.base_width_svg;
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
      ..className = 'warning-star'
      ..points = points.join(' ')
      ..style = {"stroke": "${props.color}", "fill": "${props.color}"}
      ..transform = 'rotate(${rotate_degrees} ${props.base_svg_pos.x} ${props.base_svg_pos.y})')();
  }

  Tuple2<List<double>, List<double>> _star_at_origin() {
    // assume bottom points of star are at origin
    List<double> xs = [];
    List<double> ys = [];

    double inner_radius = 0.4 * props.geometry.base_width_svg;
    double outer_radius = 0.65 * props.geometry.base_width_svg;

    int num_points = 12;
    double inner_angle = 0;
    double outer_angle = inner_angle + pi / num_points;
    for (int i = 0; i < num_points; i++) {
      double x_inner = inner_radius * cos(inner_angle);
      double y_inner = inner_radius * sin(inner_angle);
      double x_outer = outer_radius * cos(outer_angle);
      double y_outer = outer_radius * sin(outer_angle);
      xs.add(x_inner);
      xs.add(x_outer);
      ys.add(y_inner);
      ys.add(y_outer);
      inner_angle += 2 * pi / num_points;
      outer_angle += 2 * pi / num_points;
    }
    return Tuple2<List<double>, List<double>>(xs, ys);
  }
}
