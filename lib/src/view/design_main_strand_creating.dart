import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';

import '../state/helix.dart';
import '3p_end.dart';
import '5p_end.dart';

part 'design_main_strand_creating.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandCreatingProps> DesignMainStrandCreating = _$DesignMainStrandCreating;

@Props()
class _$DesignMainStrandCreatingProps extends UiProps {
  Helix helix;
  bool forward;
  int start;
  int end;
  Color color;
}

@Component2()
class DesignMainStrandCreatingComponent extends UiComponent2<DesignMainStrandCreatingProps> {
  @override
  render() {
    Point<num> start_svg = props.helix.svg_base_pos(props.start, props.forward);
    Point<num> end_svg = props.helix.svg_base_pos(props.end - 1, props.forward);

    String classname_5p = 'five-prime-end-first-substrand';
    String classname_3p = 'three-prime-end-last-substrand';

    return (Dom.g()..className = 'strand-creating')(
      (Dom.line()
        ..stroke = props.color.toHexColor().toCssString()
        ..x1 = '${start_svg.x}'
        ..y1 = '${start_svg.y}'
        ..x2 = '${end_svg.x}'
        ..y2 = '${end_svg.y}'
        ..key = 'line'
        ..className = 'substrand-line')(),
      (End5Prime()
        ..classname = classname_5p
        ..pos = props.forward ? start_svg : end_svg
        ..color = props.color
        ..forward = props.forward
        ..id = '5p-strand-creating')(),
      (End3Prime()
        ..classname = classname_3p
        ..pos = props.forward ? end_svg : start_svg
        ..color = props.color
        ..forward = props.forward
        ..id = '3p-strand-creating')(),
    );
  }
}
