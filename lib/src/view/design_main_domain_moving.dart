// @dart=2.9
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/reducers/domains_move_reducer.dart';

import 'pure_component.dart';
import 'transform_by_helix_group.dart';
import '../state/group.dart';
import '../state/domain.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_domain_moving.over_react.g.dart';

UiFactory<DesignMainDomainMovingProps> DesignMainDomainMoving = _$DesignMainDomainMoving;

mixin DesignMainDomainMovingPropsMixin on UiProps {
  Domain domain_moved;
  Color color;
  HelixGroup original_group;
  HelixGroup current_group;
  BuiltSet<int> side_selected_helix_idxs;
  int delta_view_order;
  int delta_offset;
  bool delta_forward;
  bool allowable;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;
  num domain_helix_svg_position_y;
}

class DesignMainDomainMovingProps = UiProps
    with DesignMainDomainMovingPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainDomainMovingComponent extends UiComponent2<DesignMainDomainMovingProps>
    with PureComponent, TransformByHelixGroup<DesignMainDomainMovingProps> {
  @override
  render() {
    Helix helix = props.helices[props.domain_moved.helix];
    var start_svg = helix.svg_base_pos(
        props.domain_moved.offset_5p, props.domain_moved.forward, props.domain_helix_svg_position_y);
    var end_svg = helix.svg_base_pos(
        props.domain_moved.offset_3p, props.domain_moved.forward, props.domain_helix_svg_position_y);

    var classname = constants.css_selector_domain_moving;
    if (!props.allowable) {
      classname += ' ' + constants.css_selector_disallowed;
    }

    var hex_color = props.color.toHexColor();
    var hex_color_css = hex_color.toCssString();

    return (Dom.line()
      ..stroke = hex_color_css
      ..transform = transform_of_helix(helix.idx)
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..className = classname)();
  }
}
