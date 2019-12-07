@JS()
library view_design;

import 'dart:convert';
import 'dart:html';
import 'dart:svg' as svg;

import 'package:dnd/dnd.dart';
import 'package:js/js.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/react_dom.dart' as react_dom;
import 'package:platform_detect/platform_detect.dart';

import '../state/app_state.dart';
import '../app.dart';
import 'view.dart';
import 'design_side.dart';
import '../util.dart' as util;
import 'design_main.dart';
import 'design_footer.dart';
import 'svg_filters.dart';
import 'error_message.dart';
import '../middleware/local_storage.dart' as local_storage;
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;

const DEBUG_PRINT_SIDE_VIEW_MOUSE_POSITION = false;
//const DEBUG_PRINT_SIDE_VIEW_MOUSE_POSITION = true;

const FOOTER_ID = 'design-footer-mouse-over';
const MODES_ID = 'design-mode-buttons';
const SIDE_VIEW_SVG_VIEWPORT_GROUP = 'side-view-svg-viewport';
const MAIN_VIEW_SVG_VIEWPORT_GROUP = 'main-view-svg-viewport';
const SIDE_VIEW_SVG_ID = 'side-view-svg';
const MAIN_VIEW_SVG_ID = 'main-view-svg';

enum DraggableComponent { main, side }

class DesignViewComponent {
  DivElement root_element;

  DivElement design_above_footer_pane = DivElement()..attributes = {'id': 'design'};
  DivElement footer_separator = DivElement()
    ..attributes = {'id': 'design-footer-separator', 'class': 'fixed-separator'};
  DivElement footer_element = DivElement()..attributes = {'id': FOOTER_ID};
  DivElement modes_element = DivElement()..attributes = {'id': MODES_ID};
  DivElement error_message_pane = DivElement()..attributes = {'id': 'error-message-pane'};

  svg.SvgSvgElement side_view_svg;
  svg.SvgSvgElement main_view_svg;

  ErrorMessageComponent error_message_component;

  DivElement side_pane;
  DivElement main_pane;

  bool svg_panzoom_has_been_set_up = false;

  Point<num> side_view_mouse_position = Point<num>(0, 0);
  Set<int> keys_pressed = {};

  DesignViewComponent(this.root_element) {
    this.side_pane = DivElement()..attributes = {'id': 'side-pane', 'class': 'split'};
    var side_main_separator = DivElement()
      ..attributes = {'id': 'side-main-separator', 'class': 'draggable-separator'};
    this.main_pane = DivElement()..attributes = {'id': 'main-pane', 'class': 'split'};

    side_view_svg = svg.SvgSvgElement()
      ..attributes = {
        'id': SIDE_VIEW_SVG_ID,
        'width': '100%',
        'height': '100%',
      };

    main_view_svg = svg.SvgSvgElement()
      ..attributes = {
        'id': MAIN_VIEW_SVG_ID,
        'width': '100%',
        'height': '100%',
      };
    add_shadow_filter(main_view_svg);

    var side_view_svg_viewport = svg.GElement()
      ..attributes = {
        'id': SIDE_VIEW_SVG_VIEWPORT_GROUP,
      };
    var main_view_svg_viewport = svg.GElement()..attributes = {'id': MAIN_VIEW_SVG_VIEWPORT_GROUP};

    side_view_svg.children.add(side_view_svg_viewport);
    main_view_svg.children.add(main_view_svg_viewport);

    var side_view_dummy_elt = svg.CircleElement()
      ..attributes = {'id': 'dummy-elt-side-view', 'r': '100', 'cx': '100', 'cy': '50', 'fill': 'white'};
    var main_view_dummy_elt = svg.CircleElement()
      ..attributes = {'id': 'dummy-elt-main-view', 'r': '200', 'cx': '100', 'cy': '100', 'fill': 'white'};
    side_view_svg_viewport.children.add(side_view_dummy_elt);
    main_view_svg_viewport.children.add(main_view_dummy_elt);

    this.root_element.children.add(design_above_footer_pane);
    this.root_element.children.add(this.footer_separator);
    this.root_element.children.add(this.footer_element);

    design_above_footer_pane.children.add(side_pane);
    design_above_footer_pane.children.add(side_main_separator);
    design_above_footer_pane.children.add(main_pane);
    setup_splits(false);

    this.error_message_component = ErrorMessageComponent(error_message_pane);

    side_pane.children.add(side_view_svg);
    main_pane.children.add(main_view_svg);

    set_side_main_pane_widths();
    handle_keyboard_mouse_events();

//    app.state.design_or_error_store.listen((_) => this.render());
  }

  set_side_main_pane_widths() {
    String side_pane_width = local_storage.side_pane_width();
    if (side_pane_width == null) {
      side_pane_width = constants.default_side_pane_width;
    }
    num main_pane_width_int = 100.0 - num.parse(side_pane_width.substring(0, side_pane_width.length - 1));
    String main_pane_width = '${main_pane_width_int.toString()}%';
    side_pane.setAttribute('style', 'width: $side_pane_width');
    main_pane.setAttribute('style', 'width: $main_pane_width');
  }

  Map<DraggableComponent, Draggable> draggables = {
    DraggableComponent.main: null,
    DraggableComponent.side: null,
  };

  handle_keyboard_mouse_events() {
    side_view_svg.onMouseLeave.listen((_) => side_view_mouse_leave_update_mouseover());
    side_view_svg.onMouseMove.listen((event) {
      side_view_mouse_position = event.client;
      side_view_update_mouseover(keys_pressed, event: event);
    });

    // need to install and uninstall Draggable on each cycle of Ctrl/Shift key-down/up,
    // because while installed, Draggable stops the mouse events that the svg-pan-zoom library listens to.
    window.onKeyDown.listen((ev) {
      int key = ev.which;

      if (!ev.repeat) {
        keys_pressed.add(key);
      }

      if ((key == constants.KEY_CODE_TOGGLE_SELECT ||
              key == constants.KEY_CODE_TOGGLE_SELECT_MAC ||
              key == constants.KEY_CODE_SELECT) &&
          !ev.repeat) {
        install_draggable(true, DraggableComponent.main, main_view_svg);
        install_draggable(false, DraggableComponent.side, side_view_svg);
      }

      if (key == constants.KEY_CODE_SHOW_POTENTIAL_HELIX && !ev.repeat) {
        side_view_update_mouseover(keys_pressed, mouse_pos: side_view_mouse_position);
      }

      if (key == constants.KEY_CODE_MOUSEOVER_HELIX_VIEW_INFO && !ev.repeat) {
        app.store.dispatch(actions.SetShowMouseoverRect(true));
      }

      if (key == KeyCode.ESC) {
        if (app.state.ui_state.selectables_store.isNotEmpty) {
          app.store.dispatch(actions.SelectionsClear());
        }
        if (app.state.ui_state.side_selected_helix_idxs.isNotEmpty) {
          app.store.dispatch(actions.HelixSelectionsClear());
        }
      }

      if (key == KeyCode.DELETE) {
        app.store.dispatch(actions.DeleteAllSelected());
      }
    });

    window.onKeyUp.listen((ev) {
      int key = ev.which;

      keys_pressed.remove(key);

      if (key == constants.KEY_CODE_TOGGLE_SELECT ||
          key == constants.KEY_CODE_TOGGLE_SELECT_MAC ||
          key == constants.KEY_CODE_SELECT) {
        uninstall_draggable(true, DraggableComponent.main);
        uninstall_draggable(false, DraggableComponent.side);
      }
      if (key == constants.KEY_CODE_MOUSEOVER_HELIX_VIEW_INFO && !ev.repeat) {
        if (app.state.ui_state.show_mouseover_rect) {
          app.store.dispatch(actions.SetShowMouseoverRect(false));
        }
        // removes mouseover even if on crossover even though we don't want that. Oh well

        if (app.state.ui_state.mouseover_datas.isNotEmpty) {
          app.store.dispatch(actions.MouseoverDataClear());
        }
      }

      if (key == constants.KEY_CODE_SHOW_POTENTIAL_HELIX &&
          app.state.ui_state.side_view_grid_position_mouse_cursor != null) {
        app.store.dispatch(actions.MouseGridPositionSideClear());
      }
    });

    //XXX: this does NOT get fired when Draggable is running things, in particular when the user
    // did Ctrl+mouse or Shift+mouse to drag a selection box over items and raised the mouse button to
    // finish the box
//    main_view_svg.onMouseUp.listen((ev) {
//      // XXX: if we decide to unselect items here, add some logic to make sure we didn't just get done moving a
//      // selected item/group of items
//      if (!(ev.ctrlKey || ev.metaKey || ev.shiftKey) &&
//          app.state.ui_state.selectables_store.selected_items.isNotEmpty) {
////        Actions_OLD.unselect_all();
//      }
//    });
//    side_view_svg.onMouseUp.listen((ev) {
//      if (!(ev.ctrlKey || ev.metaKey || ev.shiftKey)) {
//        //XXX: maybe should unselect the helices, but it's probably more convenient to let them stay selected
////        app.store.dispatch(actions.HelicesSelectedClear());
//      }
//    });
  }

  uninstall_draggable(bool is_main_view, DraggableComponent draggable_component) {
    if (draggables[draggable_component] != null) {
      draggables[draggable_component].destroy();
      draggables[draggable_component] = null;
      // class .dnd-drag-occurring not removed if Shift or Ctrl key depressed while mouse is lifted,
      // so we need to remove it manually just in case
      document.body.classes.remove('dnd-drag-occurring');
      if (app.store_selection_box.state != null) {
        app.store_selection_box.dispatch(actions.SelectionBoxRemove(is_main_view));
      }
    }
  }

  install_draggable(bool is_main_view, DraggableComponent draggable_component, svg.SvgSvgElement view_svg) {
    if (draggables[draggable_component] != null) {
      return;
    }

    var draggable = draggables[draggable_component] = Draggable(view_svg);

    draggable.onDragStart.listen((DraggableEvent draggable_event) {
//      print('* onDragStart ' + '*' * 100);

      MouseEvent event = draggable_event.originalEvent;
      actions.Action2 action;

      Point<num> point;

      if (!browser.isFirefox) {
        point = event.offset;
        point = util.transform_mouse_coord_to_svg_current_panzoom(point, is_main_view);
      } else {
        point = util.untransformed_svg_point(view_svg, event: event);
        point = util.transform_mouse_coord_to_svg_current_panzoom(point, is_main_view);
      }

//      print('start event.offset:   (${event.offset.x.toStringAsFixed(1)}, ${event.offset.y.toStringAsFixed(1)})');
//      print('start event.client:   (${event.client.x.toStringAsFixed(1)}, ${event.client.y.toStringAsFixed(1)})');
//      print('start point:          (${point.x.toStringAsFixed(1)}, ${point.y.toStringAsFixed(1)})');
//      print('start target: ${event.target}');

      bool toggle;
      if (event.ctrlKey || event.metaKey) {
        toggle = true;
      } else if (event.shiftKey) {
        toggle = false;
      }
      if (toggle != null) {
        action = actions.SelectionBoxCreate(point, toggle, is_main_view);
//        app.store.dispatch(action);
        app.store_selection_box.dispatch(action);
      }
    });

    draggable.onDrag.listen((DraggableEvent draggable_event) {
//      print('* onDrag ' + '-' * 100);

      MouseEvent event = draggable_event.originalEvent;

      Point<num> point;

      Element target = event.target; // || event.srcElement,

      if (!browser.isFirefox) {
        point = event.offset;
        point = util.transform_mouse_coord_to_svg_current_panzoom(point, is_main_view);
      } else {
        point = util.untransformed_svg_point(view_svg, event: event);
        point = util.transform_mouse_coord_to_svg_current_panzoom(point, is_main_view);
      }

//      print('current event.offset: (${event.offset.x.toStringAsFixed(1)}, ${event.offset.y.toStringAsFixed(1)})');
//      print('current event.client: (${event.client.x.toStringAsFixed(1)}, ${event.client.y.toStringAsFixed(1)})');
//      print('current point:        (${point.x.toStringAsFixed(1)}, ${point.y.toStringAsFixed(1)})');
//      print('current target: ${event.target}');

      if (event.ctrlKey || event.metaKey || event.shiftKey) {
        var action = actions.SelectionBoxSizeChange(point, is_main_view);
//        app.store.dispatch(actions.ThrottledAction(action, 1 / 60.0));
        app.store_selection_box.dispatch(actions.ThrottledAction(action, 1 / 60.0));
      }
    });

    draggable.onDragEnd.listen((DraggableEvent draggable_event) {
      var action_remove = actions.SelectionBoxRemove(is_main_view);
      bool toggle = app.store_selection_box.state.toggle;
      var action_adjust;
      if (is_main_view) {
        action_adjust = actions.SelectionsAdjust(toggle);
      } else {
        action_adjust = actions.HelixSelectionsAdjust(toggle, app.store_selection_box.state);
      }
      // call this first so selection box is still in view when selections are made,
      // so we can detect intersection
      app.store.dispatch(action_adjust);
      app.store_selection_box.dispatch(action_remove);
    });
  }

  render(AppState state) {
    if (state.has_error()) {
      if (!this.root_element.children.contains(this.error_message_pane)) {
        this.root_element.children.clear();
        this.root_element.children.add(this.error_message_pane);
      }
      this.error_message_component.render(state.error_message);
    } else {
//      var react_svg_pan_zoom_side = UncontrolledReactSVGPanZoom(
//        {
//          'width': '100%',
//          'height': '100%',
//        },
//        (Dom.svg()
//          ..id = 'side-view-svg'
//          ..width = '100%'
//          ..height = '100%')(
//          (DesignSide()..store = app.state.dna_design.helices_store)(),
//        ),
//      );
//      react_dom.render(react_svg_pan_zoom_side, this.side_pane);
//
//      var react_svg_pan_zoom_main = UncontrolledReactSVGPanZoom(
//        {
//          'width': '100%',
//          'height': '100%',
//        },
//        (Dom.svg()
//          ..id = 'main-view-svg'
//          ..width = '100%'
//          ..height = '100%')(
//          (DesignMain()..store = app.state)(),
//        ),
//      );
//      react_dom.render(react_svg_pan_zoom_main, this.main_pane);

      if (!this.root_element.children.contains(this.design_above_footer_pane)) {
        this.root_element.children.clear();
        this.root_element.children.add(this.design_above_footer_pane);
        this.root_element.children.add(this.footer_separator);
        this.root_element.children.add(this.footer_element);
      }

      react_dom.render(
        ErrorBoundary()(
          (ReduxProvider()..store = app.store)((ReduxProvider()
            ..store = app.store_selection_box
            ..context = app.context_selection_box)(
            ConnectedDesignSide()(),
          )),
        ),
        querySelector('#$SIDE_VIEW_SVG_VIEWPORT_GROUP'),
      );

      react_dom.render(
        ErrorBoundary()(
          (ReduxProvider()..store = app.store)((ReduxProvider()
            ..store = app.store_selection_box
            ..context = app.context_selection_box)(
            ConnectedDesignMain()(),
          )),
        ),
        querySelector('#$MAIN_VIEW_SVG_VIEWPORT_GROUP'),
      );

      react_dom.render(
        ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignFooter()(),
          ),
        ),
        this.footer_element,
      );

      if (!svg_panzoom_has_been_set_up) {
        setup_svg_panzoom_js();
        svg_panzoom_has_been_set_up = true;
      }
    }
  }
}

side_view_mouse_leave_update_mouseover() {
  if (app.state.ui_state.side_view_grid_position_mouse_cursor != null) {
    app.store.dispatch(actions.MouseGridPositionSideClear());
  }
}

side_view_update_mouseover(Set<int> keys_pressed, {Point<num> mouse_pos = null, MouseEvent event = null}) {
  assert(!(mouse_pos == null && event == null));
  if (keys_pressed.contains(constants.KEY_CODE_SHOW_POTENTIAL_HELIX)) {
    var new_grid_pos = util.grid_position_of_mouse_in_side_view(app.state.dna_design.grid,
        mouse_pos: mouse_pos, event: event);
    if (app.state.ui_state.side_view_grid_position_mouse_cursor != new_grid_pos) {
      app.store.dispatch(actions.MouseGridPositionSideUpdate(new_grid_pos));
    }
  } else {
    if (app.state.ui_state.side_view_grid_position_mouse_cursor != null) {
      app.store.dispatch(actions.MouseGridPositionSideClear());
    }
  }
}
