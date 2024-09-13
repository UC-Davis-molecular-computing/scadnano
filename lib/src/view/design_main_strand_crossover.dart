import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/dialog.dart';
import '../state/geometry.dart';

import 'transform_by_helix_group.dart';
import '../state/group.dart';
import '../state/context_menu.dart';
import '../state/helix.dart';
import '../state/crossover.dart';
import '../state/mouseover_data.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'design_main_strand_loopout.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';
import 'pure_component.dart';
import '../state/selectable.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../util.dart' as util;

part 'design_main_strand_crossover.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandCrossoverProps> DesignMainStrandCrossover = _$DesignMainStrandCrossover;

@Props()
mixin DesignMainStrandCrossoverProps on UiProps implements TransformByHelixGroupPropsMixin {
  late Crossover crossover;
  late Strand strand;

  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late bool selected;
  late Domain prev_domain;
  late Domain next_domain;
  late Geometry geometry;
  late double prev_domain_helix_svg_position_y;
  late double next_domain_helix_svg_position_y;
  late bool retain_strand_color_on_selection;
}

@State()
mixin DesignMainStrandCrossoverState on UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the state just to tell if the mouse is hovering over a crossover
  late bool mouse_hover;
}

class DesignMainStrandCrossoverComponent
    extends UiStatefulComponent2<DesignMainStrandCrossoverProps, DesignMainStrandCrossoverState>
    with PureComponent {
  @override
  Map get initialState => (newState()..mouse_hover = false);

  @override
  render() {
    Strand strand = props.strand;
    Crossover crossover = props.crossover;

    var classname = constants.css_selector_crossover;
    if (props.selected) {
      if (props.retain_strand_color_on_selection) {
        classname += ' ' + constants.css_selector_selected;
      } else {
        classname += ' ' + constants.css_selector_selected_pink;
      }
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    // Want to display crossovers within a helix a little darker since it's hard to see them;
    // This is for "crossovers" that really are just buffered space between domains on the same helix.
    if (props.prev_domain.helix == props.next_domain.helix &&
        props.prev_domain.forward == props.next_domain.forward) {
      classname += ' ' + constants.css_selector_crossover_same_helix;
    }

    var prev_group = props.helices[props.prev_domain.helix]!.group;
    var next_group = props.helices[props.next_domain.helix]!.group;
    bool within_group = prev_group == next_group;

    String path;
    if (within_group) {
      path = crossover_path_description_within_group(props.prev_domain, props.next_domain, props.helices,
          props.geometry, props.prev_domain_helix_svg_position_y, props.next_domain_helix_svg_position_y);
    } else {
      path = crossover_path_description_between_groups(
          props.prev_domain,
          props.next_domain,
          props.helices,
          props.geometry,
          props.groups,
          props.prev_domain_helix_svg_position_y,
          props.next_domain_helix_svg_position_y);
    }

    var color = strand.color.toHexColor().toCssString();
    var id = crossover.id;

    //XXX: I believe this was here so that when the crossover was clicked to set the Helix rolls at
    // each other (what we call "unstrain backbone here", the updated rolls would immediately display
    // in the side view while the mouse is on the crossover, instead of requiring a
    // mouseEnter or mouseLeave event. This is probably cleaner to handle in middleware in response
    // to the HelixRollSet action, because we don't
    // want the render() method to have side effects, nor to access global variables.
//    if (state.mouse_hover) {
//      update_mouseover_crossover();
//    }

    // String tooltip = 'PUT TOOLTIP TEXT HERE (if we think of something)';

    var path_props = Dom.path()
      ..d = path
      ..stroke = color
      ..className = classname
      ..onMouseEnter = (ev) {
        setState(newState()..mouse_hover = true);
      }
      ..onMouseLeave = (_) {
        setState(newState()..mouse_hover = false);
      }
      ..onPointerDown = ((ev) {
        if (crossover_selectable(props.crossover)) {
          props.crossover.handle_selection_mouse_down(ev.nativeEvent);
        }
      })
      ..onPointerUp = ((ev) {
        if (crossover_selectable(props.crossover)) {
          props.crossover.handle_selection_mouse_up(ev.nativeEvent);
        }
      })
      ..id = id
      ..key = id;

    if (within_group) {
      path_props.transform = transform_of_helix2(props, props.prev_domain.helix);
    }

    return path_props();
//    (Dom.svgTitle()(tooltip));
  }

  @override
  componentDidMount() {
    var element = querySelector('#${props.crossover.id}')!;
    element.addEventListener('contextmenu', on_context_menu);
    super.componentDidMount();
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.crossover.id}')!;
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev as MouseEvent;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: context_menu_crossover(props.strand).build(),
              position: util.from_point_num(event.page))));
    }
  }

  List<ContextMenuItem> context_menu_crossover(Strand strand) => [
        ContextMenuItem(
          title: 'convert to loopout',
          on_click: convert_crossover_to_loopout,
        ),
        ContextMenuItem(
          title: 'unstrain backbone here',
          on_click: unstrain_backbone_at_crossover,
        ),
      ];

  unstrain_backbone_at_crossover() {
    Domain prev_domain = props.prev_domain;
    Domain next_domain = props.next_domain;
    List<actions.UndoableAction> roll_actions = [];
    for (var domain in [prev_domain, next_domain]) {
      var other_domain = domain == prev_domain ? next_domain : prev_domain;
      int anchor = domain == prev_domain ? domain.offset_3p : domain.offset_5p;
      var roll_action = actions.HelixRollSetAtOther(domain.helix, other_domain.helix, domain.forward, anchor);
      roll_actions.add(roll_action);
    }
    var action = actions.BatchAction(roll_actions, "unstrain backbone at crossover");
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
    int new_length = await ask_for_length(
      'set loopout length',
      current_length: 1,
      lower_bound: 1,
      dialog_type: DialogType.set_loopout_length,
    );
    if (new_length == 0) {
      return;
    }

    var selected_crossovers = app.state.ui_state.selectables_store.selected_crossovers;
    actions.UndoableAction action;
    if (selected_crossovers.length > 0) {
      action = actions.ConvertCrossoversToLoopouts(selected_crossovers, new_length);
    } else {
      action = actions.ConvertCrossoverToLoopout(props.crossover, new_length);
    }
    app.dispatch(action);
  }
}
