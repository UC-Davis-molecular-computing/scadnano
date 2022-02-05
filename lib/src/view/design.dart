@JS()
library view_design;

import 'dart:html';
import 'dart:svg' as svg;

import 'package:built_collection/built_collection.dart';
import 'package:dnd/dnd.dart';
import 'package:js/js.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/react_dom.dart' as react_dom;
import 'package:over_react/components.dart' as over_react_components;
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/middleware/system_clipboard.dart';
import 'package:scadnano/src/state/domains_move.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/helix_group_move.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/selection_rope.dart';
import 'package:scadnano/src/view/design_main_arrows.dart';
import 'package:scadnano/src/view/strand_color_picker.dart';

import '../state/address.dart';
import '../state/dna_ends_move.dart';
import '../state/edit_mode.dart';
import '../state/helix.dart';
import '../state/strand_creation.dart';
import '../state/strands_move.dart';

import '../state/app_state.dart';
import '../app.dart';
import 'design_context_menu.dart';
import 'design_dialog_form.dart';
import 'design_main_error_boundary.dart';
import 'design_side_arrows.dart';
import 'menu_side.dart';
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
const SIDE_VIEW_MENU_ID = 'side-view-menu';
const SIDE_VIEW_SVG_VIEWPORT_GROUP = 'side-view-svg-viewport';
const MAIN_VIEW_SVG_VIEWPORT_GROUP = 'main-view-svg-viewport';
const SIDE_VIEW_SVG_ID = 'side-view-svg';
const MAIN_VIEW_SVG_ID = 'main-view-svg';
const SIDE_VIEW_ARROWS_SVG_ID = 'side-arrows';
const MAIN_VIEW_ARROWS_SVG_ID = 'main-arrows';

const PANZOOMABLE_CLASS = 'panzoomable';
const DRAGGING_CLASS = 'dragging';
const SELECTION_BOX_DRAWABLE_CLASS = 'selection-box-drawable';

enum DraggableComponent { main, side }

class DesignViewComponent {
  DivElement root_element;

  DivElement design_above_footer_pane = DivElement()..attributes = {'id': 'design'};
  DivElement footer_separator = DivElement()
    ..attributes = {'id': 'design-footer-separator', 'class': 'fixed-separator'};
  DivElement footer_element = DivElement()..attributes = {'id': FOOTER_ID};
  DivElement modes_element = DivElement()..attributes = {'id': MODES_ID};
  DivElement error_message_pane = DivElement()..attributes = {'id': 'error-message-pane'};

  DivElement side_view_menu = DivElement()..attributes = {'id': SIDE_VIEW_MENU_ID};

  DivElement context_menu_container = DivElement()..attributes = {'id': 'context-menu-container'};
  DivElement dialog_form_container = DivElement()..attributes = {'class': 'dialog-form-container'};
  DivElement strand_color_picker_container = DivElement()
    ..attributes = {'id': 'strand-color-picker-container'};

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
        'class': PANZOOMABLE_CLASS,
        'width': '100%',
        'height': '100%',
      };

    main_view_svg = svg.SvgSvgElement()
      ..attributes = {
        'id': MAIN_VIEW_SVG_ID,
        'class': PANZOOMABLE_CLASS,
        'width': '100%',
        'height': '100%',
      };
    add_shadow_filter(main_view_svg);

    var main_arrows = svg.SvgSvgElement()
      ..attributes = {
        'id': MAIN_VIEW_ARROWS_SVG_ID,
        'width': '85px',
        'height': '85px',
      };

    var side_arrows = svg.SvgSvgElement()
      ..attributes = {
        'id': SIDE_VIEW_ARROWS_SVG_ID,
        'width': '85px',
        'height': '85px',
      };

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
    this.root_element.children.add(this.strand_color_picker_container);
    this.root_element.children.add(this.footer_separator);
    this.root_element.children.add(this.footer_element);

    design_above_footer_pane.children.add(side_pane);
    design_above_footer_pane.children.add(side_main_separator);
    design_above_footer_pane.children.add(main_pane);
    setup_splits(false);

    this.error_message_component = ErrorMessageComponent(error_message_pane);

    side_pane.children.add(side_view_menu);
    side_pane.children.add(side_view_svg);
    side_pane.children.add(side_arrows);
    main_pane.children.add(main_view_svg);
    main_pane.children.add(main_arrows);

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
    document.onClick.listen((MouseEvent event) {
      Element target = event.target;
      // put away context menu if click occurred anywhere outside of it
      if (app.state.ui_state.context_menu != null) {
        var context_menu_elt = querySelector('#context-menu');
        if (context_menu_elt != null && !context_menu_elt.contains(target)) {
          app.dispatch(actions.ContextMenuHide());
        }
      }
      // put away strand color picker if click occurred anywhere outside of it
      if (app.state.ui_state.strand_color_picker_strand != null) {
        var strand_color_picker_elt = querySelector('#strand-color-picker');
        if (strand_color_picker_elt != null && !strand_color_picker_elt.contains(target)) {
          app.dispatch(actions.StrandColorPickerHide());
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
      // which calls [main_view_pointer_up]
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

    main_view_svg.onMouseMove.listen((MouseEvent event) {
      // https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/buttons
      bool left_mouse_button_is_down = util.left_mouse_button_pressed_during_mouse_event(event);

      // move potential crossover
      main_view_mouse_position = event.client;
      main_view_move_potential_crossover(event);

      // redraw potential next point for selection rope
      if (edit_mode_is_rope_select() &&
          app.state.ui_state.selection_rope != null &&
          (event.ctrlKey || event.metaKey || event.shiftKey)) {
        bool is_main_view = true;
        var view_svg = main_view_svg;
        Point<num> point =
            util.transform_mouse_coord_to_svg_current_panzoom_correct_firefox(event, is_main_view, view_svg);
        var action = actions.SelectionRopeMouseMove(point: point, is_main_view: is_main_view);
        app.dispatch(actions.ThrottledActionFast(action, 1 / 60.0));
      }

      // move slice bar
      if (left_mouse_button_is_down && app.state.ui_state.slice_bar_is_moving) {
        String displayed_group_name = app.state.ui_state.displayed_group_name;
        var group = app.state.design.groups[displayed_group_name];
        var helices_in_group = app.state.design.helices_in_group(displayed_group_name).values;
        int old_offset = app.state.ui_state.storables.slice_bar_offset;
        var new_offset = util.find_closest_offset(event, helices_in_group, group, app.state.design.geometry,
            app.state.helix_idx_to_svg_position_map[helices_in_group.first.idx].x);

        if (old_offset != new_offset) {
          app.dispatch(actions.SliceBarOffsetSet(new_offset));
        }
      }

      // DNAEnds, Strands, and HelixGroup move only should happen while left click is enabled
      if (left_mouse_button_is_down) {
        // move selected DNA ends
        DNAEndsMove moves_store = app.store_dna_ends_move.state;
        if (moves_store != null) {
          var group_names = group_names_of_ends(moves_store);
          if (group_names.length != 1) {
            var msg = 'Cannot move or copy DNA ends unless they are all on the same helix group.\n'
                'The selected ends occupy the following helix groups: ${group_names?.join(", ")}';
            window.alert(msg);
          } else {
            Helix helix = moves_store.helix;
            var group = app.state.design.groups[helix.group];
            var geometry = app.state.design.geometry;
            int offset = util
                .get_address_on_helix(
                    event, helix, group, geometry, app.state.helix_idx_to_svg_position_map[helix.idx])
                .offset;
            int old_offset = moves_store.current_offset;
            if (offset != old_offset) {
              app.dispatch(actions.DNAEndsMoveAdjustOffset(offset: offset));
            }
          }
        }
      }

      // move selected Strands
      StrandsMove strands_move = app.state.ui_state.strands_move;
      if (strands_move != null) {
        if (strands_move.copy || left_mouse_button_is_down) {
          // ugg... when copy/pasting, the left click doesn't have to be depressed.
          // when moving, it does.
          // paste is stopped from ever getting here (and the user was warned in strands_move_middleware)
          // if strands were on many groups, so it's safe to execute this, IF copy is true.
          // If moving, then we rely on the error-checking code next to warn the user
          // about strands being in multiple groups.
          // In particular, if we are pasting strands copied from a different design,
          // then the helices from the source design may be all on the same group, but the same helix
          // idx's in this design are on different groups. So we don't want to do the check for copying;
          // instead we rely on middleware
          // (which checked StrandsMoveStart.original_helices_view_order_inverse, which is set to null
          // on copying with Ctrl+C if the original helices were from different groups).
          bool can_paste = true;
          if (!strands_move.copy) {
            var group_names = group_names_of_strands(strands_move);
            if (group_names != null && group_names.length != 1) {
              var msg = 'Cannot move or copy strands unless they are all on the same helix group.\n'
                  'These strands occupy the following helix groups: ${group_names?.join(", ")}';
              window.alert(msg);
              can_paste = false;
            }
          }
          if (can_paste) {
            var old_address = strands_move.current_address;
            var visible_helices = app.state.ui_state.only_display_selected_helices
                ? [
                    for (var helix in app.state.design.helices.values)
                      if (app.state.ui_state.side_selected_helix_idxs.contains(helix.idx)) helix
                  ]
                : app.state.design.helices.values;
            var address = util.find_closest_address(event, visible_helices, app.state.design.groups,
                app.state.design.geometry, app.state.helix_idx_to_svg_position_map);
            if (address != old_address) {
              app.dispatch(actions.StrandsMoveAdjustAddress(address: address));
            }
          }
        }
      }

      // move selected Domains
      DomainsMove domains_move = app.state.ui_state.domains_move;
      if (domains_move != null) {
        if (left_mouse_button_is_down) {
          var group_names = group_names_of_domains(domains_move);
          if (group_names.length != 1) {
            var msg = 'Cannot move or copy domains unless they are all on the same helix group.\n'
                'These domains occupy the following helix groups: ${group_names?.join(", ")}';
            window.alert(msg);
          } else {
            var old_address = domains_move.current_address;
            var visible_helices = app.state.ui_state.only_display_selected_helices
                ? [
                    for (var helix in app.state.design.helices.values)
                      if (app.state.ui_state.side_selected_helix_idxs.contains(helix.idx)) helix
                  ]
                : app.state.design.helices.values;
            var address = util.find_closest_address(event, visible_helices, app.state.design.groups,
                app.state.design.geometry, app.state.helix_idx_to_svg_position_map);
            if (address != old_address) {
              app.dispatch(actions.DomainsMoveAdjustAddress(address: address));
            }
          }
        }
      }

      // move strand creation
      StrandCreation strand_creation = app.state.ui_state.strand_creation;
      if (strand_creation != null) {
        int old_offset = strand_creation.current_offset;
        var group = app.state.design.groups[strand_creation.helix.group];
        var geometry = app.state.design.geometry;
        int new_offset = util
            .get_address_on_helix(event, strand_creation.helix, group, geometry,
                app.state.helix_idx_to_svg_position_map[strand_creation.helix.idx])
            .offset;
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

    end_select_mode() {
      uninstall_draggable(true, DraggableComponent.main);
      uninstall_draggable(false, DraggableComponent.side);

      // restore panzoomable class to change CSS cursor
      for (var svg_elt in [this.main_view_svg, this.side_view_svg]) {
        svg_elt.classes.add(PANZOOMABLE_CLASS);
        svg_elt.classes.remove(SELECTION_BOX_DRAWABLE_CLASS);
      }

      // if rope-selecting, send actions to select items and remove displayed rope
      if (edit_mode_is_rope_select()) {
        // print('key up: ${key}');
        SelectionRope rope = app.store_selection_rope.state;
        if (rope != null) {
          bool toggle = rope.toggle;
          var action_adjust = null;
          // rope.is_main might be null;
          // also if there's only 1 or 2 points, it's not a Jordan curve yet so don't bother selecting
          if (rope.is_main == true && rope.points.length >= 3) {
            action_adjust = actions.SelectionsAdjustMainView(toggle: toggle, box: false);
          } else if (rope.is_main == false) {
            // action_adjust = actions.HelixSelectionsAdjust(toggle, app.store_selection_box.state);
          }
          if (action_adjust != null) {
            app.dispatch(action_adjust);
          }

          var action_remove = actions.SelectionRopeRemove();
          app.dispatch(action_remove);
        }
      }
    }

    window.onBlur.listen((_) => end_select_mode());

    window.onKeyUp.listen((ev) {
      int key = ev.which;

      app.keys_pressed.remove(key);

      if (key == constants.KEY_CODE_TOGGLE_SELECT ||
          key == constants.KEY_CODE_TOGGLE_SELECT_MAC ||
          key == constants.KEY_CODE_SELECT) {
        end_select_mode();
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

    // listen for clicks in rope select mode, and also open/close grabbing hand through CSS classes
    for (var svg_elt in [main_view_svg, side_view_svg]) {
      bool is_main_view = (svg_elt == main_view_svg);
      svg_elt.onMouseDown.listen((MouseEvent event) {
        // listen for clicks in rope select view to add points
        bool left_click = util.left_mouse_button_caused_mouse_event(event);
        bool selection_rope_exists = app.state.ui_state.selection_rope != null;
        if (selection_rope_exists && left_click && edit_mode_is_rope_select()) {
          Point<num> point =
              util.transform_mouse_coord_to_svg_current_panzoom_correct_firefox(event, is_main_view, svg_elt);
          app.dispatch(actions.SelectionRopeAddPoint(point: point, is_main_view: is_main_view));
        }

        // close grabbing hand if mouse key is going down
        if (left_click) {
          svg_elt.classes.add(DRAGGING_CLASS);
        }
      });

      // open grabbing hand if mouse key is going up
      svg_elt.onMouseUp.listen((MouseEvent event) {
        if (util.left_mouse_button_caused_mouse_event(event)) {
          svg_elt.classes.remove(DRAGGING_CLASS);
        }
      });
    }

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
    if (app.state.ui_state.selectables_store.isNotEmpty) {
      app.dispatch(actions.SelectionsClear());
    }
    if (app.state.ui_state.side_selected_helix_idxs.isNotEmpty) {
      app.dispatch(actions.HelixSelectionsClear());
    }
    if (app.state.ui_state.potential_crossover_is_drawing) {
      app.dispatch(actions.PotentialCrossoverRemove());
    }
    if (app.state.ui_state.strands_move != null) {
      app.dispatch(actions.StrandsMoveStop());
    }
    if (app.state.ui_state.domains_move != null) {
      app.dispatch(actions.DomainsMoveStop());
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
    if (app.state.ui_state.selection_rope != null) {
      app.dispatch(actions.SelectionRopeRemove());
    }
    app.keyboard_shortcuts_enabled = true;
  }

  handle_keyboard_shortcuts(int key, KeyboardEvent ev) {
    // if ((edit_mode_is_select_or_rope_select() || edit_mode_is_move_group()) &&
    if ((edit_mode_is_select() || edit_mode_is_move_group()) &&
        (key == constants.KEY_CODE_TOGGLE_SELECT ||
            key == constants.KEY_CODE_TOGGLE_SELECT_MAC ||
            key == constants.KEY_CODE_SELECT)) {
      //NOTE: we don't want to install_draggable in rope select mode, because that disrupts the
      // event handlers for mouse clicks needed to detect when clicking to add a point.
      // So we repeat the logic for adding SELECTION_BOX_DRAWABLE_CLASS and removing PANZOOMABLE_CLASS
      // in an else if clause below

      // start drag mode to either draw selection box or translate helix group
      install_draggable(true, DraggableComponent.main, main_view_svg);
      install_draggable(false, DraggableComponent.side, side_view_svg);

      // remove panzoomable class to change CSS cursor
      for (var svg_elt in [this.main_view_svg, this.side_view_svg]) {
        svg_elt.classes.remove(PANZOOMABLE_CLASS);
        svg_elt.classes.add(SELECTION_BOX_DRAWABLE_CLASS);
      }
    } else if (!ev.ctrlKey &&
        !ev.metaKey &&
        !ev.shiftKey &&
        !ev.altKey &&
        EditModeChoice.key_code_to_mode.keys.contains(key)) {
      // switch edit mode based on keyboard shortcut
      app.dispatch(actions.EditModeToggle(EditModeChoice.key_code_to_mode[key]));
    } else if (key == KeyCode.DELETE || (operatingSystem.isMac && key == KeyCode.BACKSPACE)) {
      // delete selected objects
      ev.preventDefault(); // ensure backspace doesn't go to previous page
      if (app.state.ui_state.selectables_store.isNotEmpty) {
        app.dispatch(actions.DeleteAllSelected());
      } else if (app.state.ui_state.side_selected_helix_idxs.isNotEmpty) {
        app.dispatch(actions.HelixRemoveAllSelected());
      }
    } else if (edit_mode_is_rope_select() &&
        (key == constants.KEY_CODE_TOGGLE_SELECT ||
            key == constants.KEY_CODE_TOGGLE_SELECT_MAC ||
            key == constants.KEY_CODE_SELECT)) {
      // Below repeats some logic from above just after calling install_draggable,
      // but we don't want the draggable installed in rope select mode.
      // remove panzoomable class to change CSS cursor
      for (var svg_elt in [this.main_view_svg, this.side_view_svg]) {
        svg_elt.classes.remove(PANZOOMABLE_CLASS);
        svg_elt.classes.add(SELECTION_BOX_DRAWABLE_CLASS);
      }

      // We do want to turn off panning in rope select mode.
      util.set_allow_pan(false);

      // start drawing selection rope, or continue it
      bool toggle = key != constants.KEY_CODE_SELECT;
      app.dispatch(actions.SelectionRopeCreate(toggle: toggle));
    }

    // Ctrl+C/Ctrl+V for copy/paste
    if (app.state.ui_state.selectables_store.selected_strands.isNotEmpty &&
        (ev.ctrlKey || ev.metaKey) &&
        key == KeyCode.C) {
      copy_selected_strands();
    }

    // can paste even if nothing selected or not in select mode, if something is in copy buffer
    if ((ev.ctrlKey || ev.metaKey) && key == KeyCode.V && !ev.shiftKey) {
      // Ctrl+V
      paste_strands_manually();
    } else if ((ev.ctrlKey || ev.metaKey) && ev.shiftKey && key == KeyCode.V) {
      // Ctrl+Shift+V
      paste_strands_auto();
    }

    // Ctrl+A for select all
    if ((ev.ctrlKey || ev.metaKey) && key == KeyCode.A && edit_mode_is_select_or_rope_select()) {
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
    if (app.state.ui_state.edit_modes.contains(EditModeChoice.select)) {
      bool toggle;
      if (event.ctrlKey || event.metaKey) {
        toggle = true;
      } else if (event.shiftKey) {
        toggle = false;
      }
      if (toggle != null) {
        app.dispatch(actions.SelectionBoxCreate(point, toggle, is_main_view));
      }
    } else if (is_main_view && app.state.ui_state.edit_modes.contains(EditModeChoice.move_group)) {
      app.dispatch(actions.HelixGroupMoveStart(mouse_point: point));
    }
  }

  drag(DraggableEvent draggable_event, svg.SvgSvgElement view_svg, bool is_main_view) {
    MouseEvent event = draggable_event.originalEvent;
    Point<num> point =
        util.transform_mouse_coord_to_svg_current_panzoom_correct_firefox(event, is_main_view, view_svg);
    if (edit_mode_is_select()) {
      if (event.ctrlKey || event.metaKey || event.shiftKey) {
        var action = actions.SelectionBoxSizeChange(point, is_main_view);
        app.dispatch(actions.ThrottledActionFast(action, 1 / 60.0));
      }
    } else if (is_main_view && edit_mode_is_move_group()) {
      if (event.ctrlKey || event.metaKey || event.shiftKey) {
        var action = actions.HelixGroupMoveAdjustTranslation(mouse_point: point);
        app.dispatch(actions.ThrottledActionFast(action, 1 / 60.0));
      }
    }
  }

  drag_end(DraggableEvent draggable_event, svg.SvgSvgElement view_svg, bool is_main_view) {
    if (edit_mode_is_select()) {
      if (app.store_selection_box.state == null) {
        return;
      }
      var action_remove = actions.SelectionBoxRemove(is_main_view);
      bool toggle = app.store_selection_box.state.toggle;
      var action_adjust;
      if (is_main_view) {
        action_adjust = actions.SelectionsAdjustMainView(toggle: toggle, box: true);
      } else {
        action_adjust = actions.HelixSelectionsAdjust(toggle, app.store_selection_box.state);
      }
      // call this first so selection box is still in view when selections are made,
      // so we can detect intersection
      app.dispatch(action_adjust);
      app.dispatch(action_remove);
    } else if (is_main_view && edit_mode_is_move_group()) {
      app.dispatch(actions.HelixGroupMoveStop());
    }
  }

  render(AppState state) {
    if (state.has_error) {
      if (!root_element.children.contains(this.error_message_pane)) {
        this.root_element.children.clear();
        this.root_element.children.add(this.error_message_pane);
        this.root_element.children.add(this.dialog_form_container);
        this.root_element.children.add(this.strand_color_picker_container);
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
        this.root_element.children.add(this.strand_color_picker_container);
        this.root_element.children.add(this.context_menu_container);
      }

      // side view menu
      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedSideMenu()(),
          ),
        ),
        querySelector('#$SIDE_VIEW_MENU_ID'),
      );

      // side view svg
      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            (ReduxProvider()
              ..store = app.store_selection_rope
              ..context = app.context_selection_rope)(
              (ReduxProvider()
                ..store = app.store_selection_box
                ..context = app.context_selection_box)(
                ConnectedDesignSide()(),
              ),
            ),
          ),
        ),
        querySelector('#$SIDE_VIEW_SVG_VIEWPORT_GROUP'),
      );

      // main view
      react_dom.render(
        DesignMainErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            (ReduxProvider()
              ..store = app.store_selection_rope
              ..context = app.context_selection_rope)(
              (ReduxProvider()
                ..store = app.store_selection_box
                ..context = app.context_selection_box)(
                (ReduxProvider()
                  ..store = app.store_potential_crossover
                  ..context = app.context_potential_crossover)(
                  (ReduxProvider()
                    ..store = app.store_dna_ends_move
                    ..context = app.context_dna_ends_move)(
                    (ReduxProvider()
                      ..store = app.store_helix_group_move
                      ..context = app.context_helix_group_move)(
                      ConnectedDesignMain()(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        querySelector('#$MAIN_VIEW_SVG_VIEWPORT_GROUP'),
      );

      // main arrows
      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignMainArrows()(),
          ),
        ),
        querySelector('#$MAIN_VIEW_ARROWS_SVG_ID'),
      );

      // side arrows
      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignSideArrows()(),
          ),
        ),
        querySelector('#$SIDE_VIEW_ARROWS_SVG_ID'),
      );

      // footer
      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignFooter()(),
          ),
        ),
        this.footer_element,
      );

      // context menu
      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignContextMenu()(),
          ),
        ),
        this.context_menu_container,
      );

      // interactive dialog
      react_dom.render(
        over_react_components.ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignDialogForm()(),
          ),
        ),
        this.dialog_form_container,
      );

      react_dom.render(
          over_react_components.ErrorBoundary()(
            (ReduxProvider()..store = app.store)(
              ConnectedStrandColorPicker()(),
            ),
          ),
          this.strand_color_picker_container);

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

  copy_selected_strands() {
    // do nothing if no strands are selected
    if (app.state.ui_state.selectables_store.selected_strands.isEmpty) return;
    app.dispatch(actions.CopySelectedStrands());
  }

  paste_strands_manually() {
    // it was much easier to handle the asynchronous read (seems to be the only way to read the clipboard)
    // here than to handle it in middleware;
    // unit testing especially seemed to be very difficult with all the asynchronous calls
    clipboard.read().then((String content) {
      if (content != null && content.isNotEmpty) {
        app.dispatch(actions.ManualPasteInitiate(clipboard_content: content));
      }
    });
  }

  paste_strands_auto() {
    // it was much easier to handle the asynchronous read (seems to be the only way to read the clipboard)
    // here than to handle it in middleware;
    // unit testing especially seemed to be very difficult with all the asynchronous calls
    clipboard.read().then((String content) {
      if (content != null && content.isNotEmpty) {
        app.dispatch(actions.AutoPasteInitiate(clipboard_content: content));
      }
    });
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
    if (edit_mode_is_pencil()) {
      var displayed_group_name = app.state.ui_state.displayed_group_name;
      var displayed_grid = app.state.design.groups[displayed_group_name].grid;
      if (!displayed_grid.is_none) {
        bool invert_y = app.state.ui_state.invert_y;
        Geometry geometry = app.state.design.geometry;
        var new_grid_pos = util.grid_position_of_mouse_in_side_view(displayed_grid, invert_y, geometry,
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

group_names_of_strands(StrandsMove strands_move) =>
    app.state.design.group_names_of_strands(strands_move.strands_moving);

group_names_of_domains(DomainsMove domains_move) =>
    app.state.design.group_names_of_domains(domains_move.domains_moving);

group_names_of_ends(DNAEndsMove ends_move) => app.state.design.group_names_of_ends(ends_move.ends_moving);

main_view_pointer_up(MouseEvent event) {
//  util.set_allow_pan(true);
  if (app.state.ui_state.slice_bar_is_moving) {
    app.dispatch(actions.SliceBarMoveStop());
  }

  DNAEndsMove dna_ends_move = app.store_dna_ends_move.state;
  if (dna_ends_move != null) {
    app.dispatch(actions.DNAEndsMoveStop());
    if (dna_ends_move.is_nontrivial) {
      app.dispatch(actions.DNAEndsMoveCommit(dna_ends_move: dna_ends_move));
    }
  }

  HelixGroupMove helix_group_move = app.store_helix_group_move.state;
  if (helix_group_move != null) {
    app.dispatch(actions.HelixGroupMoveStop());
    if (helix_group_move.is_nontrivial) {
      app.dispatch(actions.HelixGroupMoveCommit(helix_group_move: helix_group_move));
    }
  }

  StrandsMove strands_move = app.state.ui_state.strands_move;
  if (strands_move != null) {
    app.dispatch(actions.StrandsMoveStop());
    // XXX: strands_move.allowable may or may not be meaningful in general
    // (e.g., if middlware or unit tests directly dispatch a StrandsMoveCommit action),
    // but in this case, we are detecting mouse up, so it should have been checked and set properly by
    // strands_move_reducer
    if (strands_move.allowable && (strands_move.is_nontrivial || strands_move.copy)) {
      // even a trivial move can be wanted if we are copying, i.e., user copied strands, deleted them,
      // and wants to paste them back in same position
      app.dispatch(actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false));
    }
  }

  DomainsMove domains_move = app.state.ui_state.domains_move;
  if (domains_move != null) {
    app.dispatch(actions.DomainsMoveStop());
    if (domains_move.allowable && domains_move.is_nontrivial) {
      app.dispatch(actions.DomainsMoveCommit(domains_move: domains_move));
    }
  }

  StrandCreation strand_creation = app.state.ui_state.strand_creation;
  if (strand_creation != null) {
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
