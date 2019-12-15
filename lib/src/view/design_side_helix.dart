import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/position3d.dart';

import '../state/mouseover_data.dart';
import '../app.dart';
import '../state/helix.dart';
import 'design_side_rotation.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_side_helix.over_react.g.dart';

const String SIDE_VIEW_PREFIX = 'side-view';

//UiFactory<_$DesignSideHelixProps> ConnectedDesignSideHelix = connect<AppState, _$DesignSideHelixProps>(
//  mapStateToProps: (state) => (DesignSideHelix()),
//)(DesignSideHelix);

@Factory()
UiFactory<DesignSideHelixProps> DesignSideHelix = _$DesignSideHelix;

@Props()
class _$DesignSideHelixProps extends UiProps with ConnectPropsMixin {
  Helix helix;
  bool selected;
  bool mouse_is_over;
  MouseoverData mouseover_data;
  BuiltSet<EditModeChoice> edit_modes;
}

@Component2()
class DesignSideHelixComponent extends UiComponent2<DesignSideHelixProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    Helix helix = nextProps['DesignSideHelixProps.helix'];
    MouseoverData mouseover_data = nextProps['DesignSideHelixProps.mouseover_data'];
    bool selected = nextProps['DesignSideHelixProps.selected'];
    BuiltSet<EditModeChoice> edit_modes = nextProps['DesignSideHelixProps.edit_modes'];
    bool mouse_is_over = nextProps['DesignSideHelixProps.mouse_is_over'];
    bool should = !(helix == props.helix &&
        mouseover_data == props.mouseover_data &&
        selected == props.selected &&
        edit_modes == props.edit_modes &&
        mouse_is_over == props.mouse_is_over);
    return should;
  }

  @override
  render() {
//    print('rendering side helix ${props.helix.idx}');
    MouseoverData mouseover_data = this.props.mouseover_data;
//    print('  mouseover_data: $mouseover_data');

    Helix helix = props.helix;

    Position3D pos3d = helix.position3d();
    Point<num> center = Point<num>(pos3d.x, pos3d.y);
    bool selected = props.selected;

    String classname_circle = '$SIDE_VIEW_PREFIX-helix-circle';
    if (selected) {
      classname_circle += ' selected';
    }
    if (props.mouse_is_over && props.edit_modes.contains(EditModeChoice.helix)) {
      classname_circle += ' deletable';
    }

    var children = [
      (Dom.circle()
        ..className = classname_circle
        ..r = '${constants.SIDE_HELIX_RADIUS}'
        ..onClick = ((e) => this._handle_click(e, helix))
        ..key = 'circle')(),
      (Dom.text()
        ..className = '$SIDE_VIEW_PREFIX-helix-text'
        ..onClick = ((e) => this._handle_click(e, helix))
        ..key = 'text')(this.props.helix.idx.toString()),
    ];

//    print('checking mouseover data');
    if (mouseover_data != null) {
//      print('mouseover data not null; creating DesignSideRotation now');
      assert(mouseover_data.helix.idx == this.props.helix.idx);
      var rot_component = (DesignSideRotation()
        ..radius = constants.SIDE_HELIX_RADIUS
        ..helix = mouseover_data.helix
        ..offset = mouseover_data.offset
        ..key = 'rotation'
        ..className = '$SIDE_VIEW_PREFIX-helix-rotation')();
      children.add(rot_component);
    }

    return (Dom.g()
      ..transform = 'translate(${center.x} ${center.y})')(children);
  }

  _handle_click(SyntheticMouseEvent event, Helix helix) {
    if (props.edit_modes.contains(EditModeChoice.helix)) {
      app.dispatch(actions.HelixRemove(helix.idx));
    } else if (event.shiftKey) {
      app.dispatch(actions.HelixSelect(helix.idx, false));
    } else if (event.ctrlKey || event.metaKey) {
      app.dispatch(actions.HelixSelect(helix.idx, true));
    }
  }

}
