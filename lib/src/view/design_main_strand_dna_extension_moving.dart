import 'dart:math';

import 'package:over_react/over_react_redux.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/dna_extensions_move.dart';
import '../state/dna_end.dart';

import '../state/dna_ends_move.dart';
import '../state/helix.dart';

import '../app.dart';
import '3p_end.dart';
import '5p_end.dart';

part 'design_main_strand_dna_extension_moving.over_react.g.dart';

typedef PointerDownHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

UiFactory<ExtensionMovingProps> ConnectedExtensionMoving = connect<DNAExtensionsMove, ExtensionMovingProps>(
  mapStateToPropsWithOwnProps: (dna_extensions_move, props) {
    Point<num> current_point = dna_extensions_move?.current_point_of(props.dna_end);
    if (current_point == null) {
      return ExtensionMoving()..render = false;
    }
    return ExtensionMoving()..current_point = current_point;
  },
  context: app.context_extensions_move,
)(ExtensionMoving);


UiFactory<ExtensionMovingProps> ExtensionMoving = _$ExtensionMoving;


mixin ExtensionMovingProps on UiProps {
  DNAEnd dna_end;
  Helix helix;
  Color color;
  bool forward;
  bool is_5p;
  bool allowable;

  Point<num> current_point;
  bool render;
  num svg_position_y;
  String transform;
}


class ExtensionMovingComponent extends UiComponent2<ExtensionMovingProps> {
  @override
  get defaultProps => (newProps()
    ..render = true
    ..allowable = true);

  @override
  render() {
    if (!props.render) {
      return null;
    }
    Point<num> pos = props.current_point;
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
