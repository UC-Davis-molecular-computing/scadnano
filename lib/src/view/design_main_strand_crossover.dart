import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/state/edit_mode.dart';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/view/edit_mode_queryable.dart';
import 'package:scadnano/src/view/pure_component.dart';
import '../state/crossover.dart';
import '../state/mouseover_data.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'design_main_mouseover_rect_helix.dart';
import 'design_main_strand_loopout.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_strand_crossover.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandCrossoverProps> DesignMainStrandCrossover = _$DesignMainStrandCrossover;

@Props()
mixin DesignMainStrandCrossoverPropsMixin on UiProps {
  Crossover crossover;
  Strand strand;

  Domain prev_domain;
  Domain next_domain;
  bool selected;
  BuiltSet<EditModeChoice> edit_modes;
  BuiltMap<int, Helix> helices;
}

class DesignMainStrandCrossoverProps = UiProps with DesignMainStrandCrossoverPropsMixin, EditModePropsMixin;

@State()
mixin DesignMainStrandCrossoverState on UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the state just to tell if the mouse is hovering over a crossover
  bool mouse_hover;
}

class DesignMainStrandCrossoverComponent
    extends UiStatefulComponent2<DesignMainStrandCrossoverProps, DesignMainStrandCrossoverState>
    with PureComponent, EditModeQueryable<DesignMainStrandCrossoverProps> {
  @override
  Map get initialState => (newState()..mouse_hover = false);

  @override
  render() {
    Strand strand = props.strand;
    Crossover crossover = props.crossover;
    Domain prev_substrand = props.prev_domain;
    Domain next_substrand = props.next_domain;

    bool show_mouseover_rect = backbone_mode;
    bool mouse_hover = state.mouse_hover;

    var classname_this_curve = constants.css_selector_crossover;
    if (props.selected) {
      classname_this_curve += ' ' + constants.css_selector_selected;
    }

    var path = crossover_path_description(prev_substrand, next_substrand, props.helices);
    var color = strand.color.toHexColor().toCssString();
    var id = crossover.id();

    if (show_mouseover_rect && mouse_hover) {
      update_mouseover_crossover();
    }

    String tooltip = 'PUT TOOLTIP TEXT HERE (if we think of something)';

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
            if (select_mode) {
              props.crossover.handle_selection_mouse_down(ev.nativeEvent);
            }
          })
          ..onPointerUp = ((ev) {
            if (select_mode) {
              props.crossover.handle_selection_mouse_up(ev.nativeEvent);
            }
          })
          ..id = id
          ..key = id)(
//        Dom.svgTitle()(tooltip)
        );
  }

  @override
  componentDidMount() {
    var element = querySelector('#${props.crossover.id()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.crossover.id()}');
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(items: context_menu_strand(props.strand).build(), position: event.page)));
    }
  }

  List<ContextMenuItem> context_menu_strand(Strand strand) => [
        ContextMenuItem(
          title: 'convert to loopout',
          on_click: convert_crossover_to_loopout,
        ),
        ContextMenuItem(
          title: 'unstrain backbone here',
          on_click: handle_crossover_click,
        ),
      ];

  handle_crossover_click() {
    Domain prev_domain = props.prev_domain;
    Domain next_domain = props.next_domain;
    List<actions.UndoableAction> roll_actions = [];
    for (var dom in [prev_domain, next_domain]) {
      var other_ss = dom == prev_domain ? next_domain : prev_domain;
      int anchor = dom == prev_domain ? dom.offset_3p : dom.offset_5p;
      var roll_action = actions.HelixRollSetAtOther(dom.helix, other_ss.helix, dom.forward, anchor);
      roll_actions.add(roll_action);
    }
    var action = actions.BatchAction(roll_actions);
    app.dispatch(action);
  }

  update_mouseover_crossover() {
    Domain prev_domain = props.prev_domain;
    Domain next_domain = props.next_domain;
    List<MouseoverParams> param_list = [];
    for (var dom in [prev_domain, next_domain]) {
      int helix_idx = dom == prev_domain ? prev_domain.helix : next_domain.helix;
      int offset = dom == prev_domain ? dom.offset_3p : dom.offset_5p;
      bool forward = dom.forward;
      param_list.add(MouseoverParams(helix_idx, offset, forward));
    }

    app.dispatch(actions.MouseoverDataUpdate(mouseover_params: BuiltList<MouseoverParams>(param_list)));
  }

  convert_crossover_to_loopout() async {
    int new_length = await ask_for_length('change loopout length', current_length: 1, lower_bound: 1);
    if (new_length == null || new_length == 0) {
      return;
    }
    app.dispatch(actions.ConvertCrossoverToLoopout(props.crossover, new_length));
  }
}
