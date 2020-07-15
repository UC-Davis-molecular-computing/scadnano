@JS()
library view;

import 'dart:html';

import 'package:js/js.dart';
import 'package:over_react/react_dom.dart' as react_dom;
import 'package:path/path.dart' as path;
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/components.dart' as over_react_components;


import '../state/app_state.dart';
import 'design.dart';
import 'edit_mode.dart';
import 'select_mode.dart';
import 'menu.dart';
import 'editor.dart';
import '../app.dart';
import '../util.dart' as util;

import '../constants.dart' as constants;

@JS(constants.js_function_name_setup_svg_panzoom)
external setup_svg_panzoom_js(void Function() svg_cache_callback,
    void Function(bool) dispatch_zoom_threshold_callback, num zoom_threshold);

@JS(constants.js_function_name_setup_splits)
external setup_splits(bool show_editor);

@JS(constants.js_function_name_sdrag)
external sdrag_js();

const MENU_ID = 'menu';
const EDIT_MODE_ID = 'edit-mode';
const SELECT_MODE_ID = 'select-mode';
const DESIGN_ID = 'design-pane';
const EDITOR_ID = 'editor-pane';
const RIGHT_SIDE_PANES_CONTAINER_ID = 'right-side-panes-container';

const FIXED_VERTICAL_SEPARATOR = 'fixed-vertical-separator';
const FIXED_HORIZONTAL_SEPARATOR = 'fixed-horizontal-separator';

/// Most views clear out their root element on each render, but View is a little special, so some
/// elements are put in place in the DOM in the constructor and never moved again. It is expected that
/// only one View object is ever created during the lifetime of the app. (in particular we should not need
/// to call setup_splits() more than once).
class View {
  final DivElement root_element;

  DivElement right_side_panes_container_element = DivElement()..attributes = {'id': RIGHT_SIDE_PANES_CONTAINER_ID};
  DivElement menu_element = DivElement()..attributes = {'id': MENU_ID};
  DivElement design_element = DivElement()..attributes = {'id': DESIGN_ID};
  DivElement design_editor_separator = DivElement()
    ..attributes = {'id': 'design-editor-separator', 'class': 'draggable-separator'};
  DivElement editor_element = DivElement()..attributes = {'id': EDITOR_ID};

  DivElement edit_mode_element = DivElement()..attributes = {'id': EDIT_MODE_ID};
  DivElement select_mode_element = DivElement()..attributes = {'id': SELECT_MODE_ID};

  DesignViewComponent design_view;
  EditorViewComponent editor_view;

  bool currently_showing_editor;

  View(this.root_element) {
    setup_file_drag_and_drop_listener(root_element);

    currently_showing_editor = app.state.ui_state.show_editor;

    this.root_element.children.add(menu_element);
    var menu_design_separator = DivElement()..attributes = {'class': FIXED_HORIZONTAL_SEPARATOR};
    this.root_element.children.add(menu_design_separator);
    this.root_element.children.add(this.right_side_panes_container_element);

    this.right_side_panes_container_element.children.add(design_element);
    var design_mode_separator = DivElement()..attributes = {'class': FIXED_VERTICAL_SEPARATOR};
    this.right_side_panes_container_element.children.add(design_mode_separator);

    var modes_separator = DivElement()..attributes = {'class': FIXED_HORIZONTAL_SEPARATOR};
    this.right_side_panes_container_element.children.add(DivElement()
      ..id = 'modes-buttons'
      ..children = [edit_mode_element, modes_separator, select_mode_element]);

    this.design_view = DesignViewComponent(design_element);

    // IF(DEBUGING-SVG-PNG-CACHING)
    // var canvas = CanvasElement()..id = "canvas-dev";
    // this.root_element.children.add(canvas);
    // var img = ImageElement()..id = "img-dev";
    // this.root_element.children.add(img);

//    this.editor_view = EditorViewComponent(editor_element);

//    setup_splits(app.state.show_editor);
//    this.state.listen((_) => this.render());
//    this.render();
  }

  render(AppState state) {
//    this.update_showing_editor();

    var store = app.store;

    react_dom.render(
      over_react_components.ErrorBoundary()(
        (ReduxProvider()..store = store)(
          ConnectedMenu()(),
        ),
      ),
      this.menu_element,
    );

    this.design_view.render(state);

//    react_dom.render((EditMode()..store = app.state.edit_mode_store)(), this.edit_mode_element);

    react_dom.render(
      over_react_components.ErrorBoundary()(
        (ReduxProvider()..store = store)(
          ConnectedEditMode()(),
        ),
      ),
      this.edit_mode_element,
    );

    react_dom.render(
      over_react_components.ErrorBoundary()(
        (ReduxProvider()..store = store)(
          ConnectedSelectMode()(),
        ),
      ),
      this.select_mode_element,
    );

    util.fit_and_center();

//    react_dom.render(
//        (SelectMode()..select_mode_state = app.state.select_mode_store)(), this.select_mode_element);

//    if (app.state.show_editor) {
//      this.editor_view.render();
//    }
  }

//  update_showing_editor() {
//    //TODO: Firefox won't let editor pane shrink (when pan separater is dragged) to hide text; Chrome puts a scrollbar
//    // at the bottom when that happens and lets the editor pane shrink arbitrarily (which is the desired behavior)
//
//    if (!this.currently_showing_editor && app.state.show_editor) {
//      this.nonmenu_panes_container_element.children.add(design_editor_separator);
//      this.nonmenu_panes_container_element.children.add(editor_element);
//      this.currently_showing_editor = true;
//      setup_splits(app.state.show_editor);
//      this.editor_view.render();
//    } else if (this.currently_showing_editor && !app.state.show_editor) {
//      this.nonmenu_panes_container_element.children.remove(design_editor_separator);
//      this.nonmenu_panes_container_element.children.remove(editor_element);
//      this.currently_showing_editor = false;
//      setup_splits(app.state.show_editor);
//      this.editor_view.render();
//    }
//  }
}


setup_file_drag_and_drop_listener(Element drop_zone) {
  drop_zone.onDragOver.listen((event) {
    event.stopPropagation();
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
  });

  drop_zone.onDrop.listen((event) {
    event.stopPropagation();
    event.preventDefault();

    var files = event.dataTransfer.files;
    if (files.isEmpty) {
      return;
    }

    if (files.length > 1) {
      window.alert('More than one file dropped! Please drop only one .dna or .json file.');
      return;
    }

    var file = files.first;
    var filename = file.name;
    var ext = path.extension(filename);
    if (ext == '.dna' || ext == '.json') {
      var confirm =
          app.state.has_error() || window.confirm('Are you sure you want to replace the current design?');

      if (confirm) {
        FileReader file_reader = new FileReader();
        //XXX: Technically to be clean Flux (or Elm architecture), this should be an Action,
        // and what is done in file_loaded should be another Action.
        file_reader.onLoad.listen((_) => scadnano_file_loaded(file_reader, filename));
        var err_msg = "error reading file: ${file_reader.error.toString()}";
        file_reader.onError.listen((_) => window.alert(err_msg));
        file_reader.readAsText(file);
      }
    } else {
      window.alert('scadnano does not support "${ext}" type files. Please drop a .dna or .json file.');
    }
  });
}
