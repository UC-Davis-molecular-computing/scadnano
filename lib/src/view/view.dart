@JS()
library view;

import 'dart:html';

import 'package:js/js.dart';
import 'package:over_react/react_dom.dart' as react_dom;
import 'package:path/path.dart' as path;
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/components.dart' as over_react_components;
import '../view/edit_and_select_modes.dart';

import '../state/app_state.dart';
import 'design.dart';
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
const DESIGN_AND_MODES_BUTTONS_CONTAINER_ID = 'design-and-modes-buttons-container';
const EDIT_AND_SELECT_MODES_ID = 'modes-buttons';

const FIXED_VERTICAL_SEPARATOR = 'fixed-vertical-separator';
const FIXED_HORIZONTAL_SEPARATOR = 'fixed-horizontal-separator';

/// Most views clear out their root element on each render, but View is a little special, so some
/// elements are put in place in the DOM in the constructor and never moved again. It is expected that
/// only one View object is ever created during the lifetime of the app. (in particular we should not need
/// to call setup_splits() more than once).
class View {
  final DivElement root_element;

  DivElement design_and_modes_buttons_container_element = DivElement()
    ..attributes = {'id': DESIGN_AND_MODES_BUTTONS_CONTAINER_ID};
  DivElement edit_and_select_modes_element = DivElement()..attributes = {'id': EDIT_AND_SELECT_MODES_ID};
  DivElement menu_element = DivElement()..attributes = {'id': MENU_ID};
  DivElement design_element = DivElement()..attributes = {'id': DESIGN_ID};
  DivElement design_editor_separator = DivElement()
    ..attributes = {'id': 'design-editor-separator', 'class': 'draggable-separator'};
  DivElement editor_element = DivElement()..attributes = {'id': EDITOR_ID};

  DesignViewComponent design_view;
  EditorViewComponent editor_view;

  bool currently_showing_editor;

  View(this.root_element) {
    setup_file_drag_and_drop_listener(root_element);

    currently_showing_editor = app.state.ui_state.show_editor;

    this.root_element.children.add(menu_element);
    var menu_design_separator = DivElement()..attributes = {'class': FIXED_HORIZONTAL_SEPARATOR};
    this.root_element.children.add(menu_design_separator);
    this.root_element.children.add(this.design_and_modes_buttons_container_element);
    // DEBUG the virtual canvas for svg-png-caching, uncomment this, used in utils.dart
    // this.root_element.children.add(CanvasElement(width: 100, height: 100)..id='canvas-dev');

    this.design_and_modes_buttons_container_element.children.add(design_element);
    var design_mode_separator = DivElement()..attributes = {'class': FIXED_VERTICAL_SEPARATOR};
    this.design_and_modes_buttons_container_element.children.add(design_mode_separator);

    this.design_and_modes_buttons_container_element.children.add(edit_and_select_modes_element);

    this.design_view = DesignViewComponent(design_element);
  }

  render(AppState state) {
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

    react_dom.render(
      over_react_components.ErrorBoundary()(
        (ReduxProvider()..store = store)(
          ConnectedEditAndSelectModes()(),
        ),
      ),
      this.edit_and_select_modes_element,
    );

    util.fit_and_center();
  }

//  update_showing_editor() {
//    //TODO: Firefox won't let editor pane shrink (when pan separator is dragged) to hide text;
//    // Chrome puts a scrollbar at the bottom when that happens and lets the editor pane shrink
//    // arbitrarily (which is the desired behavior)
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

    var dot_exts = constants.all_scadnano_file_extensions.map((ext) => '.' + ext).toList();
    var extensions_str = dot_exts.sublist(0, dot_exts.length-1).join(', ') + ', or ' + dot_exts.last;
    if (files.length > 1) {
      window.alert('More than one file dropped! Please drop only one ${extensions_str} file.');
      return;
    }

    var file = files.first;
    var filename = file.name;
    var ext = path.extension(filename);
    if (dot_exts.contains(ext)) {
      var confirm =
          app.state.has_error() || window.confirm('Are you sure you want to replace the current design?');

      if (confirm) {
        FileReader file_reader = new FileReader();
        //XXX: Technically to be clean Redux (or Elm architecture), this should be an Action,
        // and what is done in file_loaded should be another Action.
        file_reader.onLoad.listen((_) => scadnano_file_loaded(file_reader, filename));
        var err_msg = "error reading file: ${file_reader.error.toString()}";
        file_reader.onError.listen((_) => window.alert(err_msg));
        file_reader.readAsText(file);
      }
    } else {
      window.alert('scadnano does not support "${ext}" type files. Please drop a ${extensions_str} file.');
    }
  });
}
