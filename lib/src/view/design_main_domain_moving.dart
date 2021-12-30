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
  Domain domain;
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
  num helix_svg_position_y;
}

class DesignMainDomainMovingProps = UiProps
    with DesignMainDomainMovingPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainDomainMovingComponent extends UiComponent2<DesignMainDomainMovingProps>
    with PureComponent, TransformByHelixGroup<DesignMainDomainMovingProps> {
  @override
  render() {
    Domain domain_moved = move_domain(
      domain: props.domain,
      original_group: props.original_group,
      current_group: props.current_group,
      delta_view_order: props.delta_view_order,
      delta_offset: props.delta_offset,
      delta_forward: props.delta_forward,
      set_first_last_false: true, // don't want to display 5'/3' ends while moving
    );

    Helix helix = props.helices[domain_moved.helix];
    var start_svg = helix.svg_base_pos(domain_moved.offset_5p, domain_moved.forward, props.helix_svg_position_y);
    var end_svg = helix.svg_base_pos(domain_moved.offset_3p, domain_moved.forward, props.helix_svg_position_y);

    var classname = constants.css_selector_domain_moving;
    if (!props.allowable) {
      classname += ' ' + constants.css_selector_disallowed;
    }

    return (Dom.line()
      ..stroke = props.color.toHexColor().toCssString()
      ..transform = transform_of_helix(helix.idx)
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..className = classname)();
  }
}
