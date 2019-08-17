import 'dart:html';
import 'dart:svg' as svg;
import 'dart:js';

import 'package:split/split.dart' as split;

import 'view_side.dart';
import 'view_main.dart';
import 'view_menu.dart';
import 'view_editor.dart';
import 'app.dart';
import 'model.dart';
import 'constants.dart' as constants;

//TODO: let user execute Python script in editor creating DNADesign (consider Brython, Transcypt, or Skulpt)

//TODO: display message while app is loading so it looks like something is happening

class View {
  DivElement dart_root_element;
  DivElement panes_container_element;
  DivElement editor_pane;

  MenuViewElement menu_view;
  SideViewComponent side_view;
  MainViewComponent main_view;
  EditorViewComponent editor_view;

  svg.GElement side_view_svg_viewport;
  svg.GElement main_view_svg_viewport;

  split.Splitter splitter;

  View() {
    this.dart_root_element = querySelector('.top-container');
    var menu_element = DivElement()..attributes = {'id': 'menu'};
    this.dart_root_element.children.add(menu_element);
    this.dart_root_element.children.add(DivElement()..attributes = {'class': 'menu-separator'});
    this.panes_container_element = DivElement()..attributes = {'class': 'panes-container'};
    this.dart_root_element.children.add(this.panes_container_element);

    var side_pane = DivElement()..attributes = {'id': 'side-pane', 'class': 'split'};
    var main_pane = DivElement()..attributes = {'id': 'main-pane', 'class': 'split'};
    this.editor_pane = DivElement()..attributes = {'id': 'editor-pane', 'class': 'split'};

    var side_view_svg = svg.SvgSvgElement()
      ..attributes = {
        'id': 'side-view-svg',
        'width': '100%',
        'height': '100%',
      };
    var main_view_svg = svg.SvgSvgElement()
      ..attributes = {
        'id': 'main-view-svg',
        'width': '100%',
        'height': '100%',
      };
    side_pane.children.add(side_view_svg);
    main_pane.children.add(main_view_svg);

    this.side_view_svg_viewport = svg.GElement()..attributes = {'id': 'side-view-svg-viewport'};
    this.main_view_svg_viewport = svg.GElement()..attributes = {'id': 'main-view-svg-viewport'};
    side_view_svg.children.add(side_view_svg_viewport);
    main_view_svg.children.add(main_view_svg_viewport);

    var side_view_dummy_elt = svg.CircleElement()
      ..attributes = {'id': 'dummy-elt-side-view', 'r': '100', 'cx': '100', 'cy': '50', 'fill': 'white'};
    var main_view_dummy_elt = svg.CircleElement()
      ..attributes = {'id': 'dummy-elt-main-view', 'r': '200', 'cx': '100', 'cy': '100', 'fill': 'white'};
    side_view_svg_viewport.children.add(side_view_dummy_elt);
    main_view_svg_viewport.children.add(main_view_dummy_elt);

    this.panes_container_element.children.add(side_pane);
    this.panes_container_element.children.add(main_pane);
    if (app.model.show_editor) {
      this.panes_container_element.children.add(this.editor_pane);
    }

    // These must be called after elements are added to DOM.
    this.setup_splits();
    this.setup_svg_panzoom();

    this.menu_view = MenuViewElement(menu_element);
    this.side_view = SideViewComponent(side_view_svg_viewport);
    this.main_view = MainViewComponent(main_view_svg_viewport);
    this.editor_view = EditorViewComponent(editor_pane);
  }

  /*
  <div id="menu"></div>

  <div class="menu-separator" id="menu-separator"></div>

  <div class="panes-container">

    <div class="split" id="side-pane">
        <svg id="side-view-svg" width="100%" height="100%" style="touch-action: none;">
            <g id="side-view-svg-viewport">
                <circle id="dummy-elt-side-view" r="100" cx="100" cy="50" fill="white">
                    dummy elt for svg-pan-zoom not to have a divide-by-0 error due to 0 width/height
                </circle>
            </g>
        </svg>
    </div>

    <div class="split" id="main-pane">
        <svg id="main-view-svg" width="100%" height="100%" style="touch-action: none;">
            <g id="main-view-svg-viewport">
                <circle id="dummy-elt-main-view" r="200" cx="100" cy="100" fill="white">
                    dummy elt for svg-pan-zoom not to have a divide-by-0 error due to 0 width/height
                </circle>
            </g>
        </svg>
    </div>

    <div class="split" id="editor-pane">
        <div id="controls">
            <label for="theme">Theme:</label>
            <select id="theme"></select>
        </div>
        <div id="editor"></div>
        <p id="footer"></p>
    </div>
   */

  setup_splits() {
    var side_pane = querySelector('#side-pane');
    var main_pane = querySelector('#main-pane');

    if (this.splitter != null) {
      this.splitter.destroy();
    }

    if (app.model.show_editor) {
      this.splitter = split.fixedSplit([side_pane, main_pane, this.editor_pane],
          gutterSize: 10, sizes: [10, 50, 40], minSize: [0, 0, 0]);
    } else {
      this.splitter = split.fixedSplit([side_pane, main_pane], gutterSize: 10, sizes: [10, 90], minSize: [0, 0]);
    }
  }

  setup_svg_panzoom() {
    JsFunction js_setup_svg_panzoom = context[constants.js_function_name_setup_svg_panzoom];
    js_setup_svg_panzoom.apply([]);
  }

  /// This should be called whenever app.model is set to a new object,
  /// to redraw the entire app. It should NOT be called when the model changes
  /// in place. Instead, individual view elements should be notified as needed,
  /// using the notifier streams defined in Controller.
  render() {
    // These need to be recreated in case we got a new model.
    this.side_view = SideViewComponent(this.side_view_svg_viewport);
    this.main_view = MainViewComponent(this.main_view_svg_viewport);

    this.menu_view.render();
    this.side_view.render();
    this.main_view.render();
    this.editor_view.render();
    app.controller.setup_subscriptions();
  }

  show_editor(bool show) {
    if (show) {
      if (!this.panes_container_element.children.contains(this.editor_view.element)) {
        this.panes_container_element.children.add(this.editor_view.element);
      }
    } else {
      if (this.panes_container_element.children.contains(this.editor_view.element)) {
        this.panes_container_element.children.remove(this.editor_view.element);
      }
    }
    this.setup_splits();
  }
}

/// A Component that can listen to a change in some part of the model
/// and re-render all of itself in response.
abstract class ReactiveComponent {
  render();

  listen<T>(ChangeNotifier<T> change_notifier) {
    change_notifier.listen_for_change((_) => this.render());
  }
}
