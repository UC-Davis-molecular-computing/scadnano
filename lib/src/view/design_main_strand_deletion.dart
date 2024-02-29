import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/geometry.dart';

import '../state/domain.dart';
import '../state/helix.dart';
import '../app.dart';
import 'pure_component.dart';
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;
import '../state/selectable.dart';

part 'design_main_strand_deletion.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandDeletionProps> DesignMainStrandDeletion = _$DesignMainStrandDeletion;

@Props()
mixin DesignMainStrandDeletionPropsMixin on UiProps {
  SelectableDeletion selectable_deletion;
  Helix helix;
  String transform;
  bool selected;

  Domain get domain => selectable_deletion.domain;
  int get deletion => selectable_deletion.offset;
  num svg_position_y;
  bool retain_strand_color_on_selection;
}

class DesignMainStrandDeletionProps = UiProps with DesignMainStrandDeletionPropsMixin;

@Component2()
class DesignMainStrandDeletionComponent extends UiComponent2<DesignMainStrandDeletionProps>
    with PureComponent {
  @override
  render() {
    Geometry geometry = props.helix.geometry;
    Domain domain = props.domain;
    int deletion_offset = props.deletion;

    Point<num> pos = props.helix.svg_base_pos(deletion_offset, domain.forward, props.svg_position_y);

    // deletion
    var width = 0.8 * geometry.base_width_svg;
    var half_width = 0.5 * width;
    var path_cmds = 'M ${pos.x - half_width} ${pos.y - half_width} '
        'l ${width} ${width} m ${-width} ${0} l ${width} ${-width}';

    // deletion invisible background
    num background_width = geometry.base_width_svg;
    num background_height = geometry.base_height_svg;
    num background_x = pos.x - background_width / 2;
    num background_y = pos.y - background_height / 2;

    var classname = constants.css_selector_deletion_group;
    if (props.selected) {
      if (props.retain_strand_color_on_selection) {
        classname += ' ' + constants.css_selector_selected;
      } else {
        classname += ' ' + constants.css_selector_selected_pink;
      }
    }
    if (props.selectable_deletion.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    String key = 'deletion-H${domain.helix}-${deletion_offset}';
    String key_background = 'deletion-background-H${domain.helix}-${deletion_offset}';
    return (Dom.g()
          ..className = classname
          ..onPointerDown = ((ev) {
            if (deletion_selectable(props.selectable_deletion)) {
              props.selectable_deletion.handle_selection_mouse_down(ev.nativeEvent);
            }
          })
          ..onPointerUp = ((ev) {
            if (deletion_selectable(props.selectable_deletion)) {
              props.selectable_deletion.handle_selection_mouse_up(ev.nativeEvent);
            }
          })
          ..transform = props.transform)(
        (Dom.rect()
          ..className = 'deletion-background'
          ..x = background_x
          ..y = background_y
          ..width = background_width
          ..height = background_height
          ..onClick = ((_) {
            if (edit_mode_is_deletion()) {
              app.dispatch(actions.DeletionRemove(domain: props.domain, offset: props.deletion));
            }
          })
          ..key = key_background)(),
        (Dom.path()
          ..className = 'deletion-cross'
          ..fill = 'none'
          ..d = path_cmds
          ..onClick = ((_) {
            if (edit_mode_is_deletion()) {
              app.dispatch(actions.DeletionRemove(domain: props.domain, offset: props.deletion));
            }
          })
          ..id = props.selectable_deletion.id
          ..key = key)());
  }
}
