import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import '../state/app_state.dart';
import '../view/redraw_counter_component_mixin.dart';

import '../app.dart';
import '../state/edit_mode.dart';
import '../actions/actions.dart' as actions;

part 'edit_mode.over_react.g.dart';

//NOTE: this is only used for testing; in the app,
// EditModeComponent is used directly without the ConnectedEditMode wrapper.
UiFactory<EditModeProps> ConnectedEditMode = connect<AppState, EditModeProps>(
  mapStateToProps: (state) {
    return EditMode()..modes = state.ui_state.edit_modes;
  },
  // Used for component test.
  forwardRef: true,
)(EditMode);

UiFactory<EditModeProps> EditMode = _$EditMode;

mixin EditModeProps on UiProps {
  late BuiltSet<EditModeChoice> modes;
}

class EditModeComponent extends UiComponent2<EditModeProps> with RedrawCounterMixin<EditModeProps> {
  @override
  render() {
    return (Dom.div()..id = 'edit-mode')([
      ...[for (var choice in EditModeChoice.values) this._button_for_choice(choice)],
    ]);
  }

  ReactElement _button_for_choice(EditModeChoice mode) {
    return (Dom.button()
      ..onClick = (_) {
        app.dispatch(actions.EditModeToggle(mode));
        app.dispatch(actions.SelectionsClear());
      }
      ..className =
          'mode-button ' +
          (props.modes.contains(mode) ? 'edit-mode-button-selected' : 'edit-mode-button-unselected')
      // TODO(benlee12): Find out how to only added this id for testing and not production if inefficient.
      ..addTestId('scadnano.EditModeComponent.button.${mode.name}')
      ..title = mode.tooltip
      ..key = mode.display_name())((Dom.img()..src = mode.image_file)(), mode.display_name());
  }
}
