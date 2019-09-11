@JS()
library view;

import 'dart:html';

import 'package:js/js.dart';
import 'package:scadnano/src/view_design.dart';

import 'json_serializable.dart' as json;
import 'view_menu.dart';
import 'view_editor.dart';
import 'app.dart';
import 'model.dart';
import 'constants.dart' as constants;

//TODO: display message while app is loading so it looks like something is happening

@JS(constants.js_function_name_setup_svg_panzoom)
external setup_svg_panzoom_js();

@JS(constants.js_function_name_setup_splits)
external setup_splits(bool show_editor);

@JS(constants.js_function_name_sdrag)
external sdrag_js();

/// Most views clear out their root element on each render, but View is a little special, so some
/// elements are put in place in the DOM in the constructor and never moved again. It is expected that
/// only one View object is ever created during the lifetime of the app. (in particular we should not need
/// to call setup_splits() more than once).
class View extends ReactiveComponent {
  final DivElement root_element;

  DivElement nonmenu_panes_container_element = DivElement()..attributes = {'id': 'nonmenu-panes-container'};
  DivElement menu_element = DivElement()..attributes = {'id': 'menu'};
  DivElement design_element = DivElement()..attributes = {'id': 'design-pane'};
  DivElement design_editor_separator = DivElement()..attributes = {'id': 'design-editor-separator', 'class': 'draggable-separator'};
  DivElement editor_element = DivElement()..attributes = {'id': 'editor-pane'};

  DesignViewComponent design_view;
  MenuViewComponent menu_view;
  EditorViewComponent editor_view;

  bool currently_showing_editor = app.model.show_editor;

//  split.Splitter splitter;

  View(this.root_element) {
    this.root_element.children.add(menu_element);
    this.root_element.children.add(DivElement()..attributes = {'class': 'fixed-separator'});
    this.root_element.children.add(this.nonmenu_panes_container_element);

    this.nonmenu_panes_container_element.children.add(design_element);

    this.menu_view = MenuViewComponent(menu_element);
    this.design_view = DesignViewComponent(design_element);
    this.editor_view = EditorViewComponent(editor_element);

    setup_splits(app.model.show_editor);
    this.listen(app.model);
  }

  /// This should be called whenever app.model is set to a new object,
  /// to redraw the entire app. It should NOT be called when the model changes
  /// in place. Instead, individual view elements should be notified as needed,
  /// using the notifier streams defined in Controller.
  render() {
    this.update_showing_editor();
    // now re-render components in place
    this.menu_view.render();
    this.design_view.render();

    if (app.model.show_editor) {
      this.editor_view.render();
    }
  }

  update_showing_editor() {

    //TODO: Firefox won't let editor pane shrink (when pan separater is dragged) to hide text; Chrome puts a scrollbar
    // at the bottom when that happens and lets the editor pane shrink arbitrarily (which is the desired behavior)

    if (!this.currently_showing_editor && app.model.show_editor) {
      this.nonmenu_panes_container_element.children.add(design_editor_separator);
      this.nonmenu_panes_container_element.children.add(editor_element);
      this.currently_showing_editor = true;
      setup_splits(app.model.show_editor);
      this.editor_view.render();

    } else if (this.currently_showing_editor && !app.model.show_editor) {
      this.nonmenu_panes_container_element.children.remove(design_editor_separator);
      this.nonmenu_panes_container_element.children.remove(editor_element);
      this.currently_showing_editor = false;
      setup_splits(app.model.show_editor);
      this.editor_view.render();
    }


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
