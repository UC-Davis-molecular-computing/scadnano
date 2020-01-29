import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/dialog.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

part 'design_dialog_form.over_react.g.dart';

UiFactory<DesignDialogFormProps> ConnectedDesignDialogForm = connect<AppState, DesignDialogFormProps>(
  mapStateToProps: (state) {
    return DesignDialogForm()..dialog = state.ui_state.dialog;
  },
)(DesignDialogForm);

@Factory()
UiFactory<DesignDialogFormProps> DesignDialogForm = _$DesignDialogForm;

@Props()
class _$DesignDialogFormProps extends UiProps {
  Dialog dialog; // these are INITIAL values only
}

@State()
class _$DesignDialogFormState extends UiState {
  BuiltList<DialogItem> responses; // these are UPDATED as user changes form inputs
}

@Component2()
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
        int check_idx = props.dialog.disable_when_off[component_idx];
        DialogCheckbox check = state.responses[check_idx];
        if (check.value == false) {
          disabled = true;
        }
      }

      // disable if checkbox in disable_when_on to which this maps is true
      if (props.dialog.disable_when_on.containsKey(component_idx)) {
        int check_idx = props.dialog.disable_when_on[component_idx];
        DialogCheckbox check = state.responses[check_idx];
        if (check.value == true) {
          disabled = true;
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

  ReactElement dialog_for(DialogItem item, int idx, bool disabled) {
    if (item is DialogCheckbox) {
      return Dom.label()(
        (Dom.input()
          ..type = 'checkbox'
          ..disabled = disabled
          ..checked = item.value
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            bool new_checked = e.target.checked;
            DialogCheckbox response = state.responses[idx];
            new_responses[idx] = response.rebuild((b) => b.value = new_checked);
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
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            String new_value = e.target.value;
            DialogText response = state.responses[idx];
            new_responses[idx] = response.rebuild((b) => b.value = new_value);
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
            DialogTextArea response = state.responses[idx];
            new_responses[idx] = response.rebuild((b) => b.value = new_value);
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
            DialogNumber response = state.responses[idx];
            new_responses[idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..responses = new_responses.build());
          })(),
      );
    } else if (item is DialogFloatingNumber) {
      return Dom.label()(
        '${item.label}: ',
        (Dom.input()
          ..type = 'number'
          ..disabled = disabled
          ..pattern = r'[+-]?([0-9]*[.])?[0-9]+' // allow to type floating numbers
          ..value = item.value
          ..step = 'any'
          ..onChange = (SyntheticFormEvent e) {
            var new_responses = state.responses.toBuilder();
            num new_value = double.tryParse(e.target.value);
            if (new_value == null) return;
            DialogFloatingNumber response = state.responses[idx];
            new_responses[idx] = response.rebuild((b) => b.value = new_value);
            setState(newState()..responses = new_responses.build());
          })(),
      );
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
