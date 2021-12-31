import 'package:js/js.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/view/react_color.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../state/strand.dart';

part 'strand_color_picker.over_react.g.dart';

typedef ActionCreator = actions.UndoableAction Function(Strand strand);

UiFactory<StrandColorPickerProps> ConnectedStrandColorPicker =
    connect<AppState, StrandColorPickerProps>(mapStateToProps: (state) {
  return StrandColorPicker()
    ..color = state.ui_state.strand_color_picker_strand?.color
    ..show = state.ui_state.strand_color_picker_strand != null
    ..strand = state.ui_state.strand_color_picker_strand;
})(StrandColorPicker);

UiFactory<StrandColorPickerProps> StrandColorPicker = _$StrandColorPicker;

mixin StrandColorPickerProps on UiProps {
  Color color;
  bool show;
  Strand strand;
}

@State()
mixin StrandColorPickerState on UiState {
  Color color;
}

class StrandColorPickerComponent
    extends UiStatefulComponent2<StrandColorPickerProps, StrandColorPickerState> {
  void handleOnChangeComplete(JSColor color, _) {
    state.color = HexColor(color.hex);
  }

  void handleOnCancel(e) {
    e.preventDefault();
    e.stopPropagation();
    app.dispatch(actions.StrandColorPickerHide());
    state.color = null;
  }

  void handleOnOK(e) {
    e.preventDefault();
    e.stopPropagation();
    app.dispatch(actions.StrandColorPickerHide());
    Color color = state.color;
    if (color != null && color != props.strand.color) {
      actions.Action action = batch_if_multiple_selected(color_set_strand_action_creator(color), props.strand,
          app.state.ui_state.selectables_store.selected_strands);
      app.dispatch(action);
    }
    state.color = null;
  }

  @override
  render() {
    if (props.show) {
      return (Dom.div()..className = 'dialog-form-container')(
        (Dom.div()..className = 'dialog-form')(
          (Dom.form()
            ..onSubmit = handleOnOK
            ..className = 'dialog-form-form')(
            SketchPicker({
              // props.color is used to set initial color (strand original color)
              // state.color is used to set color as user changes color on color picker
              'color': state.color ?? props.color,
              'onChangeComplete': handleOnChangeComplete,
            }),
            (Dom.span()
              ..className = 'dialog-buttons'
              ..key = 'buttons')(
              (Dom.input()
                ..type = 'submit'
                ..value = 'OK'
                ..className = 'dialog-button')(),
              (Dom.button()
                ..onClick = handleOnCancel
                ..className = 'dialog-button')('Cancel'),
            ),
          ),
        ),
      );
    } else {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Utility Methods (mostly same as in design_main_strand.dart)
  // --------------------------------------------------------------------------

  ActionCreator color_set_strand_action_creator(Color color) =>
      ((Strand strand) => actions.StrandColorSet(strand: strand, color: color));

  actions.UndoableAction batch_if_multiple_selected(
      ActionCreator action_creator, Strand strand, BuiltSet<Strand> selected_strands) {
    actions.Action action;
    if (selected_strands.isEmpty || selected_strands.length == 1 && selected_strands.first == strand) {
      // set for single strand if nothing is selected, or exactly this strand is selected
      action = action_creator(strand);
    } else {
      // if this strand is not selected, change it anyway along with all selected strands
      if (!selected_strands.contains(strand)) {
        selected_strands = selected_strands.rebuild((b) => b.add(strand));
      }
      action = actions.BatchAction([for (var strand in selected_strands) action_creator(strand)]);
    }
    return action;
  }
}

@JS()
@anonymous
class JSColor {
  external String get hex;
}
