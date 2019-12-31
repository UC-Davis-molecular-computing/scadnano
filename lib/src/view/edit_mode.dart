import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/app_state.dart';

import '../app.dart';
import '../state/edit_mode.dart';
import '../actions/actions.dart' as actions;

part 'edit_mode.over_react.g.dart';

UiFactory<EditModeProps> ConnectedEditMode = connect<AppState, EditModeProps>(mapStateToProps: (state) {
  return EditMode()..modes = state.ui_state.edit_modes;
})(EditMode);

@Factory()
UiFactory<EditModeProps> EditMode = _$EditMode;

@Props()
class _$EditModeProps extends UiProps {
  BuiltSet<EditModeChoice> modes;
}

@Component2()
class EditModeComponent extends UiComponent2<EditModeProps> {
  @override
  render() {
    return [
      (Dom.label()..key = 'label')('Edit mode:'),
      ...[for (var choice in EditModeChoice.values) this._button_for_choice(choice)],
    ];
  }

  ReactElement _button_for_choice(EditModeChoice mode) {
    return (Dom.button()
      ..onClick = ((_) => app.dispatch(actions.EditModeToggle(mode)))
      ..className = 'mode-button ' +
          (props.modes.contains(mode) ? 'edit-mode-button-selected' : 'edit-mode-button-unselected')
      ..key = mode.name)(mode.display_name());
  }
}
