import 'dart:html';

import 'package:split/split.dart' as split;

import 'view_side.dart';
import 'view_main.dart';
import 'view_menu.dart';
import 'view_editor.dart';
import 'app.dart';

//TODO: put code editor in browser and let user execute Python script creating DNADesign (consider Brython, Transcypt, or Skulpt)

//TODO: display message while app is loading so it looks like something is happening

class View {
  MenuViewElement menu_view;
  SideViewComponent side_view;
  MainViewComponent main_view;
  EditorViewComponent editor_view;

  split.Splitter splitter;

  View() {
    //TODO: figure out why we can't make a new one every time we re-render
    this.editor_view = EditorViewComponent();
    this.setup_splits();
  }

  setup_splits() {
    var side_pane = querySelector('#side-pane');
    var main_pane = querySelector('#main-pane');
    var editor_pane = querySelector('#editor-pane');
    this.splitter = split.fixedSplit([side_pane, main_pane, editor_pane],
        gutterSize: 10, sizes: [10, 50, 40], minSize: [0, 0, 0]);
  }

  /// This should be called whenever app.model is set to a new object,
  /// to redraw the entire app. It should NOT be called when the model changes
  /// in place. Instead, individual view elements should be notified as needed,
  /// using the notifier streams defined in Controller.
  render() {
    this.render_menu_view();
    this.render_side_view();
    this.render_main_view();
    this.render_editor_view();
    app.controller.setup_subscriptions();
  }

  render_menu_view() {
    this.menu_view = MenuViewElement();
    this.menu_view.render();
  }

  render_side_view() {
    this.side_view = SideViewComponent();
    this.side_view.render();
  }

  render_main_view() {
    this.main_view = MainViewComponent();
    this.main_view.render();
  }

  render_editor_view() {
//    this.editor_view = EditorViewComponent();
    this.editor_view.render();
  }
}
