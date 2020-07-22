@JS()
library view_design;

import 'dart:html';
import 'dart:svg' as svg;

import 'package:built_collection/built_collection.dart';
import 'package:dnd/dnd.dart';
import 'package:js/js.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/react_dom.dart' as react_dom;
import 'package:over_react/components.dart' as over_react_components;
import 'package:platform_detect/platform_detect.dart';

import '../state/domain.dart';
import '../state/dna_ends_move.dart';
import '../state/edit_mode.dart';
import '../state/helix.dart';
import '../state/select_mode.dart';
import '../state/strand.dart';
import '../state/strand_creation.dart';
import '../state/strands_move.dart';

import '../state/app_state.dart';
import '../app.dart';
import 'design_context_menu.dart';
import 'design_dialog_form.dart';
import 'design_main_error_boundary.dart';
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

  DivElement context_menu_container = DivElement()..attributes = {'id': 'context-menu-container'};
  DivElement dialog_form_container = DivElement()..attributes = {'class': 'dialog-form-container'};

  svg.SvgSvgElement side_view_svg;
  svg.SvgSvgElement main_view_svg;

  ErrorMessageComponent error_message_component;

  DivElement side_pane;
  DivElement main_pane;

  bool svg_panzoom_has_been_set_up = false;

  Point<num> side_view_mouse_position = Point<num>(0, 0);
  Point<num> main_view_mouse_position = Point<num>(0, 0);

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
    var main_view_svg_viewport = svg.GElement()
      ..attributes = {
        'id': MAIN_VIEW_SVG_VIEWPORT_GROUP,
      };

    side_view_svg.children.add(side_view_svg_viewport);
    main_view_svg.children.add(main_view_svg_viewport);

    var side_view_dummy_elt = svg.CircleElement()
      ..attributes = {'id': 'dummy-elt-side-view', 'r': '100', 'cx': '100', 'cy': '50', 'fill': 'white'};
    var main_view_dummy_elt = svg.CircleElement()
      ..attributes = {'id': 'dummy-elt-main-view', 'r': '200', 'cx': '100', 'cy': '100', 'fill': 'white'};
    side_view_svg_viewport.children.add(side_view_dummy_elt);
    main_view_svg_viewport.children.add(main_view_dummy_elt);

    this.root_element.children.add(design_above_footer_pane);
    this.root_element.children.add(this.context_menu_container);
    this.root_element.children.add(this.dialog_form_container);
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
    // put away context menu if click occured anywhere outside of it
    document.onClick.listen((MouseEvent event) {
      Element target = event.target;
      if (app.state.ui_state.context_menu != null) {
        var context_menu_elt = querySelector('#context-menu');
        if (context_menu_elt != null && !context_menu_elt.contains(target)) {
          app.dispatch(actions.ContextMenuHide());
        }
      }
    });

    side_view_svg.onMouseLeave.listen((_) => side_view_mouse_leave_update_mouseover());
    side_view_svg.onMouseMove.listen((event) {
      side_view_mouse_position = event.client;
      side_view_update_position(event: event);
    });

    // disable pan in svg-pan-zoom unless background SVG object was clicked
    for (var view_svg in [main_view_svg, side_view_svg]) {
      view_svg.onMouseDown.listen((event) {
        util.set_allow_pan(event.target is svg.SvgSvgElement);
      });
      //XXX: Dart doesn't have onPointerUp, so we have to trigger from JS,
      // which calls [main_view_pointer_up] below
//      view_svg.onMouseUp.listen((event) {
//        util.set_allow_pan(true);
//        print('mouse up');
//        if (view_svg == main_view_svg && app.store_dna_ends_move.state != null) {
//          DNAEndsMove dna_ends_move = app.store_dna_ends_move.state;
//          print('mouse up and move != null');
//          app.dispatch(actions.DNAEndsMoveStop(dna_ends_move: dna_ends_move));
//        }
//      });
    }

    main_view_svg.onMouseMove.listen((event) {
      // move potential crossover
      main_view_mouse_position = event.client;
      main_view_move_potential_crossover(event);

      // move selected DNA ends
      DNAEndsMove moves_store = app.store_dna_ends_move.state;
      if (moves_store != null) {
        Helix helix = moves_store.helix;
        int offset = util.get_address_on_helix(event, helix).offset;
        int old_offset = moves_store.current_offset;
        if (offset != old_offset) {
          app.dispatch(actions.DNAEndsMoveAdjustOffset(offset: offset));
        }
      }

      // move selected Strands
      StrandsMove strands_move = app.state.ui_state.strands_move;
      if (strands_move != null) {
        var old_address = strands_move.current_address;
        var address = util.get_closest_address(event, app.state.design.helices.values);
        if (address != old_address) {
          app.dispatch(actions.StrandsMoveAdjustAddress(address: address));
        }
      }

      // move strand creation
      StrandCreation strand_creation = app.state.ui_state.strand_creation;
      if (strand_creation != null) {
        int old_offset = strand_creation.current_offset;
        int new_offset = util.get_address_on_helix(event, strand_creation.helix).offset;
        var new_address = Address(
            helix_idx: strand_creation.helix.idx, offset: new_offset, forward: strand_creation.forward);
        if (old_offset != new_offset &&
            !app.state.design.is_occupied(new_address) && // can't draw strand over existing strand
            new_offset != strand_creation.original_offset && // can't put start and end at same offset
            strand_creation.helix.min_offset <= new_offset && // can't go off end of helix
            new_offset < strand_creation.helix.max_offset) {
          app.dispatch(actions.StrandCreateAdjustOffset(offset: new_offset));
        }
      }
    });

    // need to install and uninstall Draggable on each cycle of Ctrl/Shift key-down/up,
    // because while installed, Draggable stops the mouse events that the svg-pan-zoom library listens to.
    window.onKeyDown.listen((ev) {
      int key = ev.which;

      if (!ev.repeat) {
        app.keys_pressed.add(key);

        if (key == KeyCode.ESC) {
          // special case for ESC so we can close dialogs with it
          handle_esc_keyboard_shortcuts();
        } else if (app.keyboard_shortcuts_enabled) {
          handle_keyboard_shortcuts(key, ev);
        }
      }
    });

    window.onKeyUp.listen((ev) {
      int key = ev.which;

      app.keys_pressed.remove(key);

      if (key == constants.KEY_CODE_TOGGLE_SELECT ||
          key == constants.KEY_CODE_TOGGLE_SELECT_MAC ||
          key == constants.KEY_CODE_SELECT) {
        uninstall_draggable(true, DraggableComponent.main);
        uninstall_draggable(false, DraggableComponent.side);
      }

      if (key == constants.KEY_CODE_SHOW_POTENTIAL_HELIX) {
        if (app.state.ui_state.side_view_grid_position_mouse_cursor != null) {
          app.dispatch(actions.MouseGridPositionSideClear());
        }
        if (app.state.ui_state.side_view_position_mouse_cursor != null) {
          app.dispatch(actions.MousePositionSideClear());
        }
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
////        app.dispatch(actions.HelicesSelectedClear());
//      }
//    });
  }

  handle_esc_keyboard_shortcuts() {
    clear_copy_buffer();
    if (app.state.ui_state.selectables_store.isNotEmpty) {
      app.dispatch(actions.SelectionsClear());
    }
    if (app.state.ui_state.side_selected_helix_idxs.isNotEmpty) {
      app.dispatch(actions.HelixSelectionsClear());
    }
    if (app.state.ui_state.drawing_potential_crossover) {
      app.dispatch(actions.PotentialCrossoverRemove());
    }
    if (app.state.ui_state.strands_move != null) {
      app.dispatch(actions.StrandsMoveStop());
    }
    if (app.state.ui_state.strand_creation != null) {
      app.dispatch(actions.StrandCreateStop());
    }
    if (app.state.ui_state.context_menu != null) {
      app.dispatch(actions.ContextMenuHide());
    }
    if (app.state.ui_state.dialog != null) {
      app.dispatch(actions.DialogHide());
    }
    app.keyboard_shortcuts_enabled = true;
  }

  handle_keyboard_shortcuts(int key, KeyboardEvent ev) {
    if (app.state.ui_state.edit_modes.contains(EditModeChoice.select) &&
        (key == constants.KEY_CODE_TOGGLE_SELECT ||
            key == constants.KEY_CODE_TOGGLE_SELECT_MAC ||
            key == constants.KEY_CODE_SELECT)) {
      install_draggable(true, DraggableComponent.main, main_view_svg);
      install_draggable(false, DraggableComponent.side, side_view_svg);
    } else if (!ev.ctrlKey &&
        !ev.metaKey &&
        !ev.shiftKey &&
        !ev.altKey &&
        EditModeChoice.key_code_to_mode.keys.contains(key)) {
      app.dispatch(actions.EditModeToggle(EditModeChoice.key_code_to_mode[key]));
    } else if (key == KeyCode.DELETE || (operatingSystem.isMac && key == KeyCode.BACKSPACE)) {
      ev.preventDefault(); // ensure backspace doesn't go to previous page
      if (app.state.ui_state.selectables_store.isNotEmpty) {
        app.dispatch(actions.DeleteAllSelected());
      } else if (app.state.ui_state.side_selected_helix_idxs.isNotEmpty) {
        app.dispatch(actions.HelixRemoveAllSelected());
      }
    }

    // Ctrl+C/Ctrl+V for copy/paste
    if (app.state.ui_state.edit_modes.contains(EditModeChoice.select) &&
        app.state.ui_state.select_mode_state.modes.contains(SelectModeChoice.strand) &&
        app.state.ui_state.selectables_store.selected_items.isNotEmpty &&
        (ev.ctrlKey || ev.metaKey) &&
        key == KeyCode.C) {
      copy_selected_strands();
    }
    // can paste even if nothing selected or not in select mode, if something is in copy buffer
    if ((ev.ctrlKey || ev.metaKey) && key == KeyCode.V) {
      paste_selected_strands();
    }

    // Ctrl+A for select all
    if ((ev.ctrlKey || ev.metaKey) &&
        key == KeyCode.A &&
        app.state.ui_state.edit_modes.contains(EditModeChoice.select)) {
      ev.preventDefault();
      app.dispatch(actions.SelectAllSelectable());
    }

    if (key == EditModeChoice.pencil.key_code()) {
      side_view_update_position(mouse_pos: side_view_mouse_position);
    }
  }

  uninstall_draggable(bool is_main_view, DraggableComponent draggable_component) {
    if (draggables[draggable_component] != null) {
      draggables[draggable_component].destroy();
      draggables[draggable_component] = null;
      // class .dnd-drag-occurring not removed if Shift or Ctrl key depressed while mouse is lifted,
      // so we need to remove it manually just in case
      document.body.classes.remove('dnd-drag-occurring');
      if (app.store_selection_box.state != null) {
        app.dispatch(actions.SelectionBoxRemove(is_main_view));
      }
    }
  }

  install_draggable(bool is_main_view, DraggableComponent draggable_component, svg.SvgSvgElement view_svg) {
    if (draggables[draggable_component] != null) {
      return;
    }
    var draggable = draggables[draggable_component] = Draggable(view_svg);
    draggable.onDragStart.listen((ev) => drag_start(ev, view_svg, is_main_view));
    draggable.onDrag.listen((ev) => drag(ev, view_svg, is_main_view));
    draggable.onDragEnd.listen((ev) => drag_end(ev, view_svg, is_main_view));
  }

  drag_start(DraggableEvent draggable_event, svg.SvgSvgElement view_svg, bool is_main_view) {
    MouseEvent event = draggable_event.originalEvent;
    Point<num> point =
        util.transform_mouse_coord_to_svg_current_panzoom_correct_firefox(event, is_main_view, view_svg);
    bool toggle;
    if (event.ctrlKey || event.metaKey) {
      toggle = true;
    } else if (event.shiftKey) {
      toggle = false;
    }
    if (toggle != null) {
      app.dispatch(actions.SelectionBoxCreate(point, toggle, is_main_view));
    }
  }

  drag(DraggableEvent draggable_event, svg.SvgSvgElement view_svg, bool is_main_view) {
    MouseEvent event = draggable_event.originalEvent;
    Point<num> point =
        util.transform_mouse_coord_to_svg_current_panzoom_correct_firefox(event, is_main_view, view_svg);
    if (event.ctrlKey || event.metaKey || event.shiftKey) {
      var action = actions.SelectionBoxSizeChange(point, is_main_view);
      app.dispatch(actions.ThrottledActionFast(action, 1 / 60.0));
    }
  }

  drag_end(DraggableEvent draggable_event, svg.SvgSvgElement view_svg, bool is_main_view) {
    if (app.store_selection_box.state == null) {
      return;
    }
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
    app.dispatch(action_adjust);
    app.dispatch(action_remove);
  }

  render(AppState state) {
    if (state.has_error()) {
      if (!root_element.children.contains(this.error_message_pane)) {
        this.root_element.children.clear();
        this.root_element.children.add(this.error_message_pane);
        this.root_element.children.add(this.dialog_form_container);
      }
      this.error_message_component.render(state.error_message);

      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignDialogForm()(),
          ),
        ),
        this.dialog_form_container,
      );
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
//          (DesignSide()..store = app.state.design.helices_store)(),
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
        this.root_element.children.add(this.dialog_form_container);
        this.root_element.children.add(this.context_menu_container);
      }

      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            (ReduxProvider()
              ..store = app.store_selection_box
              ..context = app.context_selection_box)(
              ConnectedDesignSide()(),
            ),
          ),
        ),
        querySelector('#$SIDE_VIEW_SVG_VIEWPORT_GROUP'),
      );

      react_dom.render(
        DesignMainErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            (ReduxProvider()
              ..store = app.store_selection_box
              ..context = app.context_selection_box)(
              (ReduxProvider()
                ..store = app.store_potential_crossover
                ..context = app.context_potential_crossover)(
                (ReduxProvider()
                  ..store = app.store_dna_ends_move
                  ..context = app.context_dna_ends_move)(
                  ConnectedDesignMain()(),
                ),
              ),
            ),
          ),
        ),
        querySelector('#$MAIN_VIEW_SVG_VIEWPORT_GROUP'),
      );

      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignFooter()(),
          ),
        ),
        this.footer_element,
      );

      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignContextMenu()(),
          ),
        ),
        this.context_menu_container,
      );

      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignDialogForm()(),
          ),
        ),
        this.dialog_form_container,
      );

      if (!svg_panzoom_has_been_set_up) {
        // Need to wrap callbacks so that Dart functions can be called in JavaScript.
        setup_svg_panzoom_js(allowInterop(util.svg_to_png_data),
            allowInterop(util.dispatch_set_zoom_threshold), constants.ZOOM_THRESHOLD);
        svg_panzoom_has_been_set_up = true;
      }
    }
  }

  main_view_move_potential_crossover(MouseEvent event) {
    if (app.store_potential_crossover.state != null) {
      Point<num> point =
          util.transform_mouse_coord_to_svg_current_panzoom_correct_firefox(event, true, main_view_svg);
      var action = actions.PotentialCrossoverMove(point: point);
      app.dispatch(actions.ThrottledActionFast(action, 1 / 60.0));
    }
  }

  actions.StrandsMoveStart copy_action;

  copy_selected_strands() {
    // find minimum helix of any selected strand, then minimum starting offset of that strand
    var strands =
        BuiltList<Strand>(app.state.ui_state.selectables_store.selected_items.where((s) => s is Strand));
    int min_helix_idx;
    int min_offset;
    bool min_forward;
    for (Strand strand in strands) {
      for (Domain substrand in strand.domains()) {
        if (min_helix_idx == null || min_helix_idx > substrand.helix) {
          min_helix_idx = substrand.helix;
          min_offset = substrand.start; // reset this absolutely since helix got smaller
          min_forward = substrand.forward; //
        } else if (min_offset == null || (min_helix_idx == substrand.helix && min_offset > substrand.start)) {
          min_offset = substrand.start;
          min_forward = substrand.forward;
        }
      }
    }

    copy_action = actions.StrandsMoveStart(
        strands: strands,
        address: Address(helix_idx: min_helix_idx, offset: min_offset, forward: min_forward),
        copy: true);
  }

  clear_copy_buffer() {
    copy_action = null;
  }

  paste_selected_strands() {
    if (copy_action != null) {
      app.dispatch(copy_action);
    }
  }

  side_view_mouse_leave_update_mouseover() {
    if (app.state.ui_state.side_view_grid_position_mouse_cursor != null) {
      app.dispatch(actions.MouseGridPositionSideClear());
    }
    if (app.state.ui_state.side_view_position_mouse_cursor != null) {
      app.dispatch(actions.MousePositionSideClear());
    }
  }

  side_view_update_position({Point<num> mouse_pos = null, MouseEvent event = null}) {
    assert(!(mouse_pos == null && event == null));
    if (app.state.ui_state.edit_modes.contains(EditModeChoice.pencil)) {
      if (!app.state.design.grid.is_none()) {
        bool invert_y = app.state.ui_state.invert_yz;
        var new_grid_pos = util.grid_position_of_mouse_in_side_view(app.state.design.grid, invert_y,
            mouse_pos: mouse_pos, event: event);
        if (app.state.ui_state.side_view_grid_position_mouse_cursor != new_grid_pos) {
          app.dispatch(actions.MouseGridPositionSideUpdate(new_grid_pos));
        }
      } else {
        //FIXME: dispatch an action about the position, not grid position
        var svg_pos = util.transformed_svg_point(side_view_svg, false, mouse_pos: mouse_pos, event: event);
        var action = actions.MousePositionSideUpdate(svg_pos: svg_pos);
        app.dispatch(actions.ThrottledActionNonFast(action, 1.0 / 60));
      }
    } else {
      if (app.state.ui_state.side_view_grid_position_mouse_cursor != null) {
        app.dispatch(actions.MouseGridPositionSideClear());
      }
      if (app.state.ui_state.side_view_position_mouse_cursor != null) {
        app.dispatch(actions.MousePositionSideClear());
      }
    }
  }
}

main_view_pointer_up(MouseEvent event) {
//  if (app.store_dna_ends_move.state != null || app.state.ui_state.strands_move != null) {
//    // since this is called from Javascript on a pointerUp event, this stops anything from being selected on
//    // mouse up, which is the default behavior for selectable elements
//    event.stopPropagation();
//  }

  if (app.store_dna_ends_move.state != null) {
    DNAEndsMove dna_ends_move = app.store_dna_ends_move.state;
    app.dispatch(actions.DNAEndsMoveStop());
    if (dna_ends_move.is_nontrivial) {
      app.dispatch(actions.DNAEndsMoveCommit(dna_ends_move: dna_ends_move));
    }
  }

  if (app.state.ui_state.strands_move != null) {
    StrandsMove strands_move = app.state.ui_state.strands_move;
    app.dispatch(actions.StrandsMoveStop());
    if (strands_move.allowable && strands_move.is_nontrivial) {
      app.dispatch(actions.StrandsMoveCommit(strands_move: strands_move));
    }
  }

  if (app.state.ui_state.strand_creation != null) {
    StrandCreation strand_creation = app.state.ui_state.strand_creation;
    app.dispatch(actions.StrandCreateStop());
    if (strand_creation.original_offset != strand_creation.current_offset) {
      app.dispatch(actions.StrandCreateCommit(
          helix_idx: strand_creation.helix.idx,
          forward: strand_creation.forward,
          start: strand_creation.start,
          end: strand_creation.end,
          color: strand_creation.color));
    }
  }
}
