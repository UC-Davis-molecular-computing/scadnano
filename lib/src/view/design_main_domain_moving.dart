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

mixin DesignMainDomainMovingProps on UiProps implements TransformByHelixGroupPropsMixin {
  late Domain domain_moved;
  late Color color;
  late HelixGroup original_group;
  late HelixGroup current_group;
  late BuiltSet<int> side_selected_helix_idxs;
  late int delta_view_order;
  late int delta_offset;
  late bool delta_forward;
  late bool allowable;

  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late Geometry geometry;
  late num domain_helix_svg_position_y;
}

class DesignMainDomainMovingComponent extends UiComponent2<DesignMainDomainMovingProps> with PureComponent {
  @override
  render() {
    Helix helix = props.helices[props.domain_moved.helix]!;
    var start_svg = helix.svg_base_pos(props.domain_moved.offset_5p, props.domain_moved.forward,
        props.domain_helix_svg_position_y, props.geometry);
    var end_svg = helix.svg_base_pos(props.domain_moved.offset_3p, props.domain_moved.forward,
        props.domain_helix_svg_position_y, props.geometry);

    var classname = constants.css_selector_domain_moving;
    if (!props.allowable) {
      classname += ' ' + constants.css_selector_disallowed;
    }

    var hex_color = props.color.toHexColor();
    var hex_color_css = hex_color.toCssString();

    return (Dom.line()
      ..stroke = hex_color_css
      ..transform = transform_of_helix2(props, helix.idx)
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..className = classname)();
  }
}
