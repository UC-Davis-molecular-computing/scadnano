import 'dart:math';

import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/select_mode.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/reducers/app_ui_state_reducer.dart';

import '../model/crossover.dart';
import '../model/helix.dart';
import '../model/mouseover_data.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import 'design_main_mouseover_rect_helix.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../model/app_state.dart';

part 'design_main_strand_crossover.over_react.g.dart';

const SELECTED_CROSSOVER_COLOR = 'hotpink';

UiFactory<DesignMainStrandCrossoverProps> ConnectedDesignMainStrandCrossover =
    connect<AppState, DesignMainStrandCrossoverProps>(mapStateToPropsWithOwnProps: (state, props) {
  bool selected = state.ui_state.selectables_store.selected(props.crossover);
  return DesignMainStrandCrossover()
    ..show_mouseover_rect = state.ui_state.show_mouseover_rect
    ..selected = state.ui_state.selectables_store.selected(props.crossover)
    ..selectable = state.ui_state.select_mode_state.modes.contains(SelectModeChoice.crossover);
})(DesignMainStrandCrossover);

@Factory()
UiFactory<DesignMainStrandCrossoverProps> DesignMainStrandCrossover = _$DesignMainStrandCrossover;

@Props()
class _$DesignMainStrandCrossoverProps extends UiProps {
  Strand strand;
  Crossover crossover;
  bool show_mouseover_rect;
  bool selected;
  bool selectable;
}

@State()
class _$DesignMainStrandCrossoverState extends UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the model just to tell if the mouse is hovering over a crossover
  bool mouse_hover;
}

@Component2()
class DesignMainStrandCrossoverComponent
    extends UiStatefulComponent2<DesignMainStrandCrossoverProps, DesignMainStrandCrossoverState> {
  @override
  Map get initialState => (newState()..mouse_hover = false);

//  @override
//  bool shouldComponentUpdate(Map nextProps, Map nextState) {
//    Strand strand = nextProps['DesignMainStrandCrossoverProps.strand'];
//    Crossover crossover = nextProps['DesignMainStrandCrossoverProps.crossover'];
//    bool show_mouseover_rect = nextProps['DesignMainStrandCrossoverProps.show_mouseover_rect'];
//    bool selected = nextProps['DesignMainStrandCrossoverProps.selected'];
//    return !(props.strand == strand && props.crossover == crossover && props.show_mouseover_rect == show_mouseover_rect);
//  }

  @override
  render() {
    Strand strand = props.strand;
    Crossover crossover = props.crossover;
    bool show_mouseover_rect = props.show_mouseover_rect;
    int helix_idx_prev = crossover.prev_substrand.helix;
    int helix_idx_next = crossover.next_substrand.helix;
    bool mouse_hover = state.mouse_hover;

    BoundSubstrand prev_substrand = crossover.prev_substrand;
    BoundSubstrand next_substrand = crossover.next_substrand;

    handle_crossover_click() {
      List<actions.UndoableAction> rotation_actions = [];
      for (var ss in [prev_substrand, next_substrand]) {
        var other_ss = ss == prev_substrand ? next_substrand : prev_substrand;
        int anchor = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
        var rotation_action = actions.HelixRotationSetAtOther(ss.helix, other_ss.helix, ss.forward, anchor);
        rotation_actions.add(rotation_action);
      }
      var action = actions.BatchAction(rotation_actions);
      app.store.dispatch(action);
    }

    update_mouseover_crossover() {
      List<MouseoverParams> param_list = [];
      for (var ss in [prev_substrand, next_substrand]) {
        int helix_idx = ss == prev_substrand ? helix_idx_prev : helix_idx_next;
        int offset = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
        bool forward = ss.forward;
        param_list.add(MouseoverParams(helix_idx, offset, forward));
      }

      //FIXME: should be able to use thunk middleware to give dna_design to this action and not need a global variable
      app.store.dispatch(actions.MouseoverDataUpdate(app.state.dna_design, BuiltList<MouseoverParams>(param_list)));
    }

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

    //FIXME: check if mouse is *currently* over crossover, if not then bug to update
    // look up how to check current mouse position
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
        }
      })
      ..id = id
      ..key = id)();
  }
}
