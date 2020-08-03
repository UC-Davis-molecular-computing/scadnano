import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/view/pure_component.dart';
import 'package:scadnano/src/view/transform_by_helix_group.dart';

import 'design_main_mouseover_rect_helix.dart';
import '../state/helix.dart';
import 'transform_by_helix_group.dart';

part 'design_main_mouseover_rect_helices.over_react.g.dart';

const _ID = 'mouseover-rectangle-main-view';
const _CLASS = 'mouseover-rectangle-main-view';

UiFactory<DesignMainMouseoverRectHelicesProps> DesignMainMouseoverRectHelices =
    _$DesignMainMouseoverRectHelices;

mixin DesignMainMouseoverRectHelicesPropsMixin on UiProps {
  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  bool only_display_selected_helices;
  BuiltSet<int> side_selected_helix_idxs;
}

class DesignMainMouseoverRectHelicesProps = UiProps
    with DesignMainMouseoverRectHelicesPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainMouseoverRectHelicesComponent extends UiComponent2<DesignMainMouseoverRectHelicesProps>
    with PureComponent, TransformByHelixGroup<DesignMainMouseoverRectHelicesProps> {
  @override
  render() {
    List<ReactElement> svg_groups = [];
    for (var group_name in props.groups.keys) {
      var group = props.groups[group_name];
      if (group.helices_view_order.isNotEmpty) {
        var first_helix_idx = group.helices_view_order.first;
        String transform = transform_of_helix(first_helix_idx);
        List<ReactElement> rect_elts = [];
        for (int helix_idx in group.helices_view_order) {
          if (props.only_display_selected_helices && props.side_selected_helix_idxs.contains(helix_idx)) {
            Helix helix = props.helices[helix_idx];
            rect_elts.add((DesignMainMouseoverRectHelix()
              ..helix = helix
              ..key = helix.idx)());
          }
        }
        if (rect_elts.isNotEmpty) {
          svg_groups.add((Dom.g()
            ..className = '$_CLASS-group-$group_name'
            ..transform = transform
            ..key = group_name)(rect_elts));
        }
      }
    }
    return (Dom.g()
      ..id = _ID
      ..className = _CLASS)(svg_groups);
  }
}
