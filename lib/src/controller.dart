import 'dart:async';
import 'dart:html';
import 'dart:convert';

import 'package:path/path.dart' as path;

import 'model.dart';
import 'view_side.dart';
import 'app.dart';
import 'actions.dart';

/// Responsible for notifying view listeners of changes to the model,
/// and for dispatching actions to change the model (coming from View interactions, for example).
class Controller {
  ////////////////////////////////////////////////////////////////////////////
  // Notifiers that fire when Model is updated by an Action
  // Relevant parts of the view are subscribed to these to know when to re-render.

  // Helix is updated in model
  final notifier_helix_change = StreamController<Helix>.broadcast();

  // "Show DNA" boolean value changed (e.g., user clicks on "Show DNA Sequence" check)
  final notifier_show_dna_change = StreamController<bool>.broadcast();

  // "Show Editor" boolean value changed (e.g., user clicks on "Show Editor Sequence" check)
  final notifier_show_editor_change = StreamController<bool>.broadcast();

  // Loaded filename is changed.
  final notifier_loaded_filename = StreamController<String>.broadcast();

  // Boolean value of whether model has changed since last save is changed.
  final notifier_model_changed_since_save = StreamController<bool>.broadcast();

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

  subscribe_to_all_to_model_change_events() {
    this.subscribe_to_helix();
    this.subscribe_to_show_dna();
    this.subscribe_to_show_editor();
    this.subscribe_to_model_changed_since_last_save_changed();
  }

  subscribe_to_helix() {
    this.notifier_helix_change.stream.listen((Helix helix) {
      var helix_side_view_elt = app.view.side_view.helix_elts_map[helix.grid_position];
      helix_side_view_elt.render();
      var helix_main_view_elt = app.view.main_view.helix_elts_map[helix.grid_position];
      helix_main_view_elt.render();
    });
  }

  subscribe_to_show_dna() {
    this.notifier_show_dna_change.stream.listen((_) {
      app.view.main_view.render_dna_sequences();
    });
  }

  subscribe_to_show_editor() {
    this.notifier_show_editor_change.stream.listen((_) {
      var old_sizes = app.view.splitter.getSizes();
      var side_size = old_sizes[0];
      var new_sizes = [side_size, -1, -1];
      var size_main_editor = (100 - side_size);
      //TODO: this shrinks the side view a small amount; correct for it
      if (app.model.show_editor) {
        new_sizes[1] = size_main_editor * 5 / 9.0;
        new_sizes[2] = size_main_editor * 4 / 9.0;
      } else {
        new_sizes[1] = size_main_editor;
        new_sizes[2] = 0;
      }
      print('old_sizes: ${old_sizes}');
      print('new_sizes: ${new_sizes}');
      app.view.splitter.setSizes(new_sizes);
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
    this.subscribe_to_user_clicks_show_editor_checkbox();
    this.subscribe_to_save_file_button_pressed();
    this.subscribe_to_load_file_button_pressed();

    this.subscribe_to_editor_change_events();
  }

  subscribe_to_user_clicks_side_view_helix() {
    for (var helix_side_view_elt in app.view.side_view.helix_elts_map.values) {
      helix_side_view_elt.circle.onClick.listen((MouseEvent e) {
        if (e.ctrlKey) this.handle_click_side_view(helix_side_view_elt);
      });
      helix_side_view_elt.text.onClick.listen((MouseEvent e) {
        if (e.ctrlKey) this.handle_click_side_view(helix_side_view_elt);
      });
    }
  }

  handle_click_side_view(HelixSideViewComponent helix_side_view_elt) {
    //TODO: detect if any strands are on this helix and disable deletion and give warning
    var helix = helix_side_view_elt.helix;
    var use = !helix.used;
    var idx = helix.idx;
    if (idx < 0) {
      idx = app.model.dna_design.used_helices.length;
    }
    var helix_action = HelixUseAction(use, helix, idx);
    app.send_action(helix_action);
  }

  subscribe_to_user_clicks_show_dna_checkbox() {
    app.view.menu_view.show_dna_checkbox.onChange
        .listen((_) => app.send_action(ShowDNAAction(app.view.menu_view.show_dna_checkbox.checked)));
  }

  subscribe_to_user_clicks_show_editor_checkbox() {
    app.view.menu_view.show_editor_checkbox.onChange
        .listen((_) => app.send_action(ShowEditorAction(app.view.menu_view.show_editor_checkbox.checked)));
  }

  subscribe_to_save_file_button_pressed() {
    app.view.menu_view.save_button.onClick.listen((_) async {
      await save_file();
      app.send_action(AlertFileSavedAction());
    });
  }

  subscribe_to_load_file_button_pressed() {
    // this is needed in case the user selects the same filename, to reload the file in case it has changed.
    // If not, then the onChange event won't fire and we won't reload the file.
    var file_chooser = app.view.menu_view.file_chooser;
    file_chooser.onClick.listen((_) {
      file_chooser.value = null;
    });
    file_chooser.onChange.listen((_) => request_load_file_from_file_chooser(file_chooser));
  }

  subscribe_to_editor_change_events() {
    var editor = app.view.editor_view.editor;
    editor.onChange.listen((event) {
      String old_editor_content = app.model.editor_content;
      String new_editor_content = app.view.editor_view.editor.getDoc().getValue();
      var editor_content_action = EditorContentAction(new_editor_content, old_editor_content);
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
  file_reader.onLoad.listen((e) => file_loaded(file_reader, basefilename));
  var err_msg = "error reading file: ${file_reader.error.toString()}";
  //file_reader.onError.listen((e) => error_message.text = err_msg);
  file_reader.onError.listen((e) => window.alert(err_msg));
  file_reader.readAsText(file);
}

//TODO: make the rest of the menu_view more clean like the rest of the view (separate from model, go through streams for notifications)
// This is not following the BLoC pattern, since it involves a wholesale
// change-out of the entire model, so it makes more sense to rebuild the
// whole view from scratch in this case.
file_loaded(FileReader file_reader, String filename) {
  var json_model_text = file_reader.result;
  Map<String, dynamic> deserialized_map = jsonDecode(json_model_text);
  var new_design = DNADesign.from_json(deserialized_map);
  app.model.menu_view_ui_model.loaded_filename = filename;

  // set new design
  app.model.changed_since_last_save = false;
  app.model.dna_design = new_design;
  app.undo_redo.reset();
  app.view.render();
}
