import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/view/pure_component.dart';
import '../state/dialog.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

part 'design_dialog_form.over_react.g.dart';

UiFactory<DesignDialogFormProps> ConnectedDesignDialogForm = connect<AppState, DesignDialogFormProps>(
  mapStateToProps: (state) {
    return DesignDialogForm()..dialog = state.ui_state.dialog;
  },
)(DesignDialogForm);

UiFactory<DesignDialogFormProps> DesignDialogForm = _$DesignDialogForm;

mixin DesignDialogFormProps on UiProps {
  Dialog? dialog; // these are INITIAL values only
}

@State()
mixin DesignDialogFormState on UiState {
  BuiltList<DialogItem>? current_responses; // these are UPDATED as user changes form inputs
  DialogType? dialog_type;
  late BuiltMap<DialogType, BuiltList<DialogItem>> saved_responses;
}

class DesignDialogFormComponent extends UiStatefulComponent2<DesignDialogFormProps, DesignDialogFormState>
    with PureComponent {
  @override
  Map get initialState =>
      (newState()
        ..current_responses = null
        ..dialog_type = null
        ..saved_responses = new BuiltMap<DialogType, BuiltList<DialogItem>>());

  // This executes when the Dialog first pops up, and also whenever the user changes input fields,
  // which we respond to by setting a new React state, which re-renders the dialog view to show
  // their latest responses.
  @override
  Map getDerivedStateFromProps(Map nextPropsUntyped, Map prevStateUntyped) {
    // new_props has the current dialog type, which we use to look up the React state (in particular
    // the previous responses) the last time this type of Dialog was used.
    var new_props = typedPropsFactory(nextPropsUntyped);
    var prev_state = typedStateFactory(prevStateUntyped);
    if (new_props.dialog != null) {
      Dialog dialog = new_props.dialog!;
      // next if statement is true if the Dialog has just popped up, so user hasn't typed any
      // current responses yet, though some may be saved in TODO: saved where?
      if (prev_state.current_responses == null) {
        assert(dialog.process_saved_response != null);
        var dialog_type = dialog.type;
        return newState()
          ..current_responses =
              prev_state.saved_responses.containsKey(dialog_type) && dialog.use_saved_response
                  ? dialog.process_saved_response!(prev_state.saved_responses[dialog_type]!)
                  : dialog.items
          ..dialog_type = dialog.type
          ..saved_responses = prev_state.saved_responses;
      } else {
        return prevStateUntyped;
      }
    } else {
      // This runs once each time the Dialog is closed.
      //XXX: We cannot simply return null here. Must set responses to null in state, so the next time props
      // are set (when a new dialog is created), we have a fresh dialog. Otherwise the old state persists
      // and the dialog won't be refreshed for the new use.
      if (prev_state.current_responses != null) {
        assert(prev_state.dialog_type != null);
        // This happens if the user closes the Dialog after entering some input, which is stored in
        // current_responses.
        // We save those responses for next time this type of Dialog opens.
        return newState()
          ..current_responses = null
          ..dialog_type = null
          ..saved_responses = prev_state.saved_responses.rebuild((old_responses) {
            old_responses[prev_state.dialog_type!] = prev_state.current_responses!;
            return old_responses;
          });
      } else {
        // We're not sure when this executes, but it apparently happens at some point in the React lifecycle
        // (we know this from testing) so it has to be handled.
        return prevStateUntyped;
      }
    }
  }

  @override
  render() {
    Dialog? dialog = props.dialog;
    BuiltList<DialogItem>? current_responses = state.current_responses;
    if (dialog == null || current_responses == null) {
      return null;
    }

    int component_idx = 0;
    List<ReactElement> components = [];
    for (var item in current_responses) {
      bool disabled = false;

      // disable if radio button in disable_when_any_radio_button_selected to which this has forbidden value
      if (dialog.disable_when_any_radio_button_selected.containsKey(component_idx)) {
        BuiltMap<int, BuiltList<String>> radio_idx_maps =
            dialog.disable_when_any_radio_button_selected[component_idx]!;
        for (int radio_idx in radio_idx_maps.keys) {
          BuiltList<String> forbidden_values = radio_idx_maps[radio_idx]!;
          DialogRadio radio = current_responses[radio_idx] as DialogRadio;
          String selected_value = radio.options[radio.selected_idx];
          if (forbidden_values.contains(selected_value)) {
            disabled = true;
            break;
          }
        }
      }

      // disable if checkbox in disable_when_any_checkboxes_off to which this maps is false
      if (dialog.disable_when_any_checkboxes_off.containsKey(component_idx)) {
        BuiltList<int> check_idxs = dialog.disable_when_any_checkboxes_off[component_idx]!;
        for (int check_idx in check_idxs) {
          DialogCheckbox check = current_responses[check_idx] as DialogCheckbox;
          if (check.value == false) {
            disabled = true;
            break;
          }
        }
      }

      // disable if checkbox in disable_when_any_checkboxes_on to which this maps is true
      if (dialog.disable_when_any_checkboxes_on.containsKey(component_idx)) {
        BuiltList<int> check_idxs = dialog.disable_when_any_checkboxes_on[component_idx]!;
        for (int check_idx in check_idxs) {
          DialogCheckbox check = current_responses[check_idx] as DialogCheckbox;
          if (check.value == true) {
            disabled = true;
            break;
          }
        }
      }

      if (dialog.disable.contains(component_idx)) {
        disabled = true;
      }

      var component = (Dom.div()
        ..className = 'dialog-form-item'
        ..key = item.label)(dialog_for(item, component_idx++, disabled));

      components.add(component);
    }

    return (Dom.div()
      ..className = 'dialog-form'
      ..id = 'dialog-form')(
      (Dom.form()
        ..onSubmit = submit_form
        ..id = 'dialog-form-form'
        ..className = 'dialog-form-form')([
        (Dom.p()
          ..className = 'dialog-form-title'
          ..key = 'dialog-form-title')(dialog.title),
        ...components,
        (Dom.span()
          ..className = 'dialog-buttons'
          ..key = 'buttons')(
          (Dom.input()
            ..type = 'submit'
            ..value = 'OK'
            ..className = 'dialog-button')(),
          (Dom.button()
            ..onClick = (e) {
              e.preventDefault();
              e.stopPropagation();
              cancel();
            }
            ..className = 'dialog-button')('Cancel'),
        ),
      ]),
    );
  }

  cancel() {
    app.dispatch(actions.DialogHide());
    if (props.dialog != null && props.dialog!.on_submit != null) {
      props.dialog!.on_submit!(null);
    }
  }

  ReactElement? dialog_for(DialogItem item, int dialog_item_idx, bool disabled) {
    if (item is DialogCheckbox) {
      return (Dom.label()..title = item.tooltip)(
        (Dom.input()
          ..type = 'checkbox'
          ..disabled = disabled
          ..checked = item.value
          ..onChange = (SyntheticFormEvent e) {
            var current_responses = state.current_responses!;
            var new_responses = current_responses.toBuilder();
            bool new_checked = e.target.checked;
            DialogCheckbox response = current_responses[dialog_item_idx] as DialogCheckbox;
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_checked);

            // see if this is mutually exclusive with any checkbox that's checked; if so, uncheck it
            for (var mutually_exclusive_group in props.dialog!.mutually_exclusive_checkbox_groups) {
              if (mutually_exclusive_group.contains(dialog_item_idx)) {
                for (int other_idx in mutually_exclusive_group) {
                  if (other_idx != dialog_item_idx) {
                    DialogCheckbox other_response = current_responses[other_idx] as DialogCheckbox;
                    if (other_response.value == true) {
                      new_responses[other_idx] = other_response.rebuild((b) => b.value = false);
                    }
                  }
                }
              }
            }
            setState(newState()..current_responses = new_responses.build());
          })(),
        item.label,
      );
    } else if (item is DialogText) {
      var current_responses = state.current_responses!;
      return (Dom.label()..title = item.tooltip)(
        '${item.label}: ',
        (Dom.input()
          ..type = 'text'
          ..disabled = disabled
          ..value = item.value
          ..size = item.size
          //          ..width = '${item.size}ch'
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = current_responses.toBuilder();
            String new_value = e.target.value;
            DialogText response = current_responses[dialog_item_idx] as DialogText;
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..current_responses = new_responses.build());
          })(),
      );
    } else if (item is DialogTextArea) {
      var current_responses = state.current_responses!;
      return (Dom.label()..title = item.tooltip)(
        '${item.label}: ',
        (Dom.textarea()
          ..form = 'dialog-form-form'
          ..disabled = disabled
          ..defaultValue = item.value
          ..rows = item.rows
          ..cols = item.cols
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = current_responses.toBuilder();
            String new_value = e.target.value;
            DialogTextArea response = current_responses[dialog_item_idx] as DialogTextArea;
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..current_responses = new_responses.build());
          })(),
      );
    } else if (item is DialogInteger) {
      var current_responses = state.current_responses!;
      return (Dom.label()..title = item.tooltip)(
        '${item.label}: ',
        (Dom.input()
          ..type = 'number'
          ..disabled = disabled
          ..pattern =
              r'-?\d+' // allow to type integers
          ..value = item.value
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = current_responses.toBuilder();
            int? new_value = int.tryParse(e.target.value);
            if (new_value == null) return;
            DialogInteger response = current_responses[dialog_item_idx] as DialogInteger;
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..current_responses = new_responses.build());
          })(),
      );
    } else if (item is DialogFloat) {
      var current_responses = state.current_responses!;
      return (Dom.label()..title = item.tooltip)(
        '${item.label}: ',
        (Dom.input()
          ..type = 'number'
          ..disabled = disabled
          ..pattern =
              r'[+-]?(\d*[.])?\d+' // allow to type floating numbers
          ..value = item.value
          ..step = 'any'
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = current_responses.toBuilder();
            double? new_value = double.tryParse(e.target.value);
            if (new_value == null) return;
            DialogFloat response = current_responses[dialog_item_idx] as DialogFloat;
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..current_responses = new_responses.build());
          })(),
      );
    } else if (item is DialogRadio && item.radio) {
      var current_responses = state.current_responses!;
      // can be either radio buttons or drop-down select, depending on value of DialogRadio.radio
      int radio_idx = 0;
      List<ReactElement> components = [];
      for (int i = 0; i < item.options.length; i++) {
        var option = item.options[i];
        var option_tooltip = item.option_tooltips[i];
        components.add((Dom.br()..key = 'br-$radio_idx')());
        components.add(
          (Dom.input()
            ..type = 'radio'
            ..id = 'radio-${item.label}-${radio_idx}'
            ..disabled = disabled
            ..name = item.label
            ..checked = (item.selected_idx == radio_idx)
            ..value = option
            ..onChange = (SyntheticFormEvent e) {
              var selected_title = e.target.value;
              int selected_radio_idx = item.options.indexOf(selected_title);
              DialogRadio response = current_responses[dialog_item_idx] as DialogRadio;
              var new_responses = current_responses.toBuilder();
              new_responses[dialog_item_idx] = response.rebuild((b) => b.selected_idx = selected_radio_idx);
              setState(newState()..current_responses = new_responses.build());
            }
            ..key = '$radio_idx')(),
        );
        components.add(
          (Dom.label()
            ..key = 'label-$radio_idx'
            ..title = option_tooltip)(option),
        );
        radio_idx++;
      }
      // return (Dom.div()..className = 'radio-left')('${item.label}: ', components);
      return (Dom.div()
        ..className = 'radio-left')(((Dom.label()..title = item.tooltip)('${item.label}:')), components);
    } else if (item is DialogRadio && !item.radio) {
      var current_responses = state.current_responses!;
      int radio_idx = 0;
      List<ReactElement> components = [];
      for (int i = 0; i < item.options.length; i++) {
        var option = item.options[i];
        var option_tooltip = item.option_tooltips[i];
        components.add(
          (Dom.option()
            ..id = 'radio-${radio_idx}'
            ..disabled = disabled
            ..title = option_tooltip
            ..value = option
            ..onChange = (SyntheticFormEvent e) {
              var selected_title = e.target.value;
              int selected_radio_idx = item.options.indexOf(selected_title);
              DialogRadio response = current_responses[dialog_item_idx] as DialogRadio;
              var new_responses = current_responses.toBuilder();
              new_responses[dialog_item_idx] = response.rebuild((b) => b.selected_idx = selected_radio_idx);
              setState(newState()..current_responses = new_responses.build());
            }
            ..key = '$radio_idx')(option),
        );
        radio_idx++;
      }

      return (Dom.div())(
        ((Dom.label()..title = item.tooltip)('${item.label}:')),
        (Dom.select()
          ..className = 'radio-left'
          ..disabled = disabled
          ..onChange = (SyntheticFormEvent e) {
            var selected_title = e.target.value;
            int selected_radio_idx = item.options.indexOf(selected_title);
            DialogRadio response = current_responses[dialog_item_idx] as DialogRadio;
            var new_responses = current_responses.toBuilder();
            new_responses[dialog_item_idx] = response.rebuild((b) => b.selected_idx = selected_radio_idx);
            setState(newState()..current_responses = new_responses.build());
          })('${item.label}: ', components),
      );
    } else if (item is DialogLink) {
      return (Dom.a()
        ..href = item.link
        ..target = '_blank'
        ..rel = 'noopener noreferrer')(item.label);
    } else if (item is DialogLabel) {
      return (Dom.span()..title = item.tooltip)(item.label);
    }

    return null;
  }

  submit_form(SyntheticFormEvent event) {
    event.preventDefault();
    event.stopPropagation();
    app.dispatch(actions.DialogHide());
    if (props.dialog != null && props.dialog!.on_submit != null && state.current_responses != null) {
      props.dialog!.on_submit!(state.current_responses!.toList());
    }
  }
}
