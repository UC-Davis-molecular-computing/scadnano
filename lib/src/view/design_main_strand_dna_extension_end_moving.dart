// @dart=2.9
import 'dart:math';

import 'package:over_react/over_react_redux.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/dna_extensions_move.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/group.dart';
import '../state/dna_end.dart';

import '../state/dna_ends_move.dart';
import '../state/helix.dart';

import '../app.dart';
import '3p_end.dart';
import '5p_end.dart';

import '../util.dart' as util;

part 'design_main_strand_dna_extension_end_moving.over_react.g.dart';

typedef PointerDownHandler = void Function(react.SyntheticPointerEvent);
typedef MouseUpHandler = void Function(react.SyntheticMouseEvent);

UiFactory<ExtensionEndMovingProps> ConnectedExtensionEndMoving =
    connect<DNAExtensionsMove, ExtensionEndMovingProps>(
  mapStateToPropsWithOwnProps: (dna_extensions_move, props) {
    Point<double> current_point = dna_extensions_move?.current_point_of(props.dna_end);
    if (current_point == null) {
      return ExtensionEndMoving()..render = false;
    }
    return ExtensionEndMoving()..current_point = current_point;
  },
  context: app.context_extensions_move,
)(ExtensionEndMoving);

UiFactory<ExtensionEndMovingProps> ExtensionEndMoving = _$ExtensionEndMoving;

mixin ExtensionEndMovingProps on UiProps {
  DNAEnd dna_end;
  Extension ext;
  Geometry geometry;
  Point<double> attached_end_svg;
  Helix helix;
  HelixGroup group;
  Color color;
  bool forward;
  bool is_5p;
  bool allowable;

  Point<double> current_point;
  bool render;
}

class ExtensionEndMovingComponent extends UiComponent2<ExtensionEndMovingProps> {
  @override
  get defaultProps => (newProps()
    ..render = true
    ..allowable = true);

  @override
  render() {
    if (!props.render) {
      return null;
    }

    // current_point is in canvas coordinate space, so subtract it with helix group position
    // to get helix group coordinate space (since translation transform is already applied to DesignMainDNAEndComponent))
    Point<double> pos = props.current_point - props.group.translation(props.geometry);

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
    var display_angle = util.compute_extension_length_and_angle_from_point(
        pos, props.attached_end_svg, props.ext, props.ext.adjacent_domain, props.geometry);
    var rotation_degrees = util.compute_end_rotation(display_angle.item2, props.forward, props.is_5p);
    // https://stackoverflow.com/questions/15138801/rotate-rectangle-around-its-own-center-in-svg
    end_props = end_props..transform = "rotate($rotation_degrees)";
    return end_props();
  }
}
