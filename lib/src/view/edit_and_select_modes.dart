import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/view/redraw_counter_component_mixin.dart';

import '../app.dart';
import '../state/edit_mode.dart';
import '../state/app_state.dart';
import '../state/select_mode.dart';
import '../state/select_mode_state.dart';
import '../actions/actions.dart' as actions;
import 'edit_mode.dart';
import 'select_mode.dart';
import 'view.dart';

part 'edit_and_select_modes.over_react.g.dart';

UiFactory<EditAndSelectModesProps> ConnectedEditAndSelectModes = connect<AppState, EditAndSelectModesProps>(
  mapStateToProps: (state) {
    bool is_origami = (state.design?.is_origami == true);
    return EditAndSelectModes()
      ..edit_modes = state.ui_state.edit_modes
      ..select_mode_state = state.ui_state.select_mode_state
      ..is_origami = is_origami;
  },
  // Used for component test.
  forwardRef: true,
)(EditAndSelectModes);

UiFactory<EditAndSelectModesProps> EditAndSelectModes = _$EditAndSelectModes;

mixin EditAndSelectModesProps on UiProps {
  BuiltSet<EditModeChoice> edit_modes;
  SelectModeState select_mode_state;
  bool is_origami;
}

class EditAndSelectModesComponent extends UiComponent2<EditAndSelectModesProps> with RedrawCounterMixin {
  @override
  render() {
    return [
      (EditMode()
        ..modes = props.edit_modes
        ..key = 'edit-modes')(),
      (Dom.div()
        ..className = FIXED_HORIZONTAL_SEPARATOR
        ..key = 'modes-separator')(),
      (SelectMode()
        ..select_mode_state = props.select_mode_state
        ..is_origami = props.is_origami
        ..key = 'select-modes')(),
    ];
  }
}
