@JS()
library view;

import 'package:web/web.dart';

import 'package:js/js.dart';
import 'package:over_react/react_dom.dart' as react_dom;
import 'package:path/path.dart' as path;
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/components.dart' as over_react_components;
import '../view/edit_and_select_modes.dart';

import '../state/app_state.dart';
import 'design.dart';
import 'menu.dart';
import 'oxview.dart';
import '../app.dart';
import '../util.dart' as util;
import '../middleware/local_storage.dart' as local_storage;

import '../constants.dart' as constants;

@JS(constants.js_function_name_setup_svg_panzoom)
external setup_svg_panzoom_js(void Function() svg_cache_callback,
    void Function(bool) dispatch_zoom_threshold_callback, num zoom_threshold);

@JS(constants.js_function_name_setup_splits)
external setup_splits(bool show_oxview);

@JS(constants.js_function_name_sdrag)
external sdrag_js();

const MENU_ID = 'menu';
const EDIT_MODE_ID = 'edit-mode';
const SELECT_MODE_ID = 'select-mode';
const DESIGN_ID = 'design-pane';
const OXVIEW_ID = 'oxview-pane';
const DESIGN_AND_MODES_BUTTONS_CONTAINER_ID = 'design-and-modes-buttons-container';
const NONMENU_PANES_CONTAINED_ID = 'nonmenu-panes-container';
const EDIT_AND_SELECT_MODES_ID = 'modes-buttons';

const FIXED_VERTICAL_SEPARATOR = 'fixed-vertical-separator';
const FIXED_HORIZONTAL_SEPARATOR = 'fixed-horizontal-separator';

/// Most views clear out their root element on each render, but View is a little special, so some
/// elements are put in place in the DOM in the constructor and never moved again. It is expected that
/// only one View object is ever created during the lifetime of the app. (in particular we should not need
/// to call setup_splits() more than once).
class View {
  final HTMLDivElement root_element;
  HTMLDivElement edit_and_select_modes_element = HTMLDivElement()
    ..setAttribute('id', EDIT_AND_SELECT_MODES_ID);
  HTMLDivElement menu_element = HTMLDivElement()..setAttribute('id', MENU_ID);
  HTMLDivElement nonmenu_panes_container_element = HTMLDivElement()
    ..setAttribute('id', NONMENU_PANES_CONTAINED_ID);
  HTMLDivElement design_element = HTMLDivElement()..setAttribute('id', DESIGN_ID);

  HTMLDivElement design_and_modes_buttons_container_element = HTMLDivElement()
    ..setAttribute('id', DESIGN_AND_MODES_BUTTONS_CONTAINER_ID)
    ..setAttribute('class', 'split');
  HTMLDivElement design_oxview_separator = HTMLDivElement()
    ..setAttribute('id', 'design-oxview-separator')
    ..setAttribute('class', 'draggable-separator');

  late DesignViewComponent design_view;
  late OxviewViewComponent oxview_view;

  bool currently_showing_oxview = false;

  View(this.root_element) {
    setup_file_drag_and_drop_listener(root_element);

    this.root_element.append(menu_element);
    var menu_design_separator = HTMLDivElement()..setAttribute('class', FIXED_HORIZONTAL_SEPARATOR);
    this.root_element.append(menu_design_separator);
    this.root_element.append(this.nonmenu_panes_container_element);

    this.nonmenu_panes_container_element.append(this.design_and_modes_buttons_container_element);

    this.design_and_modes_buttons_container_element.append(design_element);
    var design_mode_separator = HTMLDivElement()..setAttribute('class', FIXED_VERTICAL_SEPARATOR);
    this.design_and_modes_buttons_container_element.append(design_mode_separator);

    this.design_and_modes_buttons_container_element.append(edit_and_select_modes_element);

    this.design_view = DesignViewComponent(design_element);
    this.oxview_view = OxviewViewComponent();
    this.nonmenu_panes_container_element.append(design_oxview_separator);
    this.nonmenu_panes_container_element.append(this.oxview_view.div);

    this.update_showing_oxview();
  }

  render(AppState state) {
    this.update_showing_oxview();

    var store = app.store;

    react_dom.render(
      over_react_components.ErrorBoundary()(
        (ReduxProvider()..store = store)(
          set_menu_props(ConnectedMenu(), state)(),
        ),
      ),
      this.menu_element,
    );

    this.design_view.render(state);

    react_dom.render(
      over_react_components.ErrorBoundary()(
        (ReduxProvider()
          ..store = store)(set_edit_and_select_mode_props(ConnectedEditAndSelectModes(), state)()),
      ),
      this.edit_and_select_modes_element,
    );

    util.fit_and_center();
  }

  update_showing_oxview() {
    bool show_oxview = app.state.ui_state.show_oxview;
    if (!this.currently_showing_oxview && show_oxview) {
      this.design_oxview_separator.hidden = false;
      this.oxview_view.div.hidden = false;
      this.currently_showing_oxview = true;
      this.set_design_oxview_pane_widths();
      setup_splits(show_oxview);
    } else if (!show_oxview) {
      this.design_oxview_separator.hidden = true;
      this.oxview_view.div.hidden = true;
      if (this.currently_showing_oxview) {
        this.currently_showing_oxview = false;
        setup_splits(show_oxview);
      }
    }
  }

  set_design_oxview_pane_widths() {
    String design_width = local_storage.design_width();
    num oxview_width_int = 100.0 - num.parse(design_width.substring(0, design_width.length - 1));
    String oxview_width = '${oxview_width_int.toString()}%';
    design_and_modes_buttons_container_element.setAttribute('style', 'width: $design_width');
    this.oxview_view.div.setAttribute('style', 'width: $oxview_width');
  }
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
    if (files == null || files.isEmpty) {
      return;
    }

    var dot_exts = constants.all_scadnano_file_extensions.map((ext) => '.' + ext).toList();
    var extensions_str = dot_exts.sublist(0, dot_exts.length - 1).join(', ') + ', or ' + dot_exts.last;
    if (files.length > 1) {
      window.alert('More than one file dropped! Please drop only one ${extensions_str} file.');
      return;
    }

    var file = files.first;
    var filename = file.name;
    var ext = path.extension(filename);
    var ext_lower = ext.toLowerCase();
    if (dot_exts.contains(ext_lower)) {
      var confirm =
          app.state.has_error || window.confirm('Are you sure you want to replace the current design?');

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
