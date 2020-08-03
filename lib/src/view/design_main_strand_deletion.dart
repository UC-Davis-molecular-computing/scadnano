import 'dart:math';

import 'package:over_react/over_react.dart';

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
  Domain domain;
  int deletion;
  Helix helix;
  String transform;
}

class DesignMainStrandDeletionProps = UiProps with DesignMainStrandDeletionPropsMixin;

@Component2()
class DesignMainStrandDeletionComponent extends UiComponent2<DesignMainStrandDeletionProps>
    with PureComponent {
  @override
  render() {
    Domain domain = props.domain;
    int deletion_offset = props.deletion;

    Point<num> pos = props.helix.svg_base_pos(deletion_offset, domain.forward);

    // deletion
    var width = 0.8 * constants.BASE_WIDTH_SVG;
    var half_width = 0.5 * width;
    var path_cmds = 'M ${pos.x - half_width} ${pos.y - half_width} '
        'l ${width} ${width} m ${-width} ${0} l ${width} ${-width}';

    // deletion invisible background
    num background_width = constants.BASE_WIDTH_SVG;
    num background_height = constants.BASE_HEIGHT_SVG;
    num background_x = pos.x - background_width / 2;
    num background_y = pos.y - background_height / 2;

    String key = 'deletion-H${domain.helix}-${deletion_offset}';
    String key_background = 'deletion-background-H${domain.helix}-${deletion_offset}';
    return (Dom.g()
          ..className = 'deletion-group'
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
          ..id = key
          ..key = key)());
  }
}
