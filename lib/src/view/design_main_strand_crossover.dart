import 'package:dialog/dialog.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/edit_mode.dart';

import 'package:scadnano/src/state/select_mode.dart';
import 'package:built_collection/built_collection.dart';
import '../state/crossover.dart';
import '../state/mouseover_data.dart';
import '../state/strand.dart';
import '../state/bound_substrand.dart';
import 'design_main_mouseover_rect_helix.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../constants.dart' as constants;


part 'design_main_strand_crossover.over_react.g.dart';

const SELECTED_CROSSOVER_COLOR = 'hotpink';

UiFactory<DesignMainStrandCrossoverProps> ConnectedDesignMainStrandCrossover =
    connect<AppState, DesignMainStrandCrossoverProps>(
  mapStateToPropsWithOwnProps: (state, props) {
    int prev_idx = props.crossover.prev_substrand_idx;
    int next_idx = props.crossover.next_substrand_idx;
    var prev_ss = props.strand.substrands[prev_idx];
    var next_ss = props.strand.substrands[next_idx];
    return DesignMainStrandCrossover()
      ..show_mouseover_rect = state.ui_state.show_mouseover_rect
      ..prev_substrand = prev_ss
      ..next_substrand = next_ss
      ..loopout_edit_mode_enabled = state.ui_state.edit_modes.contains(EditModeChoice.loopout)
      ..selected = state.ui_state.selectables_store.selected(props.crossover)
      ..selectable = state.ui_state.select_mode_state.modes.contains(SelectModeChoice.crossover);
  },
)(DesignMainStrandCrossover);

@Factory()
UiFactory<DesignMainStrandCrossoverProps> DesignMainStrandCrossover = _$DesignMainStrandCrossover;

@Props()
class _$DesignMainStrandCrossoverProps extends UiProps {
  Strand strand;
  Crossover crossover;
  BoundSubstrand prev_substrand;
  BoundSubstrand next_substrand;
  bool show_mouseover_rect;
  bool selected;
  bool selectable;
  bool loopout_edit_mode_enabled;
}

@State()
class _$DesignMainStrandCrossoverState extends UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the state just to tell if the mouse is hovering over a crossover
  bool mouse_hover;
}

@Component2()
class DesignMainStrandCrossoverComponent
    extends UiStatefulComponent2<DesignMainStrandCrossoverProps, DesignMainStrandCrossoverState> {
  @override
  Map get initialState => (newState()..mouse_hover = false);

  @override
  render() {
    Strand strand = props.strand;
    Crossover crossover = props.crossover;
    BoundSubstrand prev_substrand = props.prev_substrand;
    BoundSubstrand next_substrand = props.next_substrand;

    bool show_mouseover_rect = props.show_mouseover_rect;
    bool mouse_hover = state.mouse_hover;

    var classname_this_curve = 'crossover-curve';
    if (props.selected) {
      classname_this_curve += ' selected';
    }
    if (props.selectable) {
      classname_this_curve += ' selectable';
    }

    var path = crossover_path_description(prev_substrand, next_substrand);
    var color = strand.color.toRgbColor().toCssString();
    var id = crossover.id();

    if (show_mouseover_rect && mouse_hover) {
      update_mouseover_crossover();
    }

    return (Dom.path()
      ..d = path
      ..stroke = color
      ..className = classname_this_curve
      ..onMouseEnter = (ev) {
        setState(newState()..mouse_hover = true);
        if (show_mouseover_rect) {
          update_mouseover_crossover();
        }
      }
      ..onMouseLeave = ((_) {
        setState(newState()..mouse_hover = false);
        if (show_mouseover_rect) {
          mouse_leave_update_mouseover();
        }
      })
      ..onPointerDown = ((ev) {
        if (ev.nativeEvent.ctrlKey || ev.nativeEvent.metaKey || ev.nativeEvent.shiftKey) {
          crossover.handle_selection(ev);
        } else if (show_mouseover_rect) {
          handle_crossover_click();
        } else if (props.loopout_edit_mode_enabled) {
          convert_crossover_to_loopout();
        }
      })
      ..id = id
      ..key = id)();
  }

  handle_crossover_click() {
    BoundSubstrand prev_substrand = props.prev_substrand;
    BoundSubstrand next_substrand = props.next_substrand;
    List<actions.UndoableAction> rotation_actions = [];
    for (var ss in [prev_substrand, next_substrand]) {
      var other_ss = ss == prev_substrand ? next_substrand : prev_substrand;
      int anchor = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
      var rotation_action = actions.HelixRotationSetAtOther(ss.helix, other_ss.helix, ss.forward, anchor);
      rotation_actions.add(rotation_action);
    }
    var action = actions.BatchAction(rotation_actions);
    app.dispatch(action);
  }

  update_mouseover_crossover() {
    BoundSubstrand prev_substrand = props.prev_substrand;
    BoundSubstrand next_substrand = props.next_substrand;
    List<MouseoverParams> param_list = [];
    for (var ss in [prev_substrand, next_substrand]) {
      int helix_idx = ss == prev_substrand ? prev_substrand.helix : next_substrand.helix;
      int offset = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
      bool forward = ss.forward;
      param_list.add(MouseoverParams(helix_idx, offset, forward));
    }

    //FIXME: don't access global variable
    // should be able to use thunk middleware to give dna_design to this action
    app.dispatch(actions.MouseoverDataUpdate(app.state.dna_design, BuiltList<MouseoverParams>(param_list)));
  }

  convert_crossover_to_loopout() async {
    int length = null;
    String prompt_to_user = "Enter loopout length (positive integer):";
    do {
      var prompt_result = await prompt(prompt_to_user);
      if (prompt_result == null) {
        return;
      }
      var prompt_result_string = prompt_result.toString();
      length = int.tryParse(prompt_result_string);
      prompt_to_user =
          '"$prompt_result_string" is not a positive integer. Enter loopout length (positive integer):';
    } while (length == null || length <= 0);

    app.dispatch(actions.ConvertCrossoverToLoopout(props.crossover, length));
  }
}
