import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/view/redraw_counter_component_mixin.dart';

import '../app.dart';
import '../state/edit_mode.dart';
import '../actions/actions.dart' as actions;

part 'edit_mode.over_react.g.dart';

UiFactory<EditModeProps> ConnectedEditMode = connect<AppState, EditModeProps>(
  mapStateToProps: (state) {
    return EditMode()..modes = state.ui_state.edit_modes;
  },
  // Used for component test.
  forwardRef: true,
)(EditMode);

UiFactory<EditModeProps> EditMode = _$EditMode;

mixin EditModeProps on UiProps {
  BuiltSet<EditModeChoice> modes;
}

class EditModeComponent extends UiComponent2<EditModeProps> with RedrawCounterMixin {
  @override
  render() {
    return (Dom.div()..id = 'edit-mode')([
      (Dom.label()..key = 'label')('Edit mode:'),
      ...[for (var choice in EditModeChoice.values) this._button_for_choice(choice)],
    ]);
  }
  static button_response(EditModeChoice mode){
    app.dispatch(actions.EditModeToggle(mode));
    app.dispatch(actions.SelectionsClear());
  }

  ReactElement _button_for_choice(EditModeChoice mode) {
    return (Dom.button()
      ..onClick = ((_) => button_response(mode))
      ..className = 'mode-button ' +
          (props.modes.contains(mode) ? 'edit-mode-button-selected' : 'edit-mode-button-unselected')
      // TODO(benlee12): Find out how to only added this id for testing and not production if inefficient.
      ..addTestId('scadnano.EditModeComponent.button.${mode.name}')
      ..key = mode.name)(mode.display_name());
  }
}
