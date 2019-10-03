@JS()
library view_design;

import 'dart:convert';
import 'dart:html';
import 'dart:svg' as svg;

import 'package:js/js.dart';
import 'package:over_react/react_dom.dart' as react_dom;
import 'package:scadnano/src/model/model.dart';

//import 'react_svg_pan_zoom.dart';
import '../app.dart';
import 'view.dart';
import 'design_side.dart';

//import 'main.dart';
import 'design_main.dart';
import 'design_footer.dart';

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

    var side_view_svg = svg.SvgSvgElement()
      ..attributes = {
        'id': SIDE_VIEW_SVG_ID,
        'width': '100%',
        'height': '100%',
      };
    var main_view_svg = svg.SvgSvgElement()
      ..attributes = {
        'id': MAIN_VIEW_SVG_ID,
        'width': '100%',
        'height': '100%',
      };
    add_shadow_filter(main_view_svg);

    var side_view_svg_viewport = svg.GElement()..attributes = {'id': SIDE_VIEW_SVG_VIEWPORT_GROUP};
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

    app.model.design_or_error_store.listen((_) => this.render());
  }

  render() {
    //TODO: add MODES element to right side
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
            ..mouseover_data_store = app.model.main_view_ui_model.mouse_over_store)(),
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
    var drop_shadow1 = [
      svg.FEGaussianBlurElement()
        ..attributes = {
          'in': 'SourceAlpha',
          'stdDeviation': '1',
        },
      svg.FEComponentTransferElement()
        ..children = [
          svg.FEFuncAElement()
            ..attributes = {
              'type': "linear",
              'slope': "0.9",
            },
        ],
      svg.FEMergeElement()
        ..children = [
          svg.FEMergeNodeElement(),
          svg.FEMergeNodeElement()..attributes = {'in': "SourceGraphic"},
        ],
    ];


//    <feOffset result="offOut" in="SourceAlpha" dx="-5" dy="-5" />
//    <feGaussianBlur result="blurOut" in="offOut" stdDeviation="3" />
//    <feBlend in="SourceGraphic" in2="blurOut" mode="normal" />

    // https://codepen.io/andyshora/pen/vRRdRd
    /*
    <filter id="dropshadow" x="-2" y="-2" width="200" height="200">
      <feGaussianBlur  stdDeviation="1"/>
    </filter>
     */
    var drop_shadow2 = [
      svg.FEGaussianBlurElement()
        ..attributes = {
          'stdDeviation': '0.5',
        },
    ];

    //https://www.w3schools.com/graphics/svg_feoffset.asp
    /*
<svg height="120" width="120">
  <defs>
    <filter id="f1" x="0" y="0" width="200%" height="200%">
      <feOffset result="offOut" in="SourceGraphic" dx="20" dy="20" />
      <feBlend in2="offOut" in="SourceGraphic" mode="normal" />
    </filter>
  </defs>
  <rect width="90" height="90" stroke="green" stroke-width="3"
  fill="yellow" filter="url(#f1)" />
</svg>
     */
    var drop_shadow3 = [
      svg.FEOffsetElement()..attributes = {'result': 'offOut', 'in': 'SourceGraphic', 'dx': '0', 'dy': '0'},
      svg.FEBlendElement()..attributes = {'in2': 'offOut', 'in': 'SourceGraphic', 'mode': 'normal'},
    ];

    var defns = svg.DefsElement()
      ..children = [
        svg.FilterElement()
          ..children = drop_shadow2
          ..attributes = {
            'id': 'shadow',
            'x': '-200%',
            'y': '-100%',
            'width': '500%',
            'height': '500%',
          }
      ];
    //XXX: if we want to use a filter, uncomment the next line
    elt.children.add(defns);
  }
/*
  <feGaussianBlur in="SourceAlpha" stdDeviation="3"/> <!-- stdDeviation is how much to blur -->
  <feOffset dx="2" dy="2" result="offsetblur"/> <!-- how much to offset -->
  <feComponentTransfer>
    <feFuncA type="linear" slope="0.5"/> <!-- slope is the opacity of the shadow -->
  </feComponentTransfer>
  <feMerge>
    <feMergeNode/> <!-- this contains the offset blurred image -->
    <feMergeNode in="SourceGraphic"/> <!-- this contains the element that the filter is applied to -->
  </feMerge>
   */
/* from https://gist.github.com/redblobgames/6851dc787241e390c241cd9484b16e4d
  <defs>
    <filter id="drop-shadow" x="-100%" y="-100%" width="300%" height="300%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="2"/>
      <feOffset dx="5" dy="5" result="offsetblur"/>
      <feFlood flood-color="#000000"/>
      <feComposite in2="offsetblur" operator="in"/>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
   */
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
