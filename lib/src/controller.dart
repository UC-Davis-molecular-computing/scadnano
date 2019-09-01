import 'dart:async';
import 'dart:html';
import 'dart:convert';

import 'package:path/path.dart' as path;

import 'model.dart';
import 'model_ui.dart';
import 'view_side.dart';
import 'app.dart';
import 'actions.dart';

/// Responsible for notifying view listeners of changes to the model,
/// and for dispatching actions to change the model (coming from View interactions, for example).
class Controller {
  ////////////////////////////////////////////////////////////////////////////
  // Notifiers that fire when Model is updated by an Action
  // Relevant parts of the view are subscribed to these to know when to re-render.

  final notifier_model_change = StreamController<Model>.broadcast();

  final notifier_helix_change = StreamController<Helix>.broadcast();

  final notifier_show_dna_change = StreamController<bool>.broadcast();

  final notifier_show_mismatches_change = StreamController<bool>.broadcast();

  // "Show Editor" boolean value changed (e.g., user clicks on "Show Editor Sequence" check)
  final notifier_show_editor_change = StreamController<bool>.broadcast();

  // Loaded filename is changed.
  final notifier_loaded_dna_filename = StreamController<String>.broadcast();

  // Boolean value of whether model has changed since last save is changed.
  final notifier_model_changed_since_save = StreamController<bool>.broadcast();

  // mouse over data (which helix/offset is the mouse over?) has changed.
  final notifier_mouse_over_data = StreamController<MouseOverData>.broadcast();

  // END Notifiers that fire when Model is updated by an Action
  ////////////////////////////////////////////////////////////////////////////

  Controller();

  setup_subscriptions() {
    this.subscribe_to_all_to_model_change_events();
    this.subscribe_to_all_action_causing_events();
  }

  //////////////////////////////////////////////////////////////////////////////
  // subscribe view to model changes
  // This is handled automatically in React and Elm. If it is not a big performance hit,
  // should consider switching to React to avoid having to do this manually.

  //XXX: I attempted to be more object-oriented and have each view component register itself to listen.
  // Unfortunately this doesn't work because some View components get tossed out and replaced with new ones.
  // For example, when the whole View re-renders when a new .dna file is loaded, a new MainViewComponent is
  // created to replace the old one.
  // If MainViewComponent registers itself to listen to the model (e.g., for the "Show DNA" Boolean
  // changing), then the old MainViewComponent is still around (even though not shown in the DOM anymore),
  // and it still gets notified whenever the model changes. This is wasteful and also causes bugs since it
  // still has references to old parts of the model (e.g., old Strands).
  //
  // So I think it's okay to have the notifiers reside in the part of the Model they notify about, but
  // it's crucial that the listener callbacks below reference app.view.something, rather than this.something in
  // a view component, so that the notifications are always sent only to the *current* view.

  subscribe_to_all_to_model_change_events() {
    this.subscribe_to_model_changed();
    this.subscribe_to_show_dna();
    this.subscribe_to_show_mismatches();
    this.subscribe_to_show_editor();
    this.subscribe_to_model_changed_since_last_save_changed();
  }

  // for when something at the top level of the Model changes and the whole View must be re-rendered
  subscribe_to_model_changed() {
    this.notifier_model_change.stream.listen((_) {
      app.view.render();
    });
  }

  subscribe_to_show_dna() {
    this.notifier_show_dna_change.stream.listen((_) {
      app.view.design_view.main_view.render_dna_sequences();
    });
  }

  subscribe_to_show_mismatches() {
    this.notifier_show_mismatches_change.stream.listen((_) {
      app.view.design_view.main_view.render_mismatches();
    });
  }

  subscribe_to_show_editor() {
    this.notifier_show_editor_change.stream.listen((_) {
      app.view.update_showing_editor();
    });
  }

  subscribe_to_model_changed_since_last_save_changed() {
    this.notifier_model_changed_since_save.stream.listen((_) {
      app.view.menu_view.render_file_buttons();
    });
  }

  // END subscribe view to model changes
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // subscribe controller to events that result in dispatching Actions (e.g., user interaction)

  subscribe_to_all_action_causing_events() {
    this.subscribe_to_user_clicks_side_view_helix();
    //TODO: allow helices to be made longer or shorter

    this.subscribe_to_user_clicks_show_dna_checkbox();
    this.subscribe_to_user_clicks_show_mismatches_checkbox();
    this.subscribe_to_user_clicks_show_editor_checkbox();
    this.subscribe_to_save_file_button_pressed();
    this.subscribe_to_load_file_button_pressed();
    this.subscribe_to_script_load_file_button_pressed();

    this.subscribe_to_compile_button_pressed();

    this.subscribe_to_editor_change_events();
  }

  subscribe_to_user_clicks_side_view_helix() {
    for (var helix_side_view_elt in app.view.design_view.side_view.helix_elts_map.values) {
      helix_side_view_elt.circle.onClick.listen((MouseEvent e) {
        if (e.ctrlKey) this.handle_click_side_view(helix_side_view_elt);
      });
      helix_side_view_elt.text.onClick.listen((MouseEvent e) {
        if (e.ctrlKey) this.handle_click_side_view(helix_side_view_elt);
      });
    }
  }

  handle_click_side_view(HelixSideViewComponent helix_side_view_elt) {
    //TODO: detect if any strands are on this helix and warn before deleting
    //TODO: give option to user to remove only substrands on this helix and split the remaining substrands
    var helix = helix_side_view_elt.helix;
    if (helix.used) {
      if (helix.has_substrands()) {
        // implement this
      }
    }
    var use = !helix.used;
    var idx = helix.idx;
    if (idx < 0) {
      idx = app.model.dna_design.used_helices.length;
    }
    var helix_action = HelixUseAction(use, helix, idx);
    app.send_action(helix_action);
  }

  subscribe_to_user_clicks_show_dna_checkbox() {
    app.view.menu_view.show_dna_checkbox.onChange.listen((_) {
      app.send_action(ShowDNAAction(app.view.menu_view.show_dna_checkbox.checked));
    });
  }

  subscribe_to_user_clicks_show_mismatches_checkbox() {
    app.view.menu_view.show_mismatches_checkbox.onChange.listen((_) {
      app.send_action(ShowMismatchesAction(app.view.menu_view.show_mismatches_checkbox.checked));
    });
  }

  subscribe_to_user_clicks_show_editor_checkbox() {
    app.view.menu_view.show_editor_checkbox.onChange.listen((_) {
      app.send_action(ShowEditorAction(app.view.menu_view.show_editor_checkbox.checked));
    });
  }

  subscribe_to_compile_button_pressed() {
    app.view.editor_view.compile_button.onClick.listen((_) async {
      app.send_action(CompileAction());
    });
  }

  subscribe_to_save_file_button_pressed() {
    app.view.menu_view.save_button.onClick.listen((_) async {
      await save_file();
      app.send_action(AlertFileSavedAction());
    });
  }

  subscribe_to_script_save_file_button_pressed() {
    app.view.editor_view.save_button.onClick.listen((_) async {
      await script_save_file();
    });
  }

  subscribe_to_load_file_button_pressed() {
    // this is needed in case the user selects the same filename, to reload the file in case it has changed.
    // If not, then the onChange event won't fire and we won't reload the file.
    var file_chooser = app.view.menu_view.file_chooser;
    file_chooser.onClick.listen((_) {
      file_chooser.value = null;
    });
    file_chooser.onChange.listen((_) {
      request_load_file_from_file_chooser(file_chooser);
    });
  }

  subscribe_to_script_load_file_button_pressed() {
    // this is needed in case the user selects the same filename, to reload the file in case it has changed.
    // If not, then the onChange event won't fire and we won't reload the file.
    var file_chooser = app.view.editor_view.file_chooser;
    file_chooser.onClick.listen((_) {
      file_chooser.value = null;
    });
    file_chooser.onChange.listen((_) {
      request_script_load_file_from_file_chooser(file_chooser);
    });
  }

  subscribe_to_editor_change_events() {
    var editor = app.view.editor_view.editor;
    editor.onChange.listen((event) {
      String new_editor_content = app.view.editor_view.editor.getDoc().getValue();
      var editor_content_action = EditorContentAction(new_editor_content);
      app.send_action(editor_content_action);
    });
  }



// END subscribe controller to events that result in dispatching Actions (e.g., user interaction)
//////////////////////////////////////////////////////////////////////////////

}


// Saving files from browsers is tricky. I don't recall where I got the
// following code, but maybe check here:
// https://developers.google.com/web/updates/2011/08/Saving-generated-files-on-the-client-side
// https://github.com/eligrey/FileSaver.js/blob/master/src/FileSaver.js#L69
save_file() async {
  //TODO: for some reason, this does not prompt the user to save the file in dartium
  // in development mode, but it does in Chrome when running the program in production mode
  var encoder = JsonEncoder.withIndent('  ');
  String json_model_text = encoder.convert(app.model);
  Blob blob = new Blob([json_model_text], 'text/plain;charset=utf-8');
  String url = Url.createObjectUrlFromBlob(blob);
  String filename = app.model.menu_view_ui_model.loaded_filename;
  var link = new AnchorElement()
    ..href = url
    ..download = filename;

  //TODO: the following is needed for Firefox; see how to test for Firefox
  document.body.children.add(link);
  //TODO: this await is my attempt to block until the user has selected a file, but it doesn't work.
  // The code keeps executing while they pick their file. Figure out how to detect if they picked a file or cancelled
  // If they cancelled then we should act as though nothing happened (in particular the Controller should not
  // send an Action indicating that the file was saved.
  //TODO: consider using this library if possible: https://github.com/jimmywarting/StreamSaver.js
  await link.click();
  //the following is needed for Firefox; see how to test for Firefox
  link.remove();

  //TODO: figure out how to detect filename user picked and save it as new filename
}

request_load_file_from_file_chooser(FileUploadInputElement file_chooser) {
  List<File> files = file_chooser.files;
  assert(files.isNotEmpty);
  File file = files[0];

  var basefilename = path.basenameWithoutExtension(file.name);

  FileReader file_reader = new FileReader();
  file_reader.onLoad.listen((_) => file_loaded(file_reader, basefilename));
  var err_msg = "error reading file: ${file_reader.error.toString()}";
  //file_reader.onError.listen((e) => error_message.text = err_msg);
  file_reader.onError.listen((_) => window.alert(err_msg));
  file_reader.readAsText(file);
}

//TODO: make the rest of the menu_view more clean like the rest of the view (separate from model, go through streams for notifications)
// This is not following the BLoC pattern, since it involves a wholesale
// change-out of the entire model, so it makes more sense to rebuild the
// whole view from scratch in this case.
file_loaded(FileReader file_reader, String filename) {
  app.model.menu_view_ui_model.loaded_filename = filename;
  var json_model_text = file_reader.result;

  set_new_design_from_json(json_model_text);
}

set_new_design_from_json(String json_model_text) {
  Map<String, dynamic> deserialized_map = jsonDecode(json_model_text);
  set_new_design_from_map(deserialized_map);
}

set_new_design_from_map(Map map) {
  DNADesign new_design;
  try {
    new_design = DNADesign.from_json(map);
    set_new_design(new_design);
  } on IllegalDNADesignError catch (error) {
    set_error_message(error.cause);
  }
}

//set_new_design_from_map(Map map) {
//  var new_design = DNADesign.from_json(map);
//  set_new_design(new_design);
//}

set_new_design(DNADesign new_design) {
  app.model.changed_since_last_save = false;
  app.undo_redo.reset();
  app.model.error_message = null;
  app.model.dna_design = new_design;
}

set_error_message(String msg) {
  app.undo_redo.reset();
  app.model.error_message = msg;
}

//TODO: there's a lot of repeated code between here and the functions that save/load the .dna files
// handle file saving/loading for script files
script_save_file() async {
  Blob blob = new Blob([app.model.editor_content], 'text/plain;charset=utf-8');
  String url = Url.createObjectUrlFromBlob(blob);
  String filename = app.model.editor_view_ui_model.loaded_script_filename;
  var link = new AnchorElement()
    ..href = url
    ..download = filename;

  document.body.children.add(link);
  await link.click();
  link.remove();
}

request_script_load_file_from_file_chooser(FileUploadInputElement file_chooser) {
  List<File> files = file_chooser.files;
  assert(files.isNotEmpty);
  File file = files[0];

  var basefilename = path.basenameWithoutExtension(file.name);

  FileReader file_reader = new FileReader();
  file_reader.onLoad.listen((_) => script_file_loaded(file_reader, basefilename));
  var err_msg = "error reading file: ${file_reader.error.toString()}";
  //file_reader.onError.listen((e) => error_message.text = err_msg);
  file_reader.onError.listen((_) => window.alert(err_msg));
  file_reader.readAsText(file);
}

script_file_loaded(FileReader file_reader, String filename) {
  app.model.editor_view_ui_model.loaded_script_filename = filename;
  app.model.editor_content = file_reader.result;
//  print('in dart, just put this script file contents into model: ${app.model.editor_content}');
  app.view.editor_view.render();
}
