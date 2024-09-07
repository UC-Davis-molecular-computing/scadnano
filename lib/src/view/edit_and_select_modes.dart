// @dart=2.9
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/selectable.dart';
import '../state/app_state.dart';
import '../view/redraw_counter_component_mixin.dart';

import '../app.dart';
import '../state/edit_mode.dart';
import '../state/select_mode.dart';
import '../state/select_mode_state.dart';
import '../actions/actions.dart' as actions;
import 'edit_mode.dart';
import 'select_mode.dart';
import 'view.dart';

part 'edit_and_select_modes.over_react.g.dart';

UiFactory<EditAndSelectModesProps> ConnectedEditAndSelectModes = connect<AppState, EditAndSelectModesProps>(
  mapStateToProps: (state) {
    bool is_origami = (state.maybe_design?.is_origami == true);
    return EditAndSelectModes()
      ..edit_modes = state.ui_state.edit_modes
      ..select_mode_state = state.ui_state.select_mode_state
      ..is_origami = is_origami
      ..edit_mode_menu_visible = state.ui_state.show_edit_mode_menu;
  },
  // Used for component test.
  forwardRef: true,
)(EditAndSelectModes);

UiFactory<EditAndSelectModesProps> EditAndSelectModes = _$EditAndSelectModes;

mixin EditAndSelectModesProps on UiProps {
  BuiltSet<EditModeChoice> edit_modes;
  SelectModeState select_mode_state;
  bool is_origami;
  bool edit_mode_menu_visible;
}

class EditAndSelectModesComponent extends UiComponent2<EditAndSelectModesProps> with RedrawCounterMixin {
  @override
  render() {
    bool select_mode = props.edit_modes.contains(EditModeChoice.select) ||
        props.edit_modes.contains(EditModeChoice.rope_select);
    return [
      if (select_mode && props.edit_mode_menu_visible)
        (SelectMode()
          ..select_mode_state = props.select_mode_state
          ..is_origami = props.is_origami
          ..key = 'select-modes')(),
      if (select_mode && props.edit_mode_menu_visible)
        (Dom.div()
          ..className = FIXED_VERTICAL_SEPARATOR //FIXED_HORIZONTAL_SEPARATOR
          ..key = 'modes-separator')(),
      if (props.edit_mode_menu_visible)
        (EditMode()
          ..modes = props.edit_modes
          ..key = 'edit-modes')(),
      (Dom.button()
        ..key = 'edit-mode-toggle-button'
        ..className = 'edit-mode-toggle-button'
        ..title = props.edit_mode_menu_visible ? 'Hide edit mode menu' : 'Open edit mode menu'
        ..onClick = (_) => (app.dispatch(actions.ShowEditMenuToggle())))((Dom.img()
        ..className = props.edit_mode_menu_visible ? '' : 'appear'
        ..src = 'images/show_menu.png')())
    ];
  }
}
