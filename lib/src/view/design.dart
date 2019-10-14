@JS()
library view_design;

import 'dart:convert';
import 'dart:html';
import 'dart:svg' as svg;

import 'package:js/js.dart';
import 'package:over_react/react_dom.dart' as react_dom;

import '../dispatcher/actions.dart';
import '../model/model.dart';
import '../model/selectable.dart';
import '../app.dart';
import 'view.dart';
import 'design_side.dart';
import '../util.dart' as util;
import 'design_main.dart';
import 'design_footer.dart';

const DEBUG_PRINT_SIDE_VIEW_MOUSE_POSITION = false;
//const DEBUG_PRINT_SIDE_VIEW_MOUSE_POSITION = true;

const FOOTER_ID = 'design-footer-mouse-over';
const MODES_ID = 'design-mode-buttons';
const SIDE_VIEW_SVG_VIEWPORT_GROUP = 'side-view-svg-viewport';
const MAIN_VIEW_SVG_VIEWPORT_GROUP = 'main-view-svg-viewport';
const SIDE_VIEW_SVG_ID = 'side-view-svg';
const MAIN_VIEW_SVG_ID = 'main-view-svg';

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

  Model model;

  DesignViewComponent(this.root_element, this.model) {
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
      side_view_update_mouseover(side_view_svg, event);
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

    this.error_message_component = ErrorMessageComponent(error_message_pane, this.model.error_message_store);

    side_pane.children.add(side_view_svg);
    main_pane.children.add(main_view_svg);

    handle_mouse_events(main_view_svg);

    app.model.design_or_error_store.listen((_) => this.render());
  }

  void handle_mouse_events(svg.SvgSvgElement main_view_svg) {
    main_view_svg.onMouseDown.listen((ev) {
      if (ev.ctrlKey) {
        Actions.create_selection_box_toggling(ev.offset);
      } else if (ev.shiftKey) {
        Actions.create_selection_box_selecting(ev.offset);
      } else if (ev.button == 0) {
        // detects left mouse button: https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/button
        Actions.remove_all_selections();
      }
    });

    //TODO: when cursor is over SVG element, in Firefox it gives mouse offset relative to that object
    main_view_svg.onMouseMove.listen((ev) {
      if (ev.ctrlKey || ev.shiftKey) {
        //XXX: need to take care to transform mouse coordinates in transformed SVG element
        Point<num> svg_point = util.untransformed_svg_point(main_view_svg, ev);
        Actions.selection_box_size_changed(svg_point);
      }
    });

    main_view_svg.onMouseUp.listen((ev) {
      Actions.remove_selection_box();
    });
  }

  render() {
    this.root_element.children.clear();

    if (this.model.has_error()) {
      this.root_element.children.addAll([this.error_message_pane]);
      this.error_message_component.render();
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
          (DesignSide()
            ..store = app.model.dna_design.helices_store
            ..mouseover_data_store = app.model.main_view_ui_model.mouse_over_store
            ..side_view_mouse_position_store = app.model.side_view_ui_model.side_view_mouse_position_store
            ..grid = app.model.dna_design.grid)(),
          querySelector('#$SIDE_VIEW_SVG_VIEWPORT_GROUP'));

      react_dom.render((DesignMain()..store = app.model)(), querySelector('#$MAIN_VIEW_SVG_VIEWPORT_GROUP'));

      react_dom.render(
          (DesignFooter()..store = app.model.main_view_ui_model.mouse_over_store)(), this.footer_element);

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
}

class ErrorMessageComponent {
  DivElement root_element;
  ErrorMessageStore error_message_store;

  ErrorMessageComponent(this.root_element, this.error_message_store) {
    this.root_element.attributes = {'class': 'error-message'};
    this.error_message_store.listen((_) => this.render());
  }

  render() {
    this.root_element.children.clear();
    if (this.error_message_store.has_error()) {
      var pre = PreElement();
      var escaper = HtmlEscape();
      var escaped_error_message = escaper.convert(this.error_message_store.error_message);
      pre.setInnerHtml(escaped_error_message);
      this.root_element.children.add(pre);
    }
  }
}

side_view_mouse_leave_update_mouseover() {
  Actions.remove_side_view_mouse_position();
}

side_view_update_mouseover(svg.SvgSvgElement side_view_svg, MouseEvent event) {
  if (!event.ctrlKey) {
    Actions.remove_side_view_mouse_position();
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

  Actions.update_side_view_mouse_position(svg_coord);
}
