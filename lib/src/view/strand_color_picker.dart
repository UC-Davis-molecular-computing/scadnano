// @dart=2.9
import 'package:js/js.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/state/substrand.dart';
import 'package:scadnano/src/view/react_color.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../state/strand.dart';

part 'strand_color_picker.over_react.g.dart';

typedef StrandActionCreator = actions.UndoableAction Function(Strand strand);
typedef SubstrandActionCreator = actions.UndoableAction Function(Strand strand, Substrand substrand);

UiFactory<StrandOrSubstrandColorPickerProps> ConnectedStrandOrSubstrandColorPicker =
    connect<AppState, StrandOrSubstrandColorPickerProps>(mapStateToProps: (state) {
  var color = state.ui_state.color_picker_strand?.color;
  if (state.ui_state.color_picker_substrand?.color != null) {
    color = state.ui_state.color_picker_substrand.color;
  }
  return StrandOrSubstrandColorPicker()
    ..color = color
    ..show = state.ui_state.color_picker_strand != null
    ..strand = state.ui_state.color_picker_strand
    ..substrand = state.ui_state.color_picker_substrand;
})(StrandOrSubstrandColorPicker);

UiFactory<StrandOrSubstrandColorPickerProps> StrandOrSubstrandColorPicker = _$StrandOrSubstrandColorPicker;

mixin StrandOrSubstrandColorPickerProps on UiProps {
  Color color;
  bool show;
  Strand strand;
  Substrand substrand; // if null then set for the whole strand
}

@State()
mixin StrandOrSubstrandColorPickerState on UiState {
  Color color;
}

class StrandOrSubstrandColorPickerComponent
    extends UiStatefulComponent2<StrandOrSubstrandColorPickerProps, StrandOrSubstrandColorPickerState> {
  void handleOnChangeComplete(JSColor color, _) {
    state.color = HexColor(color.hex);
  }

  void handleOnCancel(e) {
    e.preventDefault();
    e.stopPropagation();
    app.dispatch(actions.StrandOrSubstrandColorPickerHide());
    state.color = null;
  }

  void handleOnOK(e) {
    e.preventDefault();
    e.stopPropagation();
    app.dispatch(actions.StrandOrSubstrandColorPickerHide());
    Color color = state.color;
    if (color != null) {
      actions.Action action = null;
      if (props.substrand == null && color != props.strand.color) {
        // if substrand is null, we're setting this for a strand or many selected strands
        action = batch_if_multiple_selected_strands(color_set_strand_action_creator(color), props.strand,
            app.state.ui_state.selectables_store.selected_strands);
      } else if (props.substrand != null && color != props.substrand.color) {
        // if substrand is non-null, we're setting this for a substrand or many selected substrands
        var store = app.state.ui_state.selectables_store;
        List<Substrand> selected_substrands = [];
        selected_substrands.addAll(store.selected_domains);
        selected_substrands.addAll(store.selected_extensions);
        selected_substrands.addAll(store.selected_loopouts);
        action = batch_if_multiple_selected_substrands(
            color_set_substrand_action_creator(color), props.strand, props.substrand, selected_substrands);
      }
      if (action != null) {
        app.dispatch(action);
      }
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

  StrandActionCreator color_set_strand_action_creator(Color color) =>
      ((Strand strand) => actions.StrandOrSubstrandColorSet(strand: strand, color: color));

  SubstrandActionCreator color_set_substrand_action_creator(Color color) =>
      ((Strand strand, Substrand substrand) =>
          actions.StrandOrSubstrandColorSet(strand: strand, substrand: substrand, color: color));

  actions.UndoableAction batch_if_multiple_selected_strands(
      StrandActionCreator action_creator, Strand strand, BuiltSet<Strand> selected_strands) {
    actions.Action action;
    if (selected_strands.isEmpty || selected_strands.length == 1 && selected_strands.first == strand) {
      // set for single strand if nothing is selected, or exactly this strand is selected
      action = action_creator(strand);
    } else {
      // if this strand is not selected, change it anyway along with all selected strands
      if (!selected_strands.contains(strand)) {
        selected_strands = selected_strands.rebuild((b) => b.add(strand));
      }
      action = actions.BatchAction(
          [for (var strand in selected_strands) action_creator(strand)], "set strands color");
    }
    return action;
  }

  actions.UndoableAction batch_if_multiple_selected_substrands(SubstrandActionCreator action_creator,
      Strand strand, Substrand substrand, List<Substrand> selected_substrands) {
    actions.Action action;
    if (selected_substrands.isEmpty ||
        selected_substrands.length == 1 && selected_substrands.first == substrand) {
      // set for single substrand if nothing is selected, or exactly this strand is selected
      action = action_creator(strand, substrand);
    } else {
      // if this substrand is not selected, change it anyway along with all selected substrands
      if (!selected_substrands.contains(substrand)) {
        selected_substrands.add(substrand);
      }
      var design = app.state.design;
      List<actions.UndoableAction> indv_actions = [];
      for (var substrand in selected_substrands) {
        var strand_of_substrand = design.strands_by_id[substrand.strand_id];
        var indv_action = action_creator(strand_of_substrand, substrand);
        indv_actions.add(indv_action);
      }
      action = actions.BatchAction(indv_actions, "set substrands color");
    }
    return action;
  }
}

@JS()
@anonymous
class JSColor {
  external String get hex;
}
