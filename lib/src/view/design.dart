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

import '../model/dna_design_action_packs.dart' as dna_design_action_packs;
import '../model/model.dart';
import '../model/selectable.dart';
import '../app.dart';
import 'view.dart';
import 'design_side.dart';
import '../util.dart' as util;
import 'design_main.dart';
import 'design_footer.dart';
import '../constants.dart' as constants;
import '../dispatcher/actions.dart' as actions;
import '../dispatcher/actions_OLD.dart';

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
    side_view_svg.onMouseLeave.listen((_) => side_view_mouse_leave_update_mouseover());
    side_view_svg.onMouseMove.listen((event) {
      side_view_update_mouseover(event);
    });

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

    design_above_footer_pane.children.add(side_pane);
    design_above_footer_pane.children.add(side_main_separator);
    design_above_footer_pane.children.add(main_pane);
    setup_splits(false);

    this.error_message_component = ErrorMessageComponent(error_message_pane);

    side_pane.children.add(side_view_svg);
    main_pane.children.add(main_view_svg);

    handle_main_view_keyboard_mouse_events();

//    app.model.design_or_error_store.listen((_) => this.render());
  }

  Map<DraggableComponent, Draggable> draggables = {
    DraggableComponent.main: null,
    DraggableComponent.side: null,
  };

  handle_main_view_keyboard_mouse_events() {
    // need to install and uninstall Draggable on each cycle of Ctrl/Shift key-down/up,
    // because while installed, Draggable stops the mouse events that the svg-pan-zoom library listens to.
    window.onKeyDown.listen((ev) {
      if ((ev.which == constants.KEY_CODE_CTRL || ev.which == constants.KEY_CODE_SHIFT) && !ev.repeat) {
        install_draggable(true, DraggableComponent.main, main_view_svg);
        install_draggable(false, DraggableComponent.side, side_view_svg);
      }

      if (ev.which == constants.KEY_CODE_ESC) {
        Actions_OLD.unselect_all();
      }

      if (ev.which == constants.KEY_CODE_DELETE) {
        //FIXME:
//        List<Selectable> selected = app.model.ui_model.selection.selections.toList();
//        dna_design_action_packs.delete_all(app.model.dna_design, selected);
        //XXX: we call a method on DNADesign directly here rather than firing an Action. That method will
        // do the work of determining which selections are redundant and only fire a reversible Action
        // for what remains after the set is trimmed.
      }
    });

    window.onKeyUp.listen((ev) {
      if (ev.which == constants.KEY_CODE_CTRL || ev.which == constants.KEY_CODE_SHIFT) {
        uninstall_draggable(true, DraggableComponent.main);
        uninstall_draggable(false, DraggableComponent.side);
      }
    });

    //XXX: this does NOT get fired when Draggable is running things, in particular when the user
    // did Ctrl+mouse or Shift+mouse to drag a selection box over items and raised the mouse button to
    // finish the box
    main_view_svg.onMouseUp.listen((ev) {
      //TODO: add some logic to make sure we didn't just get done moving a selected item/group of items
      if (!(ev.ctrlKey || ev.shiftKey) && app.model.ui_model.selectables_store.selected_items.isNotEmpty) {
        Actions_OLD.unselect_all();
      }
    });
    side_view_svg.onMouseUp.listen((ev) {
      if (!(ev.ctrlKey || ev.shiftKey)) {
        //FIXME: unselect helices
//        Actions_OLD.unselect_all();
      }
    });
  }

  uninstall_draggable(bool main_view, DraggableComponent draggable_component) {
    if (draggables[draggable_component] != null) {
      draggables[draggable_component].destroy();
      draggables[draggable_component] = null;
      // class .dnd-drag-occurring not removed if Shift or Ctrl key depressed while mouse is lifted,
      // so we need to remove it manually just in case
      document.body.classes.remove('dnd-drag-occurring');
//      if (app.model.ui_model.selection_box_store.displayed) {
      if (!main_view && app.model.ui_model.selection_box_side_view.displayed) {
        app.store.dispatch(actions.SideViewSelectionBoxRemove());
      } else if (main_view && app.model.ui_model.selection_box.displayed) {
        app.store.dispatch(actions.MainViewSelectionBoxRemove());
      }
    }
  }

  install_draggable(bool main_view, DraggableComponent draggable_component, svg.SvgSvgElement view_svg) {
    if (draggables[draggable_component] != null) {
      return;
    }

    var draggable = draggables[draggable_component] = Draggable(view_svg);

    draggable.onDragStart.listen((DraggableEvent draggable_event) {
      MouseEvent ev = draggable_event.originalEvent;
      actions.Action2 action;
      Point<num> point = ev.offset;
      if (ev.ctrlKey) {
        action = main_view
            ? actions.MainViewSelectionBoxCreateToggling(point)
            : actions.SideViewSelectionBoxCreateToggling(point);
      } else if (ev.shiftKey) {
        action = main_view
            ? actions.MainViewSelectionBoxCreateSelecting(point)
            : actions.SideViewSelectionBoxCreateSelecting(point);
      } else if (ev.button == 0) {
        // detects left mouse button: https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/button
        //FIXME: implement this
//        Actions_OLD.unselect_all();
      }
      if (action != null) {
        app.store.dispatch(action);
      }
    });

    //TODO: when cursor is over SVG element, in Firefox it gives mouse offset relative to that object
//    main_view_svg.onMouseMove.listen((MouseEvent ev) {
    draggable.onDrag.listen((DraggableEvent draggable_event) {
      MouseEvent ev = draggable_event.originalEvent;

      if (ev.ctrlKey || ev.shiftKey) {
        //XXX: need to take care to transform mouse coordinates in transformed SVG element
        Point<num> svg_point = util.untransformed_svg_point(view_svg, ev);
        var action = main_view
            ? actions.MainViewSelectionBoxSizeChanged(svg_point)
            : actions.SideViewSelectionBoxSizeChanged(svg_point);
        app.store.dispatch(action);
//        Actions_OLD.selection_box_size_changed(svg_point);
      }
    });

//    main_view_svg.onMouseUp.listen((MouseEvent ev) {
    draggable.onDragEnd.listen((DraggableEvent draggable_event) {
      var action = main_view ? actions.MainViewSelectionBoxRemove() : actions.SideViewSelectionBoxRemove();
      app.store.dispatch(action);
//      Actions_OLD.remove_selection_box();
    });
  }

  render(Model model) {
    this.root_element.children.clear();

    if (model.has_error()) {
      this.root_element.children.addAll([this.error_message_pane]);
      this.error_message_component.render(model.error_message);
    } else {
      this.root_element.children.add(this.design_above_footer_pane);
      this.root_element.children.add(this.footer_separator);
      this.root_element.children.add(this.footer_element);

//      var react_svg_pan_zoom_side = UncontrolledReactSVGPanZoom(
//        {
//          'width': '100%',
//          'height': '100%',
//        },
//        (Dom.svg()
//          ..id = 'side-view-svg'
//          ..width = '100%'
//          ..height = '100%')(
//          (DesignSide()..store = app.model.dna_design.helices_store)(),
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
//          (DesignMain()..store = app.model)(),
//        ),
//      );
//      react_dom.render(react_svg_pan_zoom_main, this.main_pane);

      react_dom.render(
        ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignSide()(),
          ),
        ),
        querySelector('#$SIDE_VIEW_SVG_VIEWPORT_GROUP'),
      );

      react_dom.render(
        ErrorBoundary()(
          (ReduxProvider()..store = app.store)(
            ConnectedDesignMain()(),
          ),
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

//      react_dom.render(
//          (DesignFooter()..mouseover_datas = app.model.ui_model.mouseover_datas)(), this.footer_element);

      if (!svg_panzoom_has_been_set_up) {
        setup_svg_panzoom_js();
        svg_panzoom_has_been_set_up = true;
      }
    }
  }

  add_shadow_filter(svg.SvgSvgElement elt) {
    // https://stackoverflow.com/a/6094674
    var drop_shadow = [
      svg.FEGaussianBlurElement()
        ..attributes = {
//          'in': 'SourceAlpha',
          'stdDeviation': '2.5',
        },
      svg.FEMergeElement()
        ..children = [
          svg.FEMergeNodeElement(),
          svg.FEMergeNodeElement()..attributes = {'in': "SourceGraphic"},
        ],
    ];

    var defns = svg.DefsElement()
      ..children = [
        svg.FilterElement()
          ..children = drop_shadow
          ..attributes = {
            'id': 'shadow',
            'filterUnits': 'userSpaceOnUse',
            'x': '-300%',
            'y': '-300%',
            'width': '900%',
            'height': '900%',
          }
      ];
    elt.children.add(defns);
  }

  side_view_mouse_leave_update_mouseover() {
    app.store.dispatch(actions.SideViewMousePositionRemove());
  }

  side_view_update_mouseover(MouseEvent event) {
    if (!(event.ctrlKey || event.shiftKey || event.altKey)) {
      app.store.dispatch(actions.SideViewMousePositionRemove());
      return;
    }

    Point<num> mouse_point = util.untransformed_svg_point(side_view_svg, event);
    Point<num> svg_coord = util.transform_mouse_coord_to_svg_current_panzoom_side(mouse_point);
//  Point<num> svg_coord = util.transform_mouse_coord_to_svg_current_panzoom_side(event.offset);

    if (DEBUG_PRINT_SIDE_VIEW_MOUSE_POSITION) {
      Point<num> pan = util.current_pan_side();
      num zoom = util.current_zoom_side();
      print('mouse event: '
          'x = ${event.offset.x},   '
          'y = ${event.offset.y},   '
          'pan = (${pan.x.toStringAsFixed(2)}, ${pan.y.toStringAsFixed(2)}),   '
          'zoom = ${zoom.toStringAsFixed(2)},   '
          'svg_x = ${svg_coord.x.toStringAsFixed(2)},   '
          'svg_y = ${svg_coord.y.toStringAsFixed(2)},   ');
    }

    app.store.dispatch(actions.SideViewMousePositionUpdate(svg_coord));
  }
}

class ErrorMessageComponent {
  DivElement root_element;

//  ErrorMessageStore error_message_store;

  ErrorMessageComponent(this.root_element) {
    this.root_element.attributes = {'class': 'error-message'};
//    this.error_message_store.listen((_) => this.render());
  }

  render(String error_message) {
    this.root_element.children.clear();
    if (error_message != null && error_message.length > 0) {
      var pre = PreElement();
      var escaper = HtmlEscape();
      var escaped_error_message = escaper.convert(error_message);
      pre.setInnerHtml(escaped_error_message);
      this.root_element.children.add(pre);
    }
  }
}
