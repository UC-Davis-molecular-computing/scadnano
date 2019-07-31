import 'dart:html' as html;
import 'dart:math';

import 'view_side.dart';
import 'view_main.dart';
import 'view_menu.dart';
import 'panzoom.dart';
import 'app.dart';

//TODO: put code editor in browser and let user execute Python script creating DNADesign

class View {
  MenuViewElement menu_view;
  SideViewElement side_view;
  MainViewElement main_view;

  View() {
    this.render();
  }

  /// This should be called whenever app.model is set to a new object,
  /// to redraw the entire app. It should NOT be called when the model changes
  /// in place. Instead, individual view elements should be notified as needed,
  /// using the notifier streams defined in Controller.
  render() {
    this.render_menu_view();
    this.render_side_view();
    this.render_main_view();
    app.controller.set_view_elements(this.menu_view, this.side_view, this.main_view);
  }

  render_menu_view() {
    this.menu_view = MenuViewElement();
    this.menu_view.render();
  }

  render_side_view() {
    this.side_view = SideViewElement();
    var panzoomable_element = PanzoomableSvgElement(this.side_view.element, 'side-view-svg');
    var pane = html.querySelector('#left-pane');
    pane.children.clear();
    pane.children.add(panzoomable_element.element);
    this.side_view.render();
  }

  render_main_view() {
    this.main_view = MainViewElement();
    // This uses a strange starting translation because the upper left of helix 0 is the origin.
    var panzoomable_element = PanzoomableSvgElement(this.main_view.element, 'main-view-svg',
        init_translation: Point<num>(100, 30));
    var pane = html.querySelector('#right-pane');
    pane.children.clear();
    pane.children.add(panzoomable_element.element);
    this.main_view.render();
  }

}
