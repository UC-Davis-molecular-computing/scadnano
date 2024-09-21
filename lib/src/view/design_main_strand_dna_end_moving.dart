import 'dart:math';

import 'package:over_react/over_react_redux.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import '../state/dna_end.dart';

import '../state/dna_ends_move.dart';
import '../state/geometry.dart';
import '../state/helix.dart';

import '../app.dart';
import '3p_end.dart';
import '5p_end.dart';

part 'design_main_strand_dna_end_moving.over_react.g.dart';

typedef PointerDownHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

UiFactory<EndMovingProps> ConnectedEndMoving = connect<DNAEndsMove?, EndMovingProps>(
  mapStateToPropsWithOwnProps: (DNAEndsMove? dna_ends_move, EndMovingProps props) {
    if (dna_ends_move == null || props.dna_end == null) {
      return EndMoving()..render = false;
    }
    int? current_offset = dna_ends_move.current_capped_offset_of(props.dna_end!);
    if (current_offset == null) {
      return EndMoving()..render = false;
    }

    return EndMoving()
      ..current_offset = current_offset
      ..dna_end = dna_ends_move.ends_moving.first
      ..helix = dna_ends_move.helix
      ..color = props.color // below here are mock props
      ..forward = props.dna_end!.forward
      ..is_5p = props.dna_end!.is_5p
      ..svg_position_y = props.svg_position_y
      ..geometry = dna_ends_move.geometry
      ..transform = null;
  },
  context: app.context_dna_ends_move,
)(EndMoving);

UiFactory<EndMovingProps> EndMoving = _$EndMoving;

mixin EndMovingProps on UiProps {
  DNAEnd? dna_end;
  Helix? helix;
  Color? color;
  bool? forward;
  bool? is_5p;
  Geometry? geometry;

  int? current_offset;
  double? svg_position_y;
  String? transform;

  // optional but specified in defaultProps
  late bool render;
  late bool allowable;
}

class EndMovingComponent extends UiComponent2<EndMovingProps> {
  @override
  get defaultProps => (newProps()
    ..render = true
    ..allowable = true);

  @override
  render() {
    if (!props.render) {
      return null;
    }
    Helix helix = props.helix!;
    int current_offset = props.current_offset!;
    bool forward = props.forward!;
    double svg_position_y = props.svg_position_y!;
    bool is_5p = props.is_5p!;
    Color color = props.color!;
    Point<double> pos = helix.svg_base_pos(current_offset, forward, svg_position_y, props.geometry!);
    EndEitherPrimeProps end_props = (is_5p ? End5Prime() : End3Prime());
    String classname = (is_5p ? 'five-prime-end-moving' : 'three-prime-end-moving') +
        (props.allowable ? '' : ' disallowed-end');
    end_props = end_props
      ..classname = classname
      ..pos = pos
      ..color = color
      ..forward = forward;
    if (props.transform != null) {
      // https://stackoverflow.com/questions/15138801/rotate-rectangle-around-its-own-center-in-svg
      end_props = end_props..transform = props.transform;
    }
    return end_props();
  }
}
