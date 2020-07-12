import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/view/redraw_counter_component_mixin.dart';

import '../app.dart';
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
  // Used for component test.
  forwardRef: true,
)(SelectMode);

UiFactory<SelectModeProps> SelectMode = _$SelectMode;

mixin SelectModePropsMixin on UiProps {
  SelectModeState select_mode_state;
  bool is_origami;
}

class SelectModeProps = UiProps with SelectModePropsMixin, ConnectPropsMixin;

class SelectModeComponent extends UiComponent2<SelectModeProps> with RedrawCounterMixin {
  @override
  get consumedProps => propsMeta.forMixins({SelectModePropsMixin});

  @override
  render() {
    var ends_modes = props.is_origami ? SelectModeChoice.ends_on_origami : SelectModeChoice.ends;
    var first_button = (Dom.button()
      ..onClick = ((_) => props.dispatch(actions.SelectModesSet(ends_modes.toBuiltList())))
      ..className = 'mode-button ' +
          (props.select_mode_state.modes.containsAll(SelectModeChoice.ends)
              ? 'select-mode-button-selected'
              : 'select-mode-button-unselected')
      ..addTestId('scadnano.SelectModeComponent.button.all_ends')
      ..key = 'all-ends')('all ends');

    var modes = props.is_origami ? SelectModeChoice.all_choices : SelectModeChoice.non_origami_choices;
    var elts = [
      (Dom.label()..key = 'label')('Select:'),
      first_button,
      ...[
        for (var mode in modes)
          (Dom.button()
            ..onClick = ((_) => app.dispatch(actions.SelectModeToggle(mode)))
            ..className = 'mode-button ' +
                (props.select_mode_state.modes.contains(mode)
                    ? 'select-mode-button-selected'
                    : 'select-mode-button-unselected')
            ..addTestId('scadnano.SelectModeComponent.button.${mode.name}')
            ..key = mode.display_name())(mode.display_name())
      ],
    ];
    return (Dom.div()..id = 'select-mode')(elts);
  }
}
