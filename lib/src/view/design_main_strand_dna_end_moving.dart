import 'dart:math';

import 'package:over_react/over_react_redux.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/dna_end.dart';

import 'package:scadnano/src/state/dna_end_move.dart';
import 'package:scadnano/src/state/helix.dart';

import '../app.dart';
import '3p_end.dart';
import '5p_end.dart';

part 'design_main_strand_dna_end_moving.over_react.g.dart';

typedef PointerDownHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

UiFactory<EndMovingProps> ConnectedEndMoving = connect<DNAEndsMove, EndMovingProps>(
  mapStateToPropsWithOwnProps: (dna_ends_move, props) {
    int current_offset = dna_ends_move?.current_capped_offset_of(props.dna_end);
//    print('dna_ends_move:  $dna_ends_move');

    if (current_offset == null) {
      return EndMoving()..render = false;
    }
    print('*'*100);
    print('current_offset: $current_offset');
    return EndMoving()..current_offset = current_offset;
  },
  context: app.context_dna_ends_move,
)(EndMoving);

@Factory()
UiFactory<EndMovingProps> EndMoving = _$EndMoving;

@Props()
class _$EndMovingProps extends UiProps {
  DNAEnd dna_end;
  int original_offset;
  Color color;
  bool forward;
  Helix helix;
  bool is_5p;

  int current_offset;
  bool render;
}

@Component2()
class EndMovingComponent extends UiComponent2<EndMovingProps> {
  @override
  get defaultProps => (newProps()..render=true);

  @override
  render() {
    if (!props.render) {
      return null;
    }
    Point<num> pos = props.helix.svg_base_pos(props.current_offset, props.forward);
    EndEitherPrimeProps end_props = (props.is_5p ? End5Prime() : End3Prime());
    String classname = props.is_5p ? 'five-prime-end-moving' : 'three-prime-end-moving';
    end_props = end_props
      ..on_pointer_down = null
      ..on_mouse_up = null
      ..pos = pos
      ..color = props.color
      ..classname = classname
      ..forward = props.forward;
    return end_props();
  }
}
