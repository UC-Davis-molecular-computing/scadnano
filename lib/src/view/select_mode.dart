import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import '../model/app_state.dart';
import '../actions/actions.dart' as actions;
import '../model/select_mode.dart';
import '../model/select_mode_state.dart';

part 'select_mode.over_react.g.dart';

//TODO: check if design is a OrigamiDNADesign; if not, don't display scaffold/staple select modes

UiFactory<SelectModeProps> ConnectedSelectMode = connect<AppState, SelectModeProps>(
  mapStateToProps: (state) => (SelectMode()..select_mode_state = state.ui_state.select_mode_state),
//  mapDispatchToProps: (dispatch) => (SelectMode()
//    ..toggle_select_mode = (SelectModeChoice mode) {
//      dispatch(Actions.toggle_select_mode());
//    }),
)(SelectMode);

@Factory()
UiFactory<SelectModeProps> SelectMode = _$SelectMode;

@Props()
class _$SelectModeProps extends UiProps with ConnectPropsMixin {
  SelectModeState select_mode_state;
  void Function(SelectModeChoice mode) toggle_select_mode;
}

@Component2()
class SelectModeComponent extends UiComponent2<SelectModeProps> {
//  @override
//  Map getDefaultProps() => (newProps());

  @override
  render() {
    return (Dom.div())([
      (Dom.label()..key = 'label')('Select:'),
      ..._choice_buttons(),
    ]);
  }

  _choice_buttons() => [for (var choice in SelectModeChoice.all_choices) this._choice_button(choice)];

  ReactElement _choice_button(SelectModeChoice mode) {
    SelectModeState select_mode_state = this.props.select_mode_state;
    return (Dom.button()
//      ..onClick = ((_) => Actions.toggle_select_mode(mode))
//      ..onClick = ((_) => props.dispatch(Actions.toggle_select_mode(mode)))
//      ..onClick = ((_) => props.toggle_select_mode(mode))
//      ..onClick = ((_) {
//        print(props);
//        props.toggle_select_mode(mode);
//      })
//      ..onClick = ((_) => props.dispatch(actions.ToggleSelectMode(mode)))
      ..onClick = ((_) => props.dispatch(actions.ToggleSelectMode(mode)))
//      ..onClick = ((_) {
//        print(props);
//        props.dispatch(ActionToggleSelectMode(mode));
//      })
      ..className = 'mode-button ' +
          (select_mode_state.modes.contains(mode)
              ? 'select-mode-button-selected'
              : 'select-mode-button-unselected')
      ..key = mode.display_name())(mode.display_name());
  }
}
