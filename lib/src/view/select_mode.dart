import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../state/select_mode.dart';
import '../state/select_mode_state.dart';

part 'select_mode.over_react.g.dart';

UiFactory<SelectModeProps> ConnectedSelectMode = connect<AppState, SelectModeProps>(
  mapStateToProps: (state) {
    bool is_origami = false;
    if (state.dna_design?.is_origami == true) {
      is_origami = true;
    }
    return SelectMode()
      ..select_mode_state = state.ui_state.select_mode_state
      ..is_origami = is_origami;
  },
)(SelectMode);

@Factory()
UiFactory<SelectModeProps> SelectMode = _$SelectMode;

@Props()
class _$SelectModeProps extends UiProps with ConnectPropsMixin {
  SelectModeState select_mode_state;
  bool is_origami;
}

@Component2()
class SelectModeComponent extends UiComponent2<SelectModeProps> {
  @override
  render() {
    var modes = props.is_origami ? SelectModeChoice.all_choices : SelectModeChoice.non_origami_choices;
    return [
      (Dom.label()..key = 'label')('Select:'),
      ...[
        for (var mode in modes)
          (Dom.button()
            ..onClick = ((_) => props.dispatch(actions.SelectModeToggle(mode)))
            ..className = 'mode-button ' +
                (props.select_mode_state.modes.contains(mode)
                    ? 'select-mode-button-selected'
                    : 'select-mode-button-unselected')
            ..key = mode.display_name())(mode.display_name())
      ],
    ];
  }
}
