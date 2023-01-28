import 'dart:math';

import 'package:over_react/over_react_redux.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import '../state/dna_end.dart';

import '../state/dna_ends_move.dart';
import '../state/helix.dart';

import '../app.dart';
import '3p_end.dart';
import '5p_end.dart';

part 'design_main_strand_dna_end_moving.over_react.g.dart';

typedef PointerDownHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

UiFactory<EndMovingProps> ConnectedEndMoving = connect<DNAEndsMove, EndMovingProps>(
  mapStateToPropsWithOwnProps: (dna_ends_move, props) {
    int current_offset = dna_ends_move?.current_capped_offset_of(props.dna_end);
    if (current_offset == null) {
      return EndMoving()..render = false;
    }
    return EndMoving()..current_offset = current_offset;
  },
  context: app.context_dna_ends_move,
)(EndMoving);


UiFactory<EndMovingProps> EndMoving = _$EndMoving;


mixin EndMovingProps on UiProps {
  DNAEnd dna_end;
  Helix helix;
  Color color;
  bool forward;
  bool is_5p;
  bool allowable;

  int current_offset;
  bool render;
  num svg_position_y;
  String transform;
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
    Point<num> pos = props.helix.svg_base_pos(props.current_offset, props.forward, props.svg_position_y);
    EndEitherPrimeProps end_props = (props.is_5p ? End5Prime() : End3Prime());
    String classname = (props.is_5p ? 'five-prime-end-moving' : 'three-prime-end-moving') +
        (props.allowable ? '' : ' disallowed-end');
    end_props = end_props
      ..on_pointer_down = null
      ..on_mouse_up = null
      ..pos = pos
      ..color = props.color
      ..classname = classname
      ..forward = props.forward;
    if (props.transform != null) {
      // https://stackoverflow.com/questions/15138801/rotate-rectangle-around-its-own-center-in-svg
      end_props = end_props..transform = props.transform;
    }
    return end_props();
  }
}
