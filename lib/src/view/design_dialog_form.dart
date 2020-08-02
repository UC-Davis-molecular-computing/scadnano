import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
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
  Dialog dialog; // these are INITIAL values only
}

@State()
mixin DesignDialogFormState on UiState {
  BuiltList<DialogItem> responses; // these are UPDATED as user changes form inputs
}

class DesignDialogFormComponent extends UiStatefulComponent2<DesignDialogFormProps, DesignDialogFormState> {
  @override
  Map getDerivedStateFromProps(Map nextPropsUntyped, Map prevStateUntyped) {
    var new_props = typedPropsFactory(nextPropsUntyped);
    if (new_props.dialog != null) {
      var prev_state = typedStateFactory(prevStateUntyped);
      if (prev_state.responses == null) {
        return newState()..responses = new_props.dialog.items;
      } else {
        return prevStateUntyped;
      }
    } else {
      //XXX: We cannot simply return null here. Must set responses to null in state, so the next time props
      // are set (when a new dialog is created), we have a fresh dialog. Otherwise the old state persists
      // and the dialog won't be refreshed for the new use.
      return newState()..responses = null;
    }
  }

  @override
  render() {
    if (props.dialog == null || state.responses == null) {
      return null;
    }

    int component_idx = 0;
    List<ReactElement> components = [];
    for (var item in state.responses) {
      bool disabled = false;

      // disable if checkbox in disable_when_off to which this maps is false
      if (props.dialog.disable_when_off.containsKey(component_idx)) {
        BuiltList<int> check_idxs = props.dialog.disable_when_off[component_idx];
        for (int check_idx in check_idxs) {
          DialogCheckbox check = state.responses[check_idx];
          if (check.value == false) {
            disabled = true;
          }
        }
      }

      // disable if checkbox in disable_when_on to which this maps is true
      if (props.dialog.disable_when_on.containsKey(component_idx)) {
        BuiltList<int> check_idxs = props.dialog.disable_when_on[component_idx];
        for (int check_idx in check_idxs) {
          DialogCheckbox check = state.responses[check_idx];
          if (check.value == true) {
            disabled = true;
          }
        }
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
          ..key = 'dialog-form-title')(props.dialog.title),
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
    props.dialog.on_submit(null);
  }

  ReactElement dialog_for(DialogItem item, int dialog_item_idx, bool disabled) {
    if (item is DialogCheckbox) {
      return Dom.label()(
        (Dom.input()
          ..type = 'checkbox'
          ..disabled = disabled
          ..checked = item.value
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            bool new_checked = e.target.checked;
            DialogCheckbox response = state.responses[dialog_item_idx];
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_checked);

            // see if this is mutually exclusive with any checkbox that's checked; if so, uncheck it
            for (var mutually_exclusive_group in props.dialog.mutually_exclusive_checkbox_groups) {
              if (mutually_exclusive_group.contains(dialog_item_idx)) {
                for (int other_idx in mutually_exclusive_group) {
                  if (other_idx != dialog_item_idx) {
                    DialogCheckbox other_response = state.responses[other_idx];
                    if (other_response.value == true) {
                      new_responses[other_idx] = other_response.rebuild((b) => b.value = false);
                    }
                  }
                }
              }
            }
            setState(newState()..responses = new_responses.build());
          })(),
        item.label,
      );
    } else if (item is DialogText) {
      return Dom.label()(
        '${item.label}: ',
        (Dom.input()
          ..type = 'text'
          ..disabled = disabled
          ..value = item.value
          ..size = item.size
//          ..width = '${item.size}ch'
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            String new_value = e.target.value;
            DialogText response = state.responses[dialog_item_idx];
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..responses = new_responses.build());
          })(),
      );
    } else if (item is DialogTextArea) {
      return Dom.label()(
        '${item.label}: ',
        (Dom.textarea()
          ..form = 'dialog-form-form'
          ..disabled = disabled
          ..value = item.value
          ..rows = item.rows
          ..cols = item.cols
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            String new_value = e.target.value;
            DialogTextArea response = state.responses[dialog_item_idx];
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..responses = new_responses.build());
          })(),
      );
    } else if (item is DialogNumber) {
      return Dom.label()(
        '${item.label}: ',
        (Dom.input()
          ..type = 'number'
          ..disabled = disabled
          ..pattern = r'-?\d+' // allow to type integers
          ..value = item.value
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            num new_value = int.tryParse(e.target.value);
            if (new_value == null) return;
            DialogNumber response = state.responses[dialog_item_idx];
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..responses = new_responses.build());
          })(),
      );
    } else if (item is DialogFloatingNumber) {
      return Dom.label()(
        '${item.label}: ',
        (Dom.input()
          ..type = 'number'
          ..disabled = disabled
          ..pattern = r'[+-]?(\d*[.])?\d+' // allow to type floating numbers
          ..value = item.value
          ..step = 'any'
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            num new_value = double.tryParse(e.target.value);
            if (new_value == null) return;
            DialogFloatingNumber response = state.responses[dialog_item_idx];
            new_responses[dialog_item_idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..responses = new_responses.build());
          })(),
      );
    } else if (item is DialogSelect) {
      throw UnsupportedError('not yet implemented');
    } else if (item is DialogRadio) {
      int radio_idx = 0;
      List<ReactElement> components = [];
      for (var option in item.options) {
        components.add((Dom.br()..key = 'br-$radio_idx')());
        components.add((Dom.input()
          ..type = 'radio'
          ..id = 'radio-example-filename-${radio_idx}'
          ..disabled = disabled
          ..name = item.label
          ..checked = (item.selected_idx == radio_idx)
          ..value = option
          ..onChange = (SyntheticFormEvent e) {
            var selected_title = e.target.value;
            int selected_radio_idx = item.options.indexOf(selected_title);
            DialogRadio response = state.responses[dialog_item_idx];
            var new_responses = state.responses.toBuilder();
            new_responses[dialog_item_idx] = response.rebuild((b) => b.selected_idx = selected_radio_idx);
            setState(newState()..responses = new_responses.build());
          }
          ..key = '$radio_idx')());
        components.add((Dom.label()..key = 'label-$radio_idx')(option));
        radio_idx++;
      }
      return (Dom.div()..className = 'radio-left')('${item.label}: ', components);
    }
    return null;
  }

  submit_form(SyntheticFormEvent event) {
    event.preventDefault();
    event.stopPropagation();
    app.dispatch(actions.DialogHide());
    props.dialog.on_submit(state.responses.toList());
  }
}
